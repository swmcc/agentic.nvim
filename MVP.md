# agentic.nvim MVP Definition

## Overview

The Minimum Viable Product (MVP) for agentic.nvim provides core agentic capabilities with dual-provider support. The focus is on establishing the adapter architecture and delivering essential user-facing features.

## MVP Features

### 1. Ask Agent

**Description**: Send a prompt to the active AI provider and receive a response in a new buffer.

**User Flow**:
```
1. User types :AgenticAsk "How do I optimize this loop?"
2. Plugin gathers current buffer context (filename, filetype, visible lines)
3. Request is sent to active provider (Claude or Gemini)
4. Response streams into a split buffer
5. User reads response, can copy/paste as needed
```

**Commands**:
- `:AgenticAsk [prompt]` - Ask with inline prompt
- `:AgenticAsk` - Open prompt input buffer

**API**:
```lua
api.ask({
  prompt = "How do I optimize this loop?",
  context = { buffer = 0, include_file = true },
})
```

### 2. Summarize Selection

**Description**: Summarize visually selected text using the active provider.

**User Flow**:
```
1. User visually selects code or text
2. User types :'<,'>AgenticSummarize
3. Selection is sent to provider with summarization prompt
4. Summary appears in floating window or split
```

**Commands**:
- `:'<,'>AgenticSummarize` - Summarize visual selection

**API**:
```lua
api.ask({
  prompt = "Summarize the following code:",
  context = { selection = true },
  workflow = "summarize",
})
```

### 3. Apply Structured Refactors

**Description**: Request code refactoring with structured output that can be applied to the buffer.

**User Flow**:
```
1. User selects code (optional)
2. User types :AgenticRefactor "Extract into separate function"
3. Provider returns structured refactor instructions
4. Plugin displays diff preview
5. User confirms application
6. Changes are applied to buffer
```

**Commands**:
- `:AgenticRefactor [instruction]` - Refactor with instruction
- `:'<,'>AgenticRefactor [instruction]` - Refactor selection

**API**:
```lua
api.ask({
  prompt = "Extract into separate function",
  context = { selection = true },
  workflow = "refactor",
  apply_changes = true,
})
```

### 4. Generate Code into New Buffer

**Description**: Generate new code based on a description and open it in a new buffer.

**User Flow**:
```
1. User types :AgenticGenerate "Create a Lua function that parses JSON"
2. Provider generates code
3. New buffer opens with generated code
4. Buffer has appropriate filetype set
```

**Commands**:
- `:AgenticGenerate [description]` - Generate code

**API**:
```lua
api.ask({
  prompt = "Create a Lua function that parses JSON",
  workflow = "generate",
  output = "new_buffer",
})
```

### 5. Multi-File Operation (Simulated)

**Description**: Plan and preview changes across multiple files. MVP version simulates execution with confirmation at each step.

**User Flow**:
```
1. User types :AgenticTask "Rename all instances of User to Account"
2. Provider returns a plan listing affected files
3. Plugin displays plan in preview buffer
4. User confirms to proceed
5. For each file:
   a. Provider generates changes
   b. Plugin displays diff
   c. User confirms each file (or all at once)
6. Changes are applied
```

**Commands**:
- `:AgenticTask [description]` - Run multi-step task

**API**:
```lua
api.run_workflow("multi_file", {
  prompt = "Rename all instances of User to Account",
  require_confirmation = true,
})
```

### 6. Provider Switching

**Description**: Switch between Claude and Gemini at runtime.

**User Flow**:
```
1. User types :AgenticUse gemini
2. Plugin switches active provider to Gemini
3. Confirmation message displayed
4. Subsequent commands use Gemini
```

**Commands**:
- `:AgenticUse claude` - Switch to Claude
- `:AgenticUse gemini` - Switch to Gemini
- `:AgenticStatus` - Show current provider

**API**:
```lua
api.switch_provider("gemini")
api.get_current_provider() -- returns "gemini"
```

## MVP Commands Summary

| Command | Description |
|---------|-------------|
| `:AgenticAsk [prompt]` | Ask the agent a question |
| `:AgenticSummarize` | Summarize selected text |
| `:AgenticRefactor [instruction]` | Refactor code |
| `:AgenticGenerate [description]` | Generate new code |
| `:AgenticTask [description]` | Run multi-step task |
| `:AgenticUse {provider}` | Switch provider |
| `:AgenticStatus` | Show status |
| `:AgenticCancel` | Cancel current operation |

## MVP Configuration

```lua
require("agentic").setup({
  -- Default provider to use
  default_provider = "claude",

  -- Provider-specific configuration
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

  -- UI preferences
  ui = {
    output = "split",      -- "split" | "float" | "tab"
    split_direction = "below",
    split_size = 15,
    confirm_changes = true,
  },

  -- Keymaps (optional)
  keymaps = {
    ask = "<leader>aa",
    refactor = "<leader>ar",
    generate = "<leader>ag",
  },
})
```

## Non-Goals for MVP

The following are explicitly out of scope for MVP:

- **Chat history persistence**: No conversation memory between sessions
- **Multiple concurrent operations**: One operation at a time
- **Custom workflow registration**: Built-in workflows only
- **Third-party adapter support**: Only Claude and Gemini
- **Streaming diff application**: Changes applied after completion
- **Undo integration**: Standard Vim undo only
- **LSP integration**: No code intelligence integration
- **Telescope integration**: No fuzzy finder integration
- **Testing framework**: Manual testing only

## Success Criteria

MVP is complete when:

1. [ ] User can ask questions and receive responses
2. [ ] User can summarize selected text
3. [ ] User can request and apply refactors
4. [ ] User can generate code into new buffers
5. [ ] User can run multi-file tasks with confirmation
6. [ ] User can switch between Claude and Gemini
7. [ ] Both providers work with identical commands
8. [ ] Error states are handled gracefully
9. [ ] Basic documentation exists

## Technical Requirements

- Neovim >= 0.9.0
- `claude` CLI installed and authenticated (for Claude provider)
- `gemini` CLI installed and authenticated (for Gemini provider)
- Lua 5.1 / LuaJIT

## File Deliverables

```
lua/agentic/
├── init.lua           # Plugin entrypoint
├── api.lua            # Internal API
├── config.lua         # Configuration
├── commands.lua       # Command registration
├── ui.lua             # Buffer/window management
├── adapters/
│   ├── base.lua       # Adapter interface
│   ├── claude.lua     # Claude implementation
│   └── gemini.lua     # Gemini implementation
└── workflows/
    └── init.lua       # Workflow engine
```
