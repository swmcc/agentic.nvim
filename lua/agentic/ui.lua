---@mod agentic.ui User interface components
---@brief [[
--- Handles buffer creation, window management, and user interaction.
---@brief ]]

local M = {}

local config = require("agentic.config")

---@type number|nil Output buffer number
local output_buf = nil

---@type number|nil Output window number
local output_win = nil

--- Create an output buffer for agent responses
---@param opts table Options (title, output type)
---@return number buffer
function M.create_output_buffer(opts)
  opts = opts or {}
  local output_type = opts.output or config.get("ui.output")
  local title = opts.title or "Agentic"

  -- Create buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buf, string.format("[%s]", title))
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "markdown"

  -- Create window based on output type
  local win

  if output_type == "float" then
    win = M._create_float_window(buf, opts)
  elseif output_type == "tab" then
    vim.cmd("tabnew")
    win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, buf)
  else -- split (default)
    win = M._create_split_window(buf, opts)
  end

  output_buf = buf
  output_win = win

  -- Set up buffer keymaps
  vim.keymap.set("n", "q", function()
    M.close_output()
  end, { buffer = buf, desc = "Close output" })

  return buf
end

--- Create a split window
---@param buf number Buffer number
---@param opts table Options
---@return number window
function M._create_split_window(buf, opts)
  local direction = config.get("ui.split_direction") or "below"
  local size = config.get("ui.split_size") or 15

  local split_cmd = {
    below = "botright split",
    above = "topleft split",
    left = "topleft vsplit",
    right = "botright vsplit",
  }

  vim.cmd(split_cmd[direction] or "botright split")
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)

  -- Set window size
  if direction == "below" or direction == "above" then
    vim.api.nvim_win_set_height(win, size)
  else
    vim.api.nvim_win_set_width(win, size)
  end

  return win
end

--- Create a floating window
---@param buf number Buffer number
---@param opts table Options
---@return number window
function M._create_float_window(buf, opts)
  local width_ratio = config.get("ui.float_width") or 0.8
  local height_ratio = config.get("ui.float_height") or 0.6

  local width = math.floor(vim.o.columns * width_ratio)
  local height = math.floor(vim.o.lines * height_ratio)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = opts.title or "Agentic",
    title_pos = "center",
  })

  return win
end

--- Append content to a buffer
---@param buf number Buffer number
---@param content string Content to append
function M.append_to_buffer(buf, content)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  local lines = vim.split(content, "\n")
  local line_count = vim.api.nvim_buf_line_count(buf)

  -- Check if buffer is empty
  local first_line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
  if first_line == "" and line_count == 1 then
    vim.api.nvim_buf_set_lines(buf, 0, 1, false, lines)
  else
    vim.api.nvim_buf_set_lines(buf, -1, -1, false, lines)
  end

  -- Scroll to bottom if window is valid
  if output_win and vim.api.nvim_win_is_valid(output_win) then
    local new_count = vim.api.nvim_buf_line_count(buf)
    vim.api.nvim_win_set_cursor(output_win, { new_count, 0 })
  end
end

--- Close the output buffer/window
function M.close_output()
  if output_win and vim.api.nvim_win_is_valid(output_win) then
    vim.api.nvim_win_close(output_win, true)
  end
  output_win = nil
  output_buf = nil
end

--- Show an error message
---@param message string Error message
function M.show_error(message)
  vim.notify("Agentic Error: " .. message, vim.log.levels.ERROR)
end

--- Show a status message
---@param message string Status message
function M.show_status(message)
  vim.notify(message, vim.log.levels.INFO)
end

--- Show confirmation dialog
---@param message string Confirmation message
---@param callback fun(confirmed: boolean) Callback with result
function M.confirm(message, callback)
  vim.ui.select(
    { "Yes", "No" },
    { prompt = message },
    function(choice)
      callback(choice == "Yes")
    end
  )
end

--- Show diff preview for changes
---@param changes table List of changes
---@param callback fun(confirmed: boolean) Callback with result
function M.show_diff_preview(changes, callback)
  if not changes or #changes == 0 then
    callback(true)
    return
  end

  -- Create diff buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].filetype = "diff"

  local lines = { "# Proposed Changes", "" }

  for i, change in ipairs(changes) do
    table.insert(lines, string.format("## Change %d: %s", i, change.path or "buffer"))
    table.insert(lines, "")
    table.insert(lines, "```diff")

    if change.type == "replace" then
      table.insert(lines, string.format("@@ -%d,%d +%d,%d @@",
        change.start_line, change.end_line - change.start_line + 1,
        change.start_line, #vim.split(change.content, "\n")
      ))
    end

    for _, line in ipairs(vim.split(change.content, "\n")) do
      table.insert(lines, "+ " .. line)
    end

    table.insert(lines, "```")
    table.insert(lines, "")
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  -- Create float window
  local win = M._create_float_window(buf, { title = "Review Changes" })

  -- Set up keymaps for confirmation
  vim.keymap.set("n", "y", function()
    vim.api.nvim_win_close(win, true)
    callback(true)
  end, { buffer = buf, desc = "Accept changes" })

  vim.keymap.set("n", "n", function()
    vim.api.nvim_win_close(win, true)
    callback(false)
  end, { buffer = buf, desc = "Reject changes" })

  vim.keymap.set("n", "q", function()
    vim.api.nvim_win_close(win, true)
    callback(false)
  end, { buffer = buf, desc = "Cancel" })

  -- Show instructions
  vim.notify("Press 'y' to accept, 'n' or 'q' to reject", vim.log.levels.INFO)
end

--- Create a new buffer with generated code
---@param content string Generated code content
---@param filetype? string Filetype to set
---@return number buffer
function M.create_code_buffer(content, filetype)
  local buf = vim.api.nvim_create_buf(true, false)

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(content, "\n"))

  if filetype then
    vim.bo[buf].filetype = filetype
  end

  -- Open in split
  vim.cmd("vsplit")
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)

  return buf
end

--- Open a prompt input buffer
---@param opts table Options (prompt, callback)
function M.open_prompt_input(opts)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].filetype = "markdown"

  -- Add placeholder text
  local placeholder = opts.placeholder or "Enter your prompt here..."
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { placeholder })

  -- Create float
  local win = M._create_float_window(buf, { title = opts.title or "Prompt" })

  -- Select all text
  vim.cmd("normal! ggVG")

  -- Set up submit keymap
  vim.keymap.set("n", "<CR>", function()
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local prompt = table.concat(lines, "\n")
    vim.api.nvim_win_close(win, true)

    if opts.callback then
      opts.callback(prompt)
    end
  end, { buffer = buf, desc = "Submit prompt" })

  vim.keymap.set("n", "q", function()
    vim.api.nvim_win_close(win, true)
  end, { buffer = buf, desc = "Cancel" })

  vim.keymap.set("n", "<Esc>", function()
    vim.api.nvim_win_close(win, true)
  end, { buffer = buf, desc = "Cancel" })
end

return M
