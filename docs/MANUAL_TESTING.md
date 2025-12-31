# Manual Testing Guide

This guide covers manual testing of Pamoja commands in Neovim.

## Prerequisites

1. Claude CLI installed and authenticated (`claude --version`)
2. Plugin loaded in Neovim (`:Lazy` shows agentic)
3. Restart Neovim or `:Lazy reload agentic` to pick up latest code

## Commands

### :PamojaStatus

Check current provider status.

```vim
:PamojaStatus
```

**Expected:** Float showing "Provider: claude (ready)" or "Provider: claude (not available)"

---

### :PamojaAsk

Ask the AI a question.

```vim
" With inline prompt
:PamojaAsk What is 2+2?

" Opens prompt dialog
:PamojaAsk
```

**Expected:**
- Float window opens with "Waiting for response..."
- Streams response in real-time
- Press `q` or `Esc` to close

---

### :PamojaSummarise

Summarise selected text (visual mode).

```vim
" 1. Select text with v or V
" 2. Run command
:'<,'>PamojaSummarise
```

**Expected:** Float with summary of selected text

---

### :PamojaRefactor

Refactor code with instruction.

```vim
" With inline instruction
:'<,'>PamojaRefactor make this more readable

" Opens prompt dialog
:'<,'>PamojaRefactor
```

**Expected:**
- Analysis shown first
- Confirmation prompt if `require_confirmation` enabled
- Refactored code displayed

---

### :PamojaGenerate

Generate new code.

```vim
" With inline description
:PamojaGenerate a function that calculates factorial

" Opens prompt dialog
:PamojaGenerate
```

**Expected:** Float with generated code

---

### :PamojaTask

Run multi-step task.

```vim
" With inline description
:PamojaTask add error handling to this module

" Opens prompt dialog
:PamojaTask
```

**Expected:**
- Step 1: Plan created
- Confirmation prompt
- Step 2: Execution

---

### :PamojaUse

Switch AI provider.

```vim
" Direct switch
:PamojaUse claude
:PamojaUse gemini

" Opens selection dialog
:PamojaUse
```

**Expected:** Status message confirming switch

---

### :PamojaCancel

Cancel running operation.

```vim
:PamojaCancel
```

**Expected:** Running operation stops, window closes

---

## Troubleshooting

### Check for errors

```vim
:messages
```

### Verify plugin loaded

```vim
:lua print(require('agentic').version())
```

Should print: `0.1.0`

### Verify CLI available

```vim
:lua print(require('agentic').is_ready())
```

Should print: `true`

### Check current provider

```vim
:lua print(require('agentic').get_provider())
```

Should print: `claude` or `gemini`

---

## UI Controls

| Key | Action |
|-----|--------|
| `q` | Close float window |
| `Esc` | Close float window |
| `v` | Promote float to vertical split |
| `s` | Promote float to horizontal split |
| `y` | Accept (in confirmation dialogs) |
| `n` | Reject (in confirmation dialogs) |
| `Enter` | Submit (in prompt input) |
