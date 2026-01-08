# AI Agent Workflow Instructions

This document provides guidance for AI agents working on the Pamoja (agentic.nvim) codebase.

## Quick Reference Commands

| Task | Command |
|------|---------|
| Run all tests | `make test` |
| Run single test | `make test-file FILE=tests/adapters/claude_spec.lua` |
| Lint code | `make lint` |
| Check in Neovim | `:lua require('agentic').setup()` |

## Key Files Reference

| File | Purpose | When to Modify |
|------|---------|----------------|
| `lua/agentic/init.lua` | Plugin entrypoint, `setup()` | Adding new public API |
| `lua/agentic/api.lua` | Internal API layer | Adding new operations |
| `lua/agentic/config.lua` | Configuration defaults | Adding config options |
| `lua/agentic/commands.lua` | User command registration | Adding `:Pamoja*` commands |
| `lua/agentic/ui.lua` | Buffer/window management | UI changes, floating windows |
| `lua/agentic/adapters/base.lua` | Adapter interface | Changing adapter contract |
| `lua/agentic/adapters/claude.lua` | Claude Code adapter | Claude-specific features |
| `lua/agentic/adapters/gemini.lua` | Gemini CLI adapter | Gemini-specific features |
| `lua/agentic/workflows/init.lua` | Workflow engine | Adding/modifying workflows |
| `tests/adapters/claude_spec.lua` | Claude adapter tests | Testing Claude adapter |
| `.luacheckrc` | Linter configuration | Adding globals, ignore rules |

## Implementation Guidelines

### Adding a New Adapter

1. Create `lua/agentic/adapters/{provider}.lua`
2. Extend `base.lua`:
   ```lua
   local Base = require("agentic.adapters.base")
   local Provider = Base:extend()
   ```
3. Implement required methods:
   - `new(opts)` - Constructor
   - `is_available()` - Check CLI availability
   - `ask(prompt, context, callback, on_event)` - Send prompt
   - `cancel()` - Cancel operation
   - `build_args(prompt, context)` - Build CLI arguments
4. Add provider config to `config.lua` defaults
5. Add tests in `tests/adapters/{provider}_spec.lua`

### Adding a New Command

1. Add command in `commands.lua`:
   ```lua
   vim.api.nvim_create_user_command("PamojaNewCmd", function(opts)
     -- Implementation
   end, {
     nargs = "*",
     desc = "Description",
   })
   ```
2. Add corresponding API function in `api.lua` if needed
3. Update README.md command table

### Adding a New Workflow

1. Register in `workflows/init.lua`:
   ```lua
   M.register("workflow_name", {
     steps = { "step1", "step2" },
     handlers = {
       step1 = function(state, adapter, callback)
         -- Implementation
       end,
       step2 = function(state, adapter, callback)
         -- Implementation
       end,
     },
   })
   ```
2. Add command binding in `commands.lua` if user-facing

### Modifying UI

- All UI changes should go through `ui.lua`
- Use `vim.schedule()` when modifying buffers from async callbacks
- Close existing floats before creating new ones
- Set `vim.bo[buf].modifiable = true` before buffer changes
- Use `set_float_keymaps()` for consistent keyboard shortcuts

## Testing Guidelines

### Test Structure

```lua
describe("Module name", function()
  local module

  before_each(function()
    module = require("agentic.module")
  end)

  describe("function_name", function()
    it("does something specific", function()
      -- Arrange
      -- Act
      -- Assert
    end)
  end)
end)
```

### Mocking Vim Functions

```lua
it("handles vim function", function()
  local original = vim.fn.executable
  vim.fn.executable = function(cmd)
    return cmd == "claude" and 1 or 0
  end

  -- Test code here

  vim.fn.executable = original  -- Always restore!
end)
```

### Testing Async Code

```lua
it("handles async operation", function()
  local original_schedule = vim.schedule
  vim.schedule = function(fn) fn() end  -- Make sync for testing

  -- Test async code

  vim.schedule = original_schedule
end)
```

## Common Tasks

### Debug a Hanging Command

1. Check adapter's `ask()` method callback handling
2. Verify `vim.loop.spawn` is receiving valid arguments
3. Check if `safe_callback` is being called on all paths
4. Look for missing `vim.schedule` wrappers

### Add Error Handling

1. Wrap risky code in `pcall`:
   ```lua
   local ok, result = pcall(vim.json.decode, data)
   if not ok then
     -- Handle error
   end
   ```
2. Use adapter's `parse_error()` for user-friendly messages
3. Always call callback with `{ error = message }` on failure

### Fix Lint Warnings

1. Run `make lint` to see issues
2. Common fixes:
   - Unused variable: prefix with `_` (e.g., `_unused`)
   - Missing global: add to `.luacheckrc` globals
   - Line too long: generally ignored (see config)

## Architecture Decisions

### Why Provider Agnosticism?

Users should not be locked into a single AI provider. The adapter pattern allows:
- Same commands work with any provider
- Easy addition of new providers
- Runtime provider switching

### Why Async-First?

AI operations can take seconds to minutes. Blocking Neovim would:
- Freeze the editor
- Prevent user cancellation
- Create poor user experience

### Why Staged Multi-File Operations?

Direct file writes are dangerous. The staging approach:
- Shows preview before applying
- Allows user confirmation
- Supports rollback capability
- Prevents accidental data loss

## Commit Checklist

Before committing changes:

- [ ] `make lint` passes
- [ ] `make test` passes (if tests exist for changed code)
- [ ] New functions have LDoc comments
- [ ] Breaking changes are documented
- [ ] Commit message uses gitmoji format
