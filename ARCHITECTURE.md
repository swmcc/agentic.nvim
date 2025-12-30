# agentic.nvim Architecture

## Overview

agentic.nvim is a dual-agent agentic workflow plugin for Neovim that supports both Claude Code and Gemini CLI as backend providers. The architecture is designed around a modular adapter pattern that allows seamless switching between AI providers while maintaining a consistent internal API.

## Core Principles

1. **Provider Agnosticism**: The plugin abstracts away provider-specific details behind a common adapter interface
2. **Separation of Concerns**: UI, API, adapters, and workflows are independent modules
3. **Async-First**: All AI operations are non-blocking to preserve editor responsiveness
4. **Safe Multi-File Operations**: File modifications are staged and require explicit confirmation

## Module Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        User Commands                             │
│  :PamojaAsk  :PamojaRefactor  :PamojaTask  :PamojaUse       │
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
├─────────────────────────────┬───────────────────────────────────┤
│       claude.lua            │          gemini.lua               │
│    Claude Code Backend      │       Gemini CLI Backend          │
└─────────────────────────────┴───────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    External Processes                            │
│              claude (CLI)    │    gemini (CLI)                  │
└─────────────────────────────────────────────────────────────────┘
```

## Module Descriptions

### `init.lua` - Plugin Entrypoint

- Initializes the plugin and sets up default configuration
- Registers user commands
- Exposes the public `setup()` function for user configuration
- Manages plugin lifecycle

### `config.lua` - Configuration Management

- Stores and validates user configuration
- Manages provider selection state
- Provides defaults for all options

```lua
-- Default configuration structure
{
  default_provider = "claude",  -- "claude" | "gemini"
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
  ui = {
    output_buffer = "split",    -- "split" | "float" | "tab"
    confirm_changes = true,
  },
}
```

### `api.lua` - Internal Plugin API

The core API module that all plugin functionality routes through. This is an internal API, not exposed to users directly.

#### Key Functions

| Function | Description |
|----------|-------------|
| `api.ask(opts)` | Send a prompt to the current provider |
| `api.plan(opts)` | Request a structured plan from the provider |
| `api.apply_changes(result)` | Apply file changes from a response |
| `api.run_workflow(name, opts)` | Execute a named workflow |
| `api.get_context()` | Gather current buffer/selection context |
| `api.switch_provider(name)` | Change the active provider |

### `adapters/base.lua` - Adapter Interface

Defines the contract that all provider adapters must implement:

```lua
local Adapter = {}
Adapter.__index = Adapter

function Adapter:new(opts) end
function Adapter:ask(prompt, context, callback) end
function Adapter:apply_edit(instructions, callback) end
function Adapter:run_workflow(workflow_name, state, callback) end
function Adapter:cancel() end
function Adapter:is_available() end

return Adapter
```

### `adapters/claude.lua` - Claude Code Adapter

Implements the adapter interface for Claude Code CLI:

- Spawns `claude` process with appropriate flags
- Handles streaming output
- Parses structured responses
- Manages process lifecycle

### `adapters/gemini.lua` - Gemini CLI Adapter

Implements the adapter interface for Gemini CLI:

- Spawns `gemini` process with appropriate flags
- Handles streaming output
- Parses structured responses
- Manages process lifecycle

### `workflows/init.lua` - Workflow Engine

Manages complex multi-step agentic workflows:

- Workflow registration and discovery
- State machine for workflow execution
- Step-by-step execution with checkpoints
- Rollback capability for failed workflows

#### Built-in Workflows

| Workflow | Description |
|----------|-------------|
| `ask` | Simple question-answer |
| `summarize` | Summarise selected text |
| `refactor` | Apply structured refactoring |
| `generate` | Generate code into new buffer |
| `multi_file` | Coordinate multi-file operations |

### `ui.lua` - User Interface

Handles all buffer and window management:

- Creates output buffers for agent responses
- Manages floating windows for prompts
- Displays diff previews for changes
- Handles confirmation dialogs
- Streaming output display

#### Buffer Types

| Buffer Type | Purpose |
|-------------|---------|
| `output` | Displays agent responses |
| `diff` | Shows proposed changes |
| `prompt` | Input prompt editing |
| `status` | Workflow progress display |

### `commands.lua` - Command Registration

Registers and handles all user-facing commands:

| Command | Description |
|---------|-------------|
| `:PamojaAsk [prompt]` | Ask the agent a question |
| `:PamojaRefactor [instruction]` | Refactor selected code |
| `:PamojaTask [description]` | Run a complex task workflow |
| `:PamojaUse {claude\|gemini}` | Switch active provider |
| `:PamojaStatus` | Show current provider and status |
| `:PamojaCancel` | Cancel running operation |

## Data Flow

### Ask Operation

```
1. User: :PamojaAsk "How do I fix this?"
2. commands.lua: Parse command, extract prompt
3. api.ask(): Build context, call adapter
4. adapter:ask(): Spawn CLI process, stream output
5. ui.lua: Create output buffer, display streaming response
6. User: Views response in split/float buffer
```

### Refactor Operation

```
1. User: Selects code, :PamojaRefactor "Extract function"
2. commands.lua: Parse command, get visual selection
3. api.ask(): Build context with selection, call adapter
4. adapter:ask(): Request structured refactor response
5. api.apply_changes(): Parse response for file changes
6. ui.lua: Display diff preview, request confirmation
7. User: Confirms changes
8. api.apply_changes(): Write changes to files
```

### Multi-File Operation

```
1. User: :PamojaTask "Rename User to Account across codebase"
2. commands.lua: Parse command
3. api.run_workflow("multi_file"): Initialize workflow state
4. workflows: Execute planning step
5. adapter:plan(): Get list of files to modify
6. ui.lua: Display plan, request confirmation
7. User: Confirms plan
8. workflows: Execute each file modification step
9. adapter:apply_edit(): Generate changes per file
10. ui.lua: Aggregate diffs, final confirmation
11. api.apply_changes(): Write all changes atomically
```

## Multi-File Operation Safety

Multi-file operations use a staged approach:

1. **Planning Phase**: Agent identifies all files to modify
2. **Preview Phase**: User reviews complete change set
3. **Staging Phase**: Changes are written to temporary locations
4. **Confirmation Phase**: User confirms final application
5. **Application Phase**: Changes are written atomically
6. **Rollback Capability**: Original files are backed up until session ends

```lua
-- Change representation
{
  type = "multi_file",
  changes = {
    {
      path = "lua/foo.lua",
      hunks = {
        { start = 10, end = 15, content = "..." },
      },
    },
    -- ...
  },
  metadata = {
    backup_dir = "/tmp/agentic_backup_xxxx",
    created_at = 1234567890,
  },
}
```

## Provider Switching

```lua
-- Runtime provider switch
:PamojaUse gemini

-- Internally:
1. config.set_provider("gemini")
2. api.adapter = adapters.gemini:new(config.providers.gemini)
3. Current operation (if any) is cancelled
4. User notified of switch
```

## Error Handling

- All adapter operations include timeout handling
- Failed operations surface clear error messages to UI
- Partial multi-file operations can be rolled back
- Process crashes are detected and reported

## Extensibility

### Custom Workflows

Users can register custom workflows:

```lua
require("agentic.workflows").register("my_workflow", {
  steps = { "plan", "execute", "verify" },
  handlers = {
    plan = function(state, adapter, callback) end,
    execute = function(state, adapter, callback) end,
    verify = function(state, adapter, callback) end,
  },
})
```

### Custom Adapters

Third-party adapters can be implemented:

```lua
local MyAdapter = require("agentic.adapters.base"):extend()

function MyAdapter:ask(prompt, context, callback)
  -- Implementation
end

require("agentic").register_adapter("my_provider", MyAdapter)
```
