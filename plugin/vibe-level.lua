-- vibe-level.nvim entry point
if vim.g.loaded_vibe_level then
  return
end

vim.g.loaded_vibe_level = 1

-- Only load if Neovim version is supported
if vim.fn.has('nvim-0.8') == 0 then
  vim.api.nvim_err_writeln('vibe-level.nvim requires Neovim >= 0.8')
  return
end

-- Load the plugin
require('vibe-level')
