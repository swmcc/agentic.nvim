# UI Domain Specification

## Overview

The UI module manages all buffer and window interactions for displaying AI responses, prompts, confirmations, and diffs. It provides a consistent user experience across all plugin operations.

## Requirements

### REQ-UI-001: Floating Window Management

The UI module MUST:

- Create floating windows with rounded borders
- Center windows in the editor viewport
- Support configurable width and height (percentage of screen)
- Support window titles
- Close existing floats before creating new ones

### REQ-UI-002: Output Buffer

Output buffers MUST:

- Be non-editable (`modifiable = false`) after content is set
- Have filetype set to "markdown" for syntax highlighting
- Support streaming content updates
- Be closeable with `q` or `<Esc>` keys
- Support promotion to split with `v` (vertical) or `s` (horizontal)

### REQ-UI-003: Streaming Display

For streaming responses, the UI SHALL:

- Show "Waiting for response..." initially
- Clear waiting message on first chunk
- Append chunks to existing content
- Auto-scroll to latest content
- Allow temporary modification during streaming

### REQ-UI-004: Prompt Input

Prompt input windows MUST:

- Open in insert mode
- Support multi-line input
- Submit on `<CR>` in normal or insert mode
- Cancel on `<Esc>`
- Clear placeholder text on edit

### REQ-UI-005: Confirmation Dialogs

Confirmation dialogs SHALL:

- Display message prominently
- Show `[y] Yes [n] No` options
- Accept `y`, `n`, `q`, or `<Esc>` for response
- Call callback with boolean result
- Close automatically after selection

### REQ-UI-006: Diff Preview

Diff preview windows MUST:

- Show all proposed changes with file paths
- Use diff filetype for syntax highlighting
- Show added lines with `+` prefix
- Provide accept/reject options
- Support reviewing multiple file changes

### REQ-UI-007: Provider Selection

Provider selection UI MUST:

- List available providers with numeric keys
- Allow selection via number keys (1, 2, etc.)
- Allow cancellation with `q`
- Call callback with selected provider name

### REQ-UI-008: Status Display

Status messages MUST:

- Show in appropriately sized floating window
- Include close instructions
- Auto-size based on message length

## Scenarios

### SCEN-UI-001: Create Output Buffer

**Given** no floating window is currently open
**When** `create_output_buffer()` is called
**Then** a new floating buffer SHALL be created
**And** window SHALL be centered in viewport
**And** keymaps for `q`, `<Esc>`, `v`, `s` SHALL be set

### SCEN-UI-002: Show Loading State

**Given** an operation is starting
**When** `show_loading()` is called
**Then** a floating window SHALL appear
**And** SHALL display "Waiting for response..."
**And** `state.streaming` SHALL be set to true

### SCEN-UI-003: Stream Response Chunks

**Given** loading state is displayed
**When** `stream_chunk("Hello")` is called
**Then** "Waiting for response..." SHALL be cleared
**And** "Hello" SHALL appear in buffer
**And** cursor SHALL scroll to content

### SCEN-UI-004: Finish Streaming

**Given** streaming is in progress
**When** `finish_streaming()` is called
**Then** buffer SHALL become non-modifiable
**And** `state.streaming` SHALL be set to false

### SCEN-UI-005: Prompt Input Submission

**Given** prompt input window is open
**And** user has typed "refactor this"
**When** user presses `<CR>`
**Then** callback SHALL be called with "refactor this"
**And** window SHALL close
**And** insert mode SHALL end

### SCEN-UI-006: Confirmation Accept

**Given** confirmation dialog shows "Apply changes?"
**When** user presses `y`
**Then** callback SHALL be called with `true`
**And** dialog SHALL close

### SCEN-UI-007: Confirmation Reject

**Given** confirmation dialog shows "Apply changes?"
**When** user presses `n` or `q` or `<Esc>`
**Then** callback SHALL be called with `false`
**And** dialog SHALL close

### SCEN-UI-008: Diff Review Accept

**Given** diff preview shows 3 file changes
**When** user presses `y`
**Then** callback SHALL be called with `true`
**And** preview SHALL close

### SCEN-UI-009: Promote to Split

**Given** floating output window is displaying response
**When** user presses `v`
**Then** float SHALL close
**And** content SHALL appear in vertical split
**And** buffer SHALL remain available

### SCEN-UI-010: Provider Selection

**Given** providers ["claude", "gemini"] are available
**When** `select_provider()` is called
**Then** window SHALL show:
```
  [1] claude
  [2] gemini

  [q] cancel
```
**And** pressing `1` SHALL call callback with "claude"
