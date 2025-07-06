# 🌊 vibe-level.nvim

> A level above high-level programming

A Neovim plugin that bridges the gap between developer intent and implementation using LLMs. Write at the "vibe level" - describe what you want or implement what you need, and let AI handle the rest.

## ✨ Features

- **Docstring → Implementation**: Write a docstring with `...` parameters, get complete function
- **Implementation → Documentation**: Write code, get comprehensive docstring
- **Intelligent Detection**: Automatically detects completion context
- **Ollama Integration**: Uses local LLMs for privacy and speed

## 🚀 Installation

### Prerequisites

- Neovim >= 0.8
- [Ollama](https://ollama.ai) installed and running
- `curl` command available

### Using lazy.nvim

```lua
{
    'yourusername/vibe-level.nvim',
    config = function()
        require('vibe-level').setup({
            ollama_url = "http://localhost:11434",
            model_name = "llama2"
        })
    end
}
```

### Using packer.nvim

```lua
use {
    'yourusername/vibe-level.nvim',
    config = function()
        require('vibe-level').setup()
    end
}
```

### ⚙️ Configuration

```
require('vibe-level').setup({
    ollama_url = "http://localhost:11434",    -- Ollama server URL
    model_name = "llama2",                    -- Model to use
    keybind = "<leader>zv",                   -- Trigger keybind
    timeout = 30000                           -- Request timeout (ms)
})
```

### Environment Variables

- `OLLAMA_URL`: Override default Ollama URL
- `OLLAMA_MODEL_VIBE_LEVEL`: Override default model name

### 🎯 Usage

- Place cursor inside a Python function
- Press `<leader>zv` or run `:VibeLevel`
- Magic happens! ✨

... Under construction
