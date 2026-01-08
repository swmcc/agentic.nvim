# Workflows Domain Specification

## Overview

The workflow engine manages complex multi-step agentic operations. Workflows provide a structured way to chain AI operations with state management, confirmation gates, and rollback capability.

## Requirements

### REQ-WORK-001: Workflow Registration

The workflow engine MUST support:

- Registering workflows by name
- Defining workflow steps as an ordered array
- Associating handler functions with each step
- Retrieving registered workflows by name

### REQ-WORK-002: Workflow Execution

The workflow engine SHALL:

- Initialize workflow state with prompt, context, and options
- Execute steps in defined order
- Pass state and adapter to each step handler
- Store step results in state for subsequent steps
- Support optional confirmation gates between steps

### REQ-WORK-003: Built-in Workflows

The plugin SHALL provide these built-in workflows:

| Workflow | Steps | Purpose |
|----------|-------|---------|
| `ask` | query | Simple question-answer |
| `summarize` | summarize | Summarize selected text |
| `refactor` | analyze, refactor | Structured code refactoring |
| `generate` | generate | Generate new code |
| `multi_file` | plan, confirm, execute | Multi-file operations |

### REQ-WORK-004: Confirmation Gates

Workflows MUST support:

- Optional confirmation between steps
- Step handlers returning `{ requires_confirmation = true }`
- UI confirmation dialog before proceeding
- Cancellation if user declines

### REQ-WORK-005: Error Handling

The workflow engine MUST:

- Detect and report missing step handlers
- Propagate adapter errors to completion callback
- Provide workflow failure notifications
- Clean up state on failure

### REQ-WORK-006: Cancellation

The workflow engine MUST support:

- Cancelling running workflows
- Cancelling adapter operations on workflow cancel
- Notifying user of cancellation
- Calling completion callback with `{ cancelled = true }`

### REQ-WORK-007: Status Reporting

The workflow engine SHALL:

- Track current workflow name
- Track current step index
- Provide status via `get_status()` method
- Report `is_running()` state

## Scenarios

### SCEN-WORK-001: Simple Ask Workflow

**Given** the "ask" workflow is registered
**When** `run("ask", { prompt = "question" })` is called
**Then** the workflow engine SHALL execute the "query" step
**And** SHALL call the adapter's `ask()` method
**And** SHALL complete successfully with response

### SCEN-WORK-002: Multi-Step Workflow

**Given** the "refactor" workflow with steps ["analyze", "refactor"]
**When** the workflow is executed
**Then** the engine SHALL execute "analyze" first
**And** SHALL store analyze results in state
**And** SHALL execute "refactor" with prior results available

### SCEN-WORK-003: Confirmation Required

**Given** a workflow with `require_confirmation = true`
**And** step handler returns `{ requires_confirmation = true }`
**When** the step completes
**Then** the engine SHALL show confirmation dialog
**And** SHALL only proceed if user confirms
**And** SHALL cancel workflow if user declines

### SCEN-WORK-004: Multi-File Planning

**Given** the "multi_file" workflow
**When** executed with a task description
**Then** the "plan" step SHALL request file list from adapter
**And** SHALL require confirmation before "execute" step
**And** SHALL show all planned files for review

### SCEN-WORK-005: Workflow Failure

**Given** a running workflow
**When** a step handler returns `{ error = "message" }`
**Then** the engine SHALL stop execution
**And** SHALL call `_fail_workflow()` with error
**And** SHALL notify user of failure
**And** SHALL call completion callback with error

### SCEN-WORK-006: Missing Handler

**Given** a workflow with step "missing_step"
**When** execution reaches that step
**And** no handler is registered for "missing_step"
**Then** the engine SHALL fail with "Missing step handler" error

### SCEN-WORK-007: Workflow Cancellation

**Given** a workflow is in progress at step 2 of 3
**When** `cancel()` is called
**Then** the engine SHALL cancel the adapter operation
**And** SHALL call completion callback with `{ cancelled = true }`
**And** SHALL clear current workflow state

### SCEN-WORK-008: Progress Reporting

**Given** a workflow with 3 steps
**When** executing step 2
**Then** `get_status()` SHALL return:
- `name`: workflow name
- `step`: 2
- `total_steps`: 3
- `current_step`: step name
