# 🌊 vibe-level.nvim

> A level above high-level programming

A Neovim plugin that bridges the gap between developer intent and implementation using LLMs. Write at the "vibe level" - describe what you want or implement what you need, and let AI handle the rest.

**How is this Different?** This tool is not for prompting. Instead you write code! Either normal high-level code (python) OR vibe-level code (code in natural language) - and Ai will fill up the missing level. 

**Intended use** You either write the vibe-level or python code of your function, whichever is shorter. This helps the programmer / developer to stay sharp as they do not rely on Ai to make code for them, but instead uses Ai to an additional level of coding (the vibe level ).


## 🎥 Vibe Level Demo

![Vibe Level Demo](https://github.com/mzguntalan/media_for_other_repo/blob/main/vibe_level/vibe_level_demo.gif?raw=true)


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
    'mzguntalan/vibe-level.nvim',
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
    'mzguntalan/vibe-level.nvim',
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
    timeout = 30000,                          -- Request timeout (ms)
    context = "FILE_LEVEL"                    -- FILE_LEVEL or FUNC_LEVEL
})
```

### Environment Variables

- `OLLAMA_URL`: Override default Ollama URL
- `OLLAMA_MODEL_VIBE_LEVEL`: Override default model name

### 🎯 Usage

- Place cursor inside a Python function
- Press `<leader>zv` or run `:VibeLevel`
- Magic happens! ✨
