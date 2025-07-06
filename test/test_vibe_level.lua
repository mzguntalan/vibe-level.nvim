-- Basic test for vibe-level plugin
local vibe_level = require('vibe-level')

-- Test setup
local function test_setup()
    print("Testing vibe-level setup...")
    
    -- Test with default config
    vibe_level.setup()
    print("✅ Default setup successful")
    
    -- Test with custom config
    vibe_level.setup({
        ollama_url = "http://localhost:11434",
        model_name = "test-model",
        keybind = "<leader>tv"
    })
    print("✅ Custom setup successful")
end

-- Test plugin loading
local function test_plugin_loading()
    print("Testing plugin loading...")
    
    if vim.g.loaded_vibe_level then
        print("✅ Plugin loaded successfully")
    else
        print("❌ Plugin not loaded")
        return false
    end
    
    return true
end

-- Test command creation
local function test_commands()
    print("Testing commands...")
    
    local commands = vim.api.nvim_get_commands({})
    if commands.VibeLevel then
        print("✅ VibeLevel command created")
    else
        print("❌ VibeLevel command not found")
        return false
    end
    
    return true
end

-- Run all tests
local function run_tests()
    print("Running vibe-level tests...")
    print("=" .. string.rep("=", 40))
    
    local success = true
    
    success = success and test_plugin_loading()
    success = success and test_commands()
    test_setup()
    
    print("=" .. string.rep("=", 40))
    if success then
        print("🎉 All tests passed!")
    else
        print("❌ Some tests failed!")
    end
    
    return success
end

-- Export for use
return {
    run_tests = run_tests
}
