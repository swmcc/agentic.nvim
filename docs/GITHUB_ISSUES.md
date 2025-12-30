# GitHub Issues

All issues required for the agentic.nvim MVP.

---

## Architecture Issues

### Issue #1: Design plugin module architecture
**Labels:** `🏗️ architecture`, `🚀 mvp`

**Description:**
Finalize the modular architecture for agentic.nvim, ensuring clean separation between API, adapters, workflows, and UI components.

**Acceptance Criteria:**
- [ ] Module dependency graph is documented
- [ ] Each module has a single responsibility
- [ ] No circular dependencies exist
- [ ] Public vs private API boundaries are clear

---

### Issue #2: Define adapter interface contract
**Labels:** `🏗️ architecture`, `🔧 backend`, `🔌 api`

**Description:**
Define the base adapter interface that all provider implementations must follow.

**Acceptance Criteria:**
- [ ] `Adapter:new(opts)` initializes adapter with config
- [ ] `Adapter:ask(prompt, context, callback)` sends prompts
- [ ] `Adapter:apply_edit(instructions, callback)` applies changes
- [ ] `Adapter:run_workflow(name, state, callback)` executes workflows
- [ ] `Adapter:cancel()` stops running operations
- [ ] `Adapter:is_available()` checks CLI availability

---

### Issue #3: Design internal plugin API
**Labels:** `🏗️ architecture`, `🔌 api`, `🚀 mvp`

**Description:**
Design the internal API layer that all plugin functionality routes through.

**Acceptance Criteria:**
- [ ] `api.ask(opts)` function defined
- [ ] `api.plan(opts)` function defined
- [ ] `api.apply_changes(result)` function defined
- [ ] `api.run_workflow(name, opts)` function defined
- [ ] Context gathering utilities implemented
- [ ] Provider switching logic implemented

---

## Backend Adapter Issues

### Issue #4: Implement Claude Code adapter
**Labels:** `🔧 backend`, `🤓 lua`, `🚀 mvp`

**Description:**
Implement the adapter for Claude Code CLI.

**Acceptance Criteria:**
- [ ] Spawns `claude` process correctly
- [ ] Passes prompts with `--print` flag
- [ ] Handles streaming output
- [ ] Parses responses for code blocks
- [ ] Implements timeout handling
- [ ] Cancellation works correctly
- [ ] Error states handled gracefully

---

### Issue #5: Implement Gemini CLI adapter
**Labels:** `🔧 backend`, `🤓 lua`, `🚀 mvp`

**Description:**
Implement the adapter for Gemini CLI.

**Acceptance Criteria:**
- [ ] Spawns `gemini` process correctly
- [ ] Passes prompts with `-p` flag
- [ ] Handles streaming output
- [ ] Parses responses for code blocks
- [ ] Implements timeout handling
- [ ] Cancellation works correctly
- [ ] Error states handled gracefully

---

### Issue #6: Implement provider switching
**Labels:** `🔧 backend`, `🔌 api`, `🚀 mvp`

**Description:**
Implement runtime switching between Claude and Gemini providers.

**Acceptance Criteria:**
- [ ] `:PamojaUse claude` switches to Claude
- [ ] `:PamojaUse gemini` switches to Gemini
- [ ] Current operation cancelled on switch
- [ ] User notified of switch
- [ ] Tab completion works for provider names

---

## Workflow Issues

### Issue #7: Implement workflow engine
**Labels:** `🔄 workflow`, `🤓 lua`, `🚀 mvp`

**Description:**
Implement the workflow engine for multi-step operations.

**Acceptance Criteria:**
- [ ] Workflow registration works
- [ ] Step-by-step execution implemented
- [ ] State management between steps works
- [ ] Confirmation prompts work
- [ ] Cancellation works mid-workflow
- [ ] Error handling works per-step

---

### Issue #8: Implement ask workflow
**Labels:** `🔄 workflow`, `🚀 mvp`

**Description:**
Implement the basic ask workflow for Q&A operations.

**Acceptance Criteria:**
- [ ] Single-step query workflow
- [ ] Context gathering works
- [ ] Output displays correctly
- [ ] Works with both providers

---

### Issue #9: Implement summarise workflow
**Labels:** `🔄 workflow`, `🚀 mvp`

**Description:**
Implement the summarise workflow for text summarization.

**Acceptance Criteria:**
- [ ] Accepts visual selection
- [ ] Sends selection with summarise prompt
- [ ] Output displays in float window
- [ ] Works with both providers

---

### Issue #10: Implement refactor workflow
**Labels:** `🔄 workflow`, `🚀 mvp`

**Description:**
Implement the refactor workflow with diff preview.

**Acceptance Criteria:**
- [ ] Two-step workflow (analyze, refactor)
- [ ] Diff preview displayed
- [ ] Confirmation required before apply
- [ ] Changes applied to buffer
- [ ] Works with both providers

---

### Issue #11: Implement generate workflow
**Labels:** `🔄 workflow`, `🚀 mvp`

**Description:**
Implement the code generation workflow.

**Acceptance Criteria:**
- [ ] Single-step generation
- [ ] Output opens in new buffer
- [ ] Filetype detected and set
- [ ] Works with both providers

---

### Issue #12: Implement multi-file workflow
**Labels:** `🔄 workflow`, `🚀 mvp`

**Description:**
Implement the multi-file task workflow with planning.

**Acceptance Criteria:**
- [ ] Three-step workflow (plan, confirm, execute)
- [ ] Plan displayed for review
- [ ] Confirmation required at each stage
- [ ] Simulated execution in MVP
- [ ] Works with both providers

---

## UI Issues

### Issue #13: Implement output buffer management
**Labels:** `🎨 ux`, `🤓 lua`, `🚀 mvp`

**Description:**
Implement buffer creation and management for agent output.

**Acceptance Criteria:**
- [ ] Split window creation works
- [ ] Float window creation works
- [ ] Tab window creation works
- [ ] Content streaming/appending works
- [ ] Close keymaps work (q, Esc)
- [ ] Markdown filetype set

---

### Issue #14: Implement diff preview UI
**Labels:** `🎨 ux`, `🚀 mvp`

**Description:**
Implement diff preview for proposed changes.

**Acceptance Criteria:**
- [ ] Diff displayed in float window
- [ ] Diff syntax highlighting works
- [ ] Accept/reject keymaps work (y/n/q)
- [ ] Instructions shown to user
- [ ] Multiple changes aggregated

---

### Issue #15: Implement prompt input UI
**Labels:** `🎨 ux`, `🚀 mvp`

**Description:**
Implement floating prompt input buffer.

**Acceptance Criteria:**
- [ ] Float window opens for input
- [ ] Placeholder text shown
- [ ] Submit on Enter works
- [ ] Cancel on Esc/q works
- [ ] Title displayed correctly

---

### Issue #16: Implement confirmation dialogs
**Labels:** `🎨 ux`, `🚀 mvp`

**Description:**
Implement confirmation dialogs using vim.ui.select.

**Acceptance Criteria:**
- [ ] Yes/No selection works
- [ ] Callback receives result
- [ ] Integrates with workflow engine

---

## Command Issues

### Issue #17: Implement :PamojaAsk command
**Labels:** `🤓 lua`, `🚀 mvp`

**Description:**
Implement the ask command for querying the agent.

**Acceptance Criteria:**
- [ ] `:PamojaAsk prompt` works inline
- [ ] `:PamojaAsk` opens prompt input
- [ ] Context gathered from current buffer
- [ ] Output displayed in split

---

### Issue #18: Implement :PamojaSummarise command
**Labels:** `🤓 lua`, `🚀 mvp`

**Description:**
Implement the summarise command for visual selections.

**Acceptance Criteria:**
- [ ] Works with visual selection
- [ ] `:' <,'>AgenticSummarise` works
- [ ] Output displayed in float

---

### Issue #19: Implement :PamojaRefactor command
**Labels:** `🤓 lua`, `🚀 mvp`

**Description:**
Implement the refactor command.

**Acceptance Criteria:**
- [ ] Works with and without selection
- [ ] Inline instruction works
- [ ] Prompt input works
- [ ] Diff preview shown
- [ ] Changes applied on confirm

---

### Issue #20: Implement :PamojaGenerate command
**Labels:** `🤓 lua`, `🚀 mvp`

**Description:**
Implement the generate command.

**Acceptance Criteria:**
- [ ] Inline description works
- [ ] Prompt input works
- [ ] Output opens in new buffer

---

### Issue #21: Implement :PamojaTask command
**Labels:** `🤓 lua`, `🚀 mvp`

**Description:**
Implement the multi-step task command.

**Acceptance Criteria:**
- [ ] Inline description works
- [ ] Prompt input works
- [ ] Multi-file workflow triggered
- [ ] Confirmations at each step

---

### Issue #22: Implement :PamojaStatus command
**Labels:** `🤓 lua`, `🚀 mvp`

**Description:**
Implement the status command.

**Acceptance Criteria:**
- [ ] Shows current provider
- [ ] Shows availability status
- [ ] Clear notification message

---

### Issue #23: Implement :PamojaCancel command
**Labels:** `🤓 lua`, `🚀 mvp`

**Description:**
Implement the cancel command.

**Acceptance Criteria:**
- [ ] Cancels running adapter operation
- [ ] Cancels running workflow
- [ ] User notified of cancellation

---

## Documentation Issues

### Issue #24: Write user documentation
**Labels:** `📚 docs`, `🚀 mvp`

**Description:**
Write comprehensive user documentation in README.

**Acceptance Criteria:**
- [ ] Installation instructions complete
- [ ] Configuration options documented
- [ ] All commands documented with examples
- [ ] Usage examples provided
- [ ] Requirements listed

---

### Issue #25: Write architecture documentation
**Labels:** `📚 docs`, `🏗️ architecture`

**Description:**
Write technical architecture documentation.

**Acceptance Criteria:**
- [ ] Module diagram included
- [ ] Data flow documented
- [ ] Adapter interface documented
- [ ] Workflow engine documented
- [ ] Extension points documented

---

## Testing Issues

### Issue #26: Manual testing checklist
**Labels:** `✅ testing`, `🚀 mvp`

**Description:**
Create and execute manual testing checklist for MVP.

**Acceptance Criteria:**
- [ ] All commands tested with Claude
- [ ] All commands tested with Gemini
- [ ] Provider switching tested
- [ ] Error states tested
- [ ] Cancel operations tested
- [ ] UI components tested

---

### Issue #27: Validate Claude CLI integration
**Labels:** `✅ testing`, `🔧 backend`

**Description:**
Validate Claude Code CLI integration works correctly.

**Acceptance Criteria:**
- [ ] CLI detection works
- [ ] Authentication handled
- [ ] Prompts sent correctly
- [ ] Responses parsed correctly
- [ ] Timeout works
- [ ] Cancellation works

---

### Issue #28: Validate Gemini CLI integration
**Labels:** `✅ testing`, `🔧 backend`

**Description:**
Validate Gemini CLI integration works correctly.

**Acceptance Criteria:**
- [ ] CLI detection works
- [ ] Authentication handled
- [ ] Prompts sent correctly
- [ ] Responses parsed correctly
- [ ] Timeout works
- [ ] Cancellation works

---

## GitHub CLI Commands

Create all issues using the GitHub CLI:

```bash
# Issue #1
gh issue create --title "Design plugin module architecture" \
  --body "Finalize the modular architecture for agentic.nvim..." \
  --label "🏗️ architecture" --label "🚀 mvp"

# Issue #2
gh issue create --title "Define adapter interface contract" \
  --body "Define the base adapter interface..." \
  --label "🏗️ architecture" --label "🔧 backend" --label "🔌 api"

# ... continue for all issues
```

## Issue Summary

| Category | Count |
|----------|-------|
| Architecture | 3 |
| Backend | 3 |
| Workflow | 6 |
| UI | 4 |
| Commands | 7 |
| Documentation | 2 |
| Testing | 3 |
| **Total** | **28** |
