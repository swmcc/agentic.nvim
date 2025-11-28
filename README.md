# agentic.nvim

A dual-agent agentic workflow plugin for Neovim with Claude Code and Gemini CLI support.

## Features

- **Dual Provider Support**: Seamlessly switch between Claude Code and Gemini CLI
- **Ask Agent**: Get answers to coding questions with full context
- **Code Refactoring**: Apply structured refactors with diff preview
- **Code Generation**: Generate new code into buffers
- **Multi-File Operations**: Plan and execute cross-file changes safely
- **Streaming Output**: See responses as they arrive

## Requirements

- Neovim >= 0.9.0
- One or both of:
  - [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) installed and authenticated
  - [Gemini CLI](https://github.com/google-gemini/gemini-cli) installed and authenticated

## Installation

### lazy.nvim

```lua
{
  "yourusername/agentic.nvim",
  config = function()
    require("agentic").setup({
      default_provider = "claude",
    })
  end,
}
```

### packer.nvim

```lua
use {
  "yourusername/agentic.nvim",
  config = function()
    require("agentic").setup({
      default_provider = "claude",
    })
  end,
}
```

## Configuration

```lua
require("agentic").setup({
  -- Default AI provider: "claude" or "gemini"
  default_provider = "claude",

  -- Provider-specific settings
  providers = {
    claude = {
      cmd = "claude",
      args = {},
    },
    gemini = {
      cmd = "gemini",
      args = {},
    },
  },

  -- UI settings
  ui = {
    output = "split",           -- "split" | "float" | "tab"
    split_direction = "below",  -- "below" | "above" | "left" | "right"
    split_size = 15,
    confirm_changes = true,
  },

  -- Optional keymaps
  keymaps = {
    ask = "<leader>aa",
    summarize = "<leader>as",
    refactor = "<leader>ar",
    generate = "<leader>ag",
    task = "<leader>at",
  },
})
```

## Commands

| Command | Description |
|---------|-------------|
| `:AgenticAsk [prompt]` | Ask the agent a question |
| `:AgenticSummarize` | Summarize selected text (visual mode) |
| `:AgenticRefactor [instruction]` | Refactor selected code |
| `:AgenticGenerate [description]` | Generate new code |
| `:AgenticTask [description]` | Run a multi-step task |
| `:AgenticUse {provider}` | Switch to claude or gemini |
| `:AgenticStatus` | Show current provider status |
| `:AgenticCancel` | Cancel running operation |

## Usage Examples

### Ask a Question

```vim
:AgenticAsk How do I implement binary search in Lua?
```

### Summarize Selection

```vim
" Select code visually, then:
:'<,'>AgenticSummarize
```

### Refactor Code

```vim
" Select function, then:
:'<,'>AgenticRefactor Extract the loop into a separate function

" Or refactor entire file:
:AgenticRefactor Add error handling to all functions
```

### Generate Code

```vim
:AgenticGenerate Create a Lua module for parsing CSV files
```

### Multi-File Task

```vim
:AgenticTask Rename the User class to Account across the codebase
```

### Switch Provider

```vim
:AgenticUse gemini
:AgenticStatus
```

## Architecture

See [ARCHITECTURE.md](./ARCHITECTURE.md) for detailed technical documentation.

## MVP Scope

See [MVP.md](./MVP.md) for current feature scope and roadmap.

## License

MIT

## Contributing

Contributions welcome. Please open an issue first to discuss proposed changes.
