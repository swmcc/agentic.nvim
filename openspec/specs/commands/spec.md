# Commands Domain Specification

## Overview

The commands module registers all user-facing Vim commands for the plugin. Commands follow the `:Pamoja*` naming convention and provide the primary interface for users to interact with AI agents.

## Requirements

### REQ-CMD-001: Command Registration

All commands MUST:

- Be registered using `vim.api.nvim_create_user_command`
- Use the `Pamoja` prefix for namespace consistency
- Include a `desc` field for discoverability
- Support appropriate completion where applicable

### REQ-CMD-002: PamojaAsk Command

The `:PamojaAsk` command SHALL:

- Accept optional inline prompt argument
- Open prompt input window if no argument provided
- Include current file context in request
- Route through `api.ask()` with `include_file = true`

### REQ-CMD-003: PamojaSummarise Command

The `:PamojaSummarise` command SHALL:

- Work in visual mode with selected text
- Support range via `range = true` option
- Route through `api.summarize()`
- Display summary in floating window

### REQ-CMD-004: PamojaRefactor Command

The `:PamojaRefactor` command SHALL:

- Accept optional instruction argument
- Open prompt input if no argument provided
- Work with visual selection (optional)
- Route through `api.refactor()` with `apply_changes = true`

### REQ-CMD-005: PamojaGenerate Command

The `:PamojaGenerate` command SHALL:

- Accept optional description argument
- Open prompt input if no argument provided
- Route through `api.generate()`
- Display generated code in new buffer

### REQ-CMD-006: PamojaTask Command

The `:PamojaTask` command SHALL:

- Accept optional task description argument
- Open prompt input if no argument provided
- Run `multi_file` workflow with `require_confirmation = true`
- Show plan before execution

### REQ-CMD-007: PamojaUse Command

The `:PamojaUse` command SHALL:

- Accept provider name as argument
- Show provider selection UI if no argument
- Support completion with available providers
- Switch provider via `api.switch_provider()`
- Display confirmation message

### REQ-CMD-008: PamojaStatus Command

The `:PamojaStatus` command SHALL:

- Take no arguments
- Display current provider name
- Display availability status ("ready" or "not available")

### REQ-CMD-009: PamojaCancel Command

The `:PamojaCancel` command SHALL:

- Take no arguments
- Cancel current running operation via `api.cancel()`

## Scenarios

### SCEN-CMD-001: Ask With Inline Prompt

**Given** user is editing a Lua file
**When** user runs `:PamojaAsk How do I fix this?`
**Then** the plugin SHALL call `api.ask()` with:
- `prompt`: "How do I fix this?"
- `context.include_file`: true

### SCEN-CMD-002: Ask Without Prompt

**Given** user is editing any file
**When** user runs `:PamojaAsk` (no arguments)
**Then** the plugin SHALL open prompt input window
**And** SHALL wait for user input
**And** SHALL call `api.ask()` after submission

### SCEN-CMD-003: Summarise Selection

**Given** user has visually selected lines 10-20
**When** user runs `:'<,'>PamojaSummarise`
**Then** the plugin SHALL call `api.summarize()` with:
- `use_selection`: true

### SCEN-CMD-004: Refactor With Instruction

**Given** user has code selected
**When** user runs `:'<,'>PamojaRefactor Extract function`
**Then** the plugin SHALL call `api.refactor()` with:
- `prompt`: "Extract function"
- `use_selection`: true

### SCEN-CMD-005: Generate Code

**Given** user wants to generate new code
**When** user runs `:PamojaGenerate Create a config parser`
**Then** the plugin SHALL call `api.generate()` with:
- `prompt`: "Create a config parser"

### SCEN-CMD-006: Run Multi-File Task

**Given** user wants to perform a codebase-wide change
**When** user runs `:PamojaTask Rename User to Account`
**Then** the plugin SHALL call `api.run_workflow("multi_file")` with:
- `prompt`: "Rename User to Account"
- `require_confirmation`: true

### SCEN-CMD-007: Switch Provider Explicitly

**Given** user is currently using Claude
**When** user runs `:PamojaUse gemini`
**Then** the plugin SHALL call `api.switch_provider("gemini")`
**And** SHALL show status message "Switched to gemini"

### SCEN-CMD-008: Switch Provider With Selection

**Given** multiple providers are configured
**When** user runs `:PamojaUse` (no argument)
**Then** the plugin SHALL show provider selection UI
**And** SHALL switch to selected provider

### SCEN-CMD-009: Check Status

**Given** Claude is configured and available
**When** user runs `:PamojaStatus`
**Then** the plugin SHALL display "Provider: claude (ready)"

### SCEN-CMD-010: Check Status Unavailable

**Given** Gemini is configured but CLI not installed
**When** user runs `:PamojaStatus`
**Then** the plugin SHALL display "Provider: gemini (not available)"

### SCEN-CMD-011: Cancel Operation

**Given** an ask operation is in progress
**When** user runs `:PamojaCancel`
**Then** the plugin SHALL call `api.cancel()`
**And** operation SHALL be terminated

### SCEN-CMD-012: Command Completion

**Given** user types `:PamojaUse ` and presses Tab
**Then** completion SHALL show available providers
**And** user can select from list
