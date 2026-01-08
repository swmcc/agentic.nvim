# Adapters Domain Specification

## Overview

Adapters provide the interface between the plugin's internal API and external AI CLI tools. The adapter pattern enables provider-agnostic operations while encapsulating provider-specific implementation details.

## Requirements

### REQ-ADAPT-001: Base Adapter Interface

The base adapter MUST define a contract that all provider adapters SHALL implement:

- `new(opts)` - Constructor accepting provider configuration
- `is_available()` - Returns boolean indicating CLI tool availability
- `ask(prompt, context, callback, on_event)` - Sends prompt and handles response
- `cancel()` - Cancels any running operation
- `build_args(prompt, context)` - Builds CLI command arguments
- `parse_output(output)` - Parses raw CLI output into structured result
- `format_context(context)` - Formats context for inclusion in prompt

### REQ-ADAPT-002: Claude Code Adapter

The Claude adapter SHALL:

- Use the `claude` CLI command by default
- Support `--output-format stream-json` for streaming responses
- Parse newline-delimited JSON events from stdout
- Handle authentication errors with user-friendly messages
- Support configurable timeout (default 300000ms)
- Provide detailed event formatting for tool use blocks

### REQ-ADAPT-003: Gemini Adapter

The Gemini adapter SHALL:

- Use the `gemini` CLI command by default
- Support `-p` flag for prompt input
- Parse code blocks from markdown responses
- Handle streaming output via chunks
- Support configurable timeout (default 120000ms)

### REQ-ADAPT-004: Error Handling

All adapters MUST:

- Return `{ error = "message" }` on failure
- Detect and report authentication errors
- Detect and report rate limit errors
- Detect and report network errors
- Handle process spawn failures gracefully
- Never leave callbacks uncalled

### REQ-ADAPT-005: Timeout Management

Adapters MUST:

- Support configurable timeout values
- Support timeout = 0 to disable timeout
- Kill process on timeout expiration
- Return `{ error = "Request timed out", timed_out = true }` on timeout
- Clean up timer resources on cancel

### REQ-ADAPT-006: Cancellation

The `cancel()` method MUST:

- Stop any running timeout timer
- Kill the running process (SIGTERM)
- Clear internal handle references
- Be safe to call when no operation is running

## Scenarios

### SCEN-ADAPT-001: Successful Ask Operation

**Given** the Claude adapter is configured with valid credentials
**And** the CLI tool is available in PATH
**When** `ask()` is called with a prompt and context
**Then** the adapter SHALL spawn the CLI process
**And** stream JSON events to the `on_event` callback
**And** call the completion callback with `{ content = "response" }`

### SCEN-ADAPT-002: CLI Not Available

**Given** the adapter's CLI tool is not installed
**When** `ask()` is called
**Then** the adapter SHALL immediately call callback with `{ error = "CLI not found..." }`
**And** SHALL NOT attempt to spawn a process

### SCEN-ADAPT-003: Authentication Failure

**Given** the user is not authenticated with the provider
**When** `ask()` is called
**Then** the adapter SHALL detect the authentication error
**And** SHALL call callback with `{ error = "Authentication required..." }`

### SCEN-ADAPT-004: Request Timeout

**Given** the adapter has a timeout of 5000ms configured
**When** `ask()` is called
**And** the response takes longer than 5000ms
**Then** the adapter SHALL kill the process
**And** SHALL call callback with `{ error = "Request timed out", timed_out = true }`

### SCEN-ADAPT-005: User Cancellation

**Given** an ask operation is in progress
**When** `cancel()` is called
**Then** the adapter SHALL stop the timeout timer
**And** SHALL kill the running process
**And** SHALL clear internal references

### SCEN-ADAPT-006: Context Formatting

**Given** context includes filename, filetype, and selection
**When** `format_context()` is called
**Then** the adapter SHALL return a formatted string including:
- File path
- Filetype
- Selected code with line numbers in code block

### SCEN-ADAPT-007: Spawn Failure

**Given** the CLI tool exists but cannot be spawned
**When** `ask()` is called
**And** `vim.loop.spawn` returns nil
**Then** the adapter SHALL close pipe resources
**And** SHALL call callback with `{ error = "Failed to spawn..." }`

### SCEN-ADAPT-008: Stream JSON Parsing (Claude)

**Given** Claude returns newline-delimited JSON events
**When** processing stdout data
**Then** the adapter SHALL buffer partial lines
**And** SHALL parse complete JSON lines
**And** SHALL handle invalid JSON gracefully without crashing

### SCEN-ADAPT-009: Code Block Extraction (Gemini)

**Given** Gemini returns markdown with code blocks
**When** `parse_output()` is called
**Then** the adapter SHALL extract code blocks
**And** SHALL include language information when available
**And** SHALL return extracted blocks in `code_blocks` array
