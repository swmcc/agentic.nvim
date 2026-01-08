# Pamoja (agentic.nvim) - Project Conventions

## Overview

Pamoja (Swahili for "together") is a dual-agent agentic workflow plugin for Neovim that supports both Claude Code CLI and Gemini CLI as backend providers. The plugin enables AI-assisted coding workflows directly within Neovim through a provider-agnostic adapter pattern.

### Core Philosophy

- **Working together**: Multiple AI agents under one unified interface
- **Editor integration**: Seamless Neovim experience
- **Provider flexibility**: Switch between Claude and Gemini instantly
- **Safe operations**: Multi-file changes staged with confirmation

## Tech Stack

| Component | Technology |
|-----------|------------|
| Language | Lua 5.1 / LuaJIT |
| Editor | Neovim >= 0.9.0 |
| Test Framework | plenary.nvim (busted-style) |
| Linting | luacheck |
| CI/CD | GitHub Actions |
| AI Backends | Claude Code CLI, Gemini CLI |

### External Dependencies

- **Claude Code CLI**: `npm install -g @anthropic-ai/claude-code`
- **Gemini CLI**: Google's official Gemini CLI tool
- **plenary.nvim**: Required for testing (auto-downloaded during tests)

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        User Commands                             │
│  :PamojaAsk  :PamojaRefactor  :PamojaTask  :PamojaUse           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      commands.lua                                │
│              Command registration & argument parsing             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                         api.lua                                  │
│                   Internal Plugin API                            │
│  api.ask()  api.plan()  api.apply_changes()  api.run_workflow() │
└─────────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
┌───────────────────┐ ┌─────────────┐ ┌─────────────────┐
│   workflows/      │ │   ui.lua    │ │    config.lua   │
│   Workflow Engine │ │ Buffer Mgmt │ │  Configuration  │
└───────────────────┘ └─────────────┘ └─────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────────────────────┐
│                       adapters/                                  │
│                    Adapter Interface                             │
├─────────────────────────────────────┬───────────────────────────┤
│       claude.lua                    │          gemini.lua       │
│    Claude Code Backend              │       Gemini CLI Backend  │
└─────────────────────────────────────┴───────────────────────────┘
```

### Key Design Principles

1. **Provider Agnosticism**: All provider-specific details abstracted behind common adapter interface
2. **Separation of Concerns**: UI, API, adapters, and workflows are independent modules
3. **Async-First**: All AI operations are non-blocking to preserve editor responsiveness
4. **Safe Multi-File Operations**: File modifications staged with explicit confirmation

## Directory Structure

```
lua/agentic/
├── init.lua           # Plugin entrypoint, setup() function
├── api.lua            # Internal API (private, not for direct user access)
├── config.lua         # Configuration management with defaults
├── commands.lua       # User command registration (:Pamoja* commands)
├── ui.lua             # Buffer/window management, floating windows
├── adapters/
│   ├── base.lua       # Adapter interface contract
│   ├── claude.lua     # Claude Code CLI adapter (stream-json)
│   └── gemini.lua     # Gemini CLI adapter
└── workflows/
    └── init.lua       # Workflow engine with built-in workflows

tests/
├── minimal_init.lua   # Test harness (auto-downloads plenary)
└── adapters/
    └── claude_spec.lua # Claude adapter unit tests
```

## Git Commit Conventions

This project uses gitmoji for commit messages. Common prefixes:

| Emoji | Code | Usage |
|-------|------|-------|
| :sparkles: | `:sparkles:` | New feature |
| :bug: | `:bug:` | Bug fix |
| :recycle: | `:recycle:` | Refactor code |
| :white_check_mark: | `:white_check_mark:` | Add/update tests |
| :memo: | `:memo:` | Documentation |
| :art: | `:art:` | Improve structure/format |
| :zap: | `:zap:` | Performance improvement |
| :lock: | `:lock:` | Security fix |
| :wrench: | `:wrench:` | Configuration files |
| :construction: | `:construction:` | Work in progress |
| :fire: | `:fire:` | Remove code/files |
| :truck: | `:truck:` | Move/rename files |
| :package: | `:package:` | Dependencies |
| :rotating_light: | `:rotating_light:` | Fix linter warnings |
| :adhesive_bandage: | `:adhesive_bandage:` | Simple fix |
| :boom: | `:boom:` | Breaking changes |
| :broom: | `:broom:` | Code cleanup |
| :shield: | `:shield:` | Add/fix error handling |
| :test_tube: | `:test_tube:` | Add failing test |
| :goal_net: | `:goal_net:` | Catch errors |

### Commit Message Format

```
:emoji: Short summary (imperative mood)

Optional longer description explaining:
- What changed
- Why it changed
- Any breaking changes
```

## Code Conventions

### Lua Style

- Use `local` for all module-level variables and functions
- Module pattern: `local M = {}` with `return M` at end
- Use LDoc-style documentation comments (`---@mod`, `---@param`, `---@return`)
- Prefer `vim.tbl_extend` and `vim.tbl_deep_extend` for table merging
- Use `vim.schedule` for callbacks that modify UI from async contexts

### Type Annotations

Use LDoc annotations for documentation:

```lua
---@class ClassName
---@field fieldname type Description

---@param arg1 type Description
---@param arg2? type Optional parameter
---@return type Description
function M.example(arg1, arg2)
end
```

### Naming Conventions

- **Modules**: `snake_case.lua`
- **Classes**: `PascalCase`
- **Functions/Methods**: `snake_case`
- **Constants**: `SCREAMING_SNAKE_CASE`
- **Private functions**: Prefix with `_` (e.g., `M._internal_func`)

### Error Handling

- Use `vim.notify()` for user-facing messages with appropriate log levels
- Return error tables from async operations: `{ error = "message" }`
- Use `pcall` for operations that may fail (JSON parsing, etc.)

## Commands

### Development

```bash
# Run all tests
make test

# Run single test file
make test-file FILE=tests/adapters/claude_spec.lua

# Lint with luacheck
make lint
```

### Testing in Neovim

```vim
" Reload plugin during development
:lua package.loaded['agentic'] = nil
:lua require('agentic').setup()

" Check current provider
:PamojaStatus

" Switch providers
:PamojaUse claude
:PamojaUse gemini
```

### Plugin Commands

| Command | Description |
|---------|-------------|
| `:PamojaAsk [prompt]` | Ask the AI agent a question |
| `:PamojaSummarise` | Summarise selected text (visual mode) |
| `:PamojaRefactor [instruction]` | Refactor selected code |
| `:PamojaGenerate [description]` | Generate new code |
| `:PamojaTask [description]` | Run multi-step task |
| `:PamojaUse {provider}` | Switch to claude or gemini |
| `:PamojaStatus` | Show current provider status |
| `:PamojaCancel` | Cancel running operation |

## Configuration

```lua
require("pamoja").setup({
  default_provider = "claude",  -- "claude" or "gemini"
  providers = {
    claude = {
      cmd = "claude",
      args = {},
      timeout = 120000,
    },
    gemini = {
      cmd = "gemini",
      args = {},
      timeout = 120000,
    },
  },
  ui = {
    output = "split",           -- "split" | "float" | "tab"
    split_direction = "below",
    split_size = 15,
    confirm_changes = true,
  },
  keymaps = {
    ask = "<leader>pa",
    summarise = "<leader>ps",
    refactor = "<leader>pr",
    generate = "<leader>pg",
    task = "<leader>pt",
  },
})
```

## Version

Current version: 0.1.0 (MVP)
