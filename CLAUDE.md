# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands

```bash
# Run all tests (requires plenary.nvim)
make test

# Run a single test file
make test-file FILE=tests/adapters/claude_spec.lua

# Lint with luacheck
make lint
```

## Architecture Overview

Pamoja (formerly agentic.nvim) is a dual-agent Neovim plugin supporting Claude Code and Gemini CLI. The architecture follows a provider-agnostic adapter pattern:

```
Commands (commands.lua) → API (api.lua) → Adapters (adapters/*.lua) → CLI processes
                              ↓
                         UI (ui.lua)
                              ↓
                       Workflows (workflows/init.lua)
```

### Key Modules

- **`lua/agentic/init.lua`** - Plugin entrypoint, exposes `setup()` function
- **`lua/agentic/api.lua`** - Internal API that all plugin functionality routes through
- **`lua/agentic/adapters/base.lua`** - Adapter interface contract all providers must implement
- **`lua/agentic/adapters/claude.lua`** - Claude Code CLI adapter using stream-json output format
- **`lua/agentic/adapters/gemini.lua`** - Gemini CLI adapter
- **`lua/agentic/ui.lua`** - Buffer/window management for output, diffs, prompts

### Adapter Interface

All adapters inherit from `base.lua` and must implement:
- `ask(prompt, context, callback, on_event)` - Send prompt, receive streaming response
- `is_available()` - Check if CLI tool is installed
- `cancel()` - Cancel running operation

The Claude adapter uses `--output-format stream-json` and parses newline-delimited JSON events.

### Testing

Tests use plenary.nvim's busted-style framework. The minimal init at `tests/minimal_init.lua` auto-downloads plenary if missing.

## Plugin Commands

Commands are prefixed with `:Pamoja*` (e.g., `:PamojaAsk`, `:PamojaRefactor`, `:PamojaUse claude`).
