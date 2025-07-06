local M = {}

-- Default configuration
local config = {
  ollama_url = os.getenv("OLLAMA_URL") or "http://localhost:11434",
  model_name = os.getenv("OLLAMA_MODEL_VIBE_LEVEL") or "llama2",
  keybind = "<leader>zv",
  timeout = 30000, -- 30 seconds
  context = "FUNC_LEVEL", -- "FUNC_LEVEL" or "FILE_LEVEL"
}

-- HTTP client using curl
local function http_request(url, data)
  local json = vim.fn.json_encode(data)
  local cmd = string.format(
    'curl -s -X POST "%s" -H "Content-Type: application/json" -d %s',
    url, vim.fn.shellescape(json)
  )
  
  local handle = io.popen(cmd)
  if not handle then
    return nil, "Failed to execute curl command"
  end
  
  local result = handle:read("*a")
  handle:close()
  
  if result == "" then
    return nil, "Empty response from Ollama"
  end
  
  local ok, decoded = pcall(vim.fn.json_decode, result)
  if not ok then
    return nil, "Failed to decode JSON response: " .. result
  end
  
  return decoded, nil
end

-- Send prompt to Ollama
local function query_ollama(prompt)
  local url = config.ollama_url .. "/api/generate"
  local data = {
    model = config.model_name,
    prompt = prompt,
    stream = false,
    options = {
      temperature = 0.3,
      top_p = 0.9,
    }
  }
  
  local response, err = http_request(url, data)
  if err then
    return nil, err
  end
  
  if response and response.response then
    return response.response, nil
  else
    return nil, "No response from model"
  end
end

-- Parse Python function/method to detect cases
local function parse_python_function(lines)
  local function_start = nil
  local docstring_start = nil
  local docstring_end = nil
  local body_start = nil
  
  -- Find function definition
  for i, line in ipairs(lines) do
    if line:match("^%s*def%s+") or line:match("^%s*async%s+def%s+") then
      function_start = i
      break
    end
  end
  
  if not function_start then
    return nil, "No function definition found"
  end
  
  -- Look for docstring
  for i = function_start + 1, #lines do
    local line = lines[i]:match("^%s*(.-)%s*$") -- trim whitespace
    if line == "" then
      goto continue
    end
    
    if line:match('^"""') or line:match("^'''") then
      docstring_start = i
      -- Find end of docstring
      local quote_type = line:match('^(""")') or line:match("^(''')")
      if line:match(quote_type .. "$") and #line > 3 then
        -- Single line docstring
        docstring_end = i
      else
        -- Multi-line docstring
        for j = i + 1, #lines do
          if lines[j]:match(quote_type) then
            docstring_end = j
            break
          end
        end
      end
      break
    else
      -- No docstring, body starts here
      body_start = i
      break
    end
    
    ::continue::
  end
  
  -- Find body start if we found a docstring
  if docstring_end then
    for i = docstring_end + 1, #lines do
      local line = lines[i]:match("^%s*(.-)%s*$")
      if line ~= "" then
        body_start = i
        break
      end
    end
  end
  
  return {
    function_start = function_start,
    docstring_start = docstring_start,
    docstring_end = docstring_end,
    body_start = body_start,
    lines = lines
  }
end

-- Extract function signature
local function extract_function_signature(line)
  local sig = line:match("def%s+(.+):")
  if not sig then
    sig = line:match("async%s+def%s+(.+):")
  end
  return sig
end

-- Check if function body is just ellipsis or pass
local function is_empty_body(lines, start_idx)
  for i = start_idx, #lines do
    local line = lines[i]:match("^%s*(.-)%s*$")
    if line ~= "" then
      return line == "..." or line == "pass"
    end
  end
  return true
end

-- Generate completion based on context
local function generate_completion(parsed, case_type, full_file_lines, current_func_start)
  local prompt = ""
  
  if case_type == "docstring_only" then
    -- Case 1: Only docstring provided, need to fill parameters and body
    local func_line = parsed.lines[parsed.function_start]
    local signature = extract_function_signature(func_line)
    
    local docstring_lines = {}
    for i = parsed.docstring_start, parsed.docstring_end do
      table.insert(docstring_lines, parsed.lines[i])
    end
    local docstring = table.concat(docstring_lines, "\n")
    
    if config.context == "FILE_LEVEL" then
      local file_context = table.concat(full_file_lines, "\n")
      prompt = string.format([[
You are a Python code generator. Here's the full file for context:

%s

Focus on the function starting at line %d. Given the function signature with ellipsis parameters and docstring, complete the function by:
1. Using existing functions, classes, and imports from the file when appropriate
2. Replacing ellipsis (...) in parameters with proper parameter names and type annotations
3. Keeping any existing fixed parameters unchanged
4. Implementing the function body based on the docstring
5. Following the coding style and patterns used in the file

Function signature: %s
Docstring:
%s

Generate ONLY the complete function definition with proper parameters and body. Do not include any explanations, markdown formatting, or code fences. Output raw Python code only.]], 
        file_context, current_func_start, signature, docstring)
    else
      -- FUNC_LEVEL context (original behavior)
      prompt = string.format([[
You are a Python code generator. Given a function signature with ellipsis parameters and a docstring, complete the function by:
1. Replacing ellipsis (...) in parameters with proper parameter names and type annotations
2. Keeping any existing fixed parameters unchanged
3. Implementing the function body based on the docstring

Function signature: %s
Docstring:
%s

Generate ONLY the complete function definition with proper parameters and body. Do not include any explanations, markdown formatting, or code fences. Output raw Python code only.]], signature, docstring)
    end
    
  elseif case_type == "body_only" then
    -- Case 2: Only body provided, need to generate docstring
    local func_line = parsed.lines[parsed.function_start]
    
    local body_lines = {}
    for i = parsed.body_start, #parsed.lines do
      table.insert(body_lines, parsed.lines[i])
    end
    local body = table.concat(body_lines, "\n")
    
    if config.context == "FILE_LEVEL" then
      local file_context = table.concat(full_file_lines, "\n")
      prompt = string.format([[
You are a Python documentation generator. Here's the full file for context:

%s

Focus on the function starting at line %d. Given the function implementation, generate a comprehensive docstring that:
1. Describes what the function does in relation to other functions in the file
2. Documents all parameters with their types
3. Documents the return value and its type
4. Includes any relevant examples or usage notes
5. Follows the docstring style used in the file

Function:
%s
%s

Generate ONLY the docstring in triple quotes format. Do not include the function definition, explanations, or markdown formatting. Output raw Python docstring only.]], 
        file_context, current_func_start, func_line, body)
    else
      -- FUNC_LEVEL context (original behavior)
      prompt = string.format([[
You are a Python documentation generator. Given a function with its implementation, generate a comprehensive docstring.

Function:
%s
%s

Generate ONLY the docstring in triple quotes format. Include description, parameters, return value, and any relevant examples. Do not include the function definition, explanations, or markdown formatting. Output raw Python docstring only.]], func_line, body)
    end
  end
  
  return query_ollama(prompt)
end

-- Main function to handle vibe level completion
local function vibe_level_complete()
  local bufnr = vim.api.nvim_get_current_buf()
  local filetype = vim.bo[bufnr].filetype
  
  if filetype ~= "python" then
    vim.notify("Vibe level currently only supports Python files", vim.log.levels.WARN)
    return
  end
  
  -- Get current cursor position
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1]
  
  -- Find function boundaries around cursor
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  
  -- Find the function that contains the cursor
  local func_start = nil
  local func_end = nil
  
  -- Search backwards for function definition
  for i = row, 1, -1 do
    if lines[i]:match("^%s*def%s+") or lines[i]:match("^%s*async%s+def%s+") then
      func_start = i
      break
    end
  end
  
  if not func_start then
    vim.notify("No function found around cursor", vim.log.levels.WARN)
    return
  end
  
  -- Find function end (next function or class, or end of file)
  func_end = #lines
  for i = func_start + 1, #lines do
    local line = lines[i]
    -- Only end function on new function/class definitions or decorators
    if line:match("^%s*def%s+") or line:match("^%s*class%s+") or 
       line:match("^%s*async%s+def%s+") or line:match("^%s*@") then
      func_end = i - 1
      break
    -- Also end on non-indented non-empty lines, but be more careful
    elseif line:match("^%S") and line:trim() ~= "" and not line:match("^#") then
      -- Check if this looks like it's outside the function
      -- Only break if it's not a string, comment, or continuation
      if not line:match("^[\"']") then
        func_end = i - 1
        break
      end
    end
  end
  
  -- Extract function lines
  local func_lines = {}
  for i = func_start, func_end do
    table.insert(func_lines, lines[i])
  end
  
  -- Parse the function
  local parsed = parse_python_function(func_lines)
  if not parsed then
    vim.notify("Failed to parse function", vim.log.levels.ERROR)
    return
  end
  
  -- Determine case type
  local case_type = nil
  if parsed.docstring_start and parsed.body_start then
    if is_empty_body(func_lines, parsed.body_start - parsed.function_start + 1) then
      case_type = "docstring_only"
    else
      vim.notify("Function appears to have both docstring and body", vim.log.levels.INFO)
      return
    end
  elseif parsed.docstring_start then
    case_type = "docstring_only"
  elseif parsed.body_start then
    case_type = "body_only"
  else
    vim.notify("Cannot determine function completion type", vim.log.levels.WARN)
    return
  end
  
  -- Show loading message
  vim.notify("Generating vibe level completion...", vim.log.levels.INFO)
  
  -- Generate completion
  local completion, err = generate_completion(parsed, case_type, lines, func_start)
  if err then
    vim.notify("Error generating completion: " .. err, vim.log.levels.ERROR)
    return
  end
  
  if not completion then
    vim.notify("No completion generated", vim.log.levels.WARN)
    return
  end
  
  -- Apply completion based on case type
  if case_type == "docstring_only" then
    -- Replace entire function
    local new_lines = vim.split(completion, "\n")
    vim.api.nvim_buf_set_lines(bufnr, func_start - 1, func_end, false, new_lines)
  elseif case_type == "body_only" then
    -- Insert docstring after function definition
    local docstring_lines = vim.split(completion, "\n")
    -- Add proper indentation
    local func_line = lines[func_start]
    local indent = func_line:match("^(%s*)")
    local body_indent = indent .. "    "
    
    for i, line in ipairs(docstring_lines) do
      if i == 1 then
        docstring_lines[i] = body_indent .. line
      else
        docstring_lines[i] = body_indent .. line
      end
    end
    
    vim.api.nvim_buf_set_lines(bufnr, func_start, func_start, false, docstring_lines)
  end
  
  vim.notify("Vibe level completion applied!", vim.log.levels.INFO)
end

-- Setup function
function M.setup(opts)
  config = vim.tbl_deep_extend("force", config, opts or {})
  
  -- Create user command
  vim.api.nvim_create_user_command("VibeLevel", vibe_level_complete, {
    desc = "Complete function at vibe level"
  })
  
  -- Set up keybinding
  vim.keymap.set("n", config.keybind, vibe_level_complete, {
    desc = "Vibe Level Complete",
    silent = true
  })
end

return M
