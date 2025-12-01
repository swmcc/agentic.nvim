local M = {}

local config = require("agentic.config")

local state = {
  win = nil,
  buf = nil,
  input_win = nil,
  input_buf = nil,
}

local function create_float(opts)
  opts = opts or {}
  local width = opts.width or math.floor(vim.o.columns * 0.8)
  local height = opts.height or math.floor(vim.o.lines * 0.7)
  local row = math.floor((vim.o.lines - height) / 2) - 1
  local col = math.floor((vim.o.columns - width) / 2)

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = opts.filetype or "markdown"

  local win_opts = {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = opts.title and (" " .. opts.title .. " ") or nil,
    title_pos = "center",
  }

  local win = vim.api.nvim_open_win(buf, true, win_opts)

  vim.wo[win].wrap = true
  vim.wo[win].linebreak = true
  vim.wo[win].cursorline = true
  vim.wo[win].winhighlight = "Normal:Normal,FloatBorder:FloatBorder,CursorLine:Visual"

  return buf, win
end

local function close_float()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
  end
  if state.input_win and vim.api.nvim_win_is_valid(state.input_win) then
    vim.api.nvim_win_close(state.input_win, true)
  end
  state.win = nil
  state.buf = nil
  state.input_win = nil
  state.input_buf = nil
end

local function set_float_keymaps(buf, on_close)
  local function close()
    close_float()
    if on_close then on_close() end
  end

  vim.keymap.set("n", "q", close, { buffer = buf, nowait = true })
  vim.keymap.set("n", "<Esc>", close, { buffer = buf, nowait = true })
end

function M.create_output_buffer(opts)
  close_float()

  local buf, win = create_float({
    title = opts.title or "Pamoja",
    filetype = "markdown",
  })

  state.buf = buf
  state.win = win

  set_float_keymaps(buf)

  return buf
end

function M._create_float_window(buf, opts)
  return create_float(opts)
end

function M._create_split_window(buf, opts)
  return create_float(opts)
end

function M.append_to_buffer(_, content)
  local buf = state.buf
  if not buf or not vim.api.nvim_buf_is_valid(buf) then return end

  vim.bo[buf].modifiable = true
  local lines = vim.split(content, "\n")
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_set_cursor(state.win, { 1, 0 })
  end
  vim.bo[buf].modifiable = false
end

function M.close_output()
  close_float()
end

function M.show_error(message)
  vim.notify(message, vim.log.levels.ERROR, { title = "Pamoja" })
end

function M.show_status(message)
  close_float()

  local lines = {
    "",
    "  " .. message,
    "",
    "  [q] close",
  }

  local buf, win = create_float({
    title = "Pamoja",
    width = math.max(#message + 10, 40),
    height = 6,
  })

  state.buf = buf
  state.win = win

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false

  set_float_keymaps(buf)
end

function M.confirm(message, callback)
  close_float()

  local lines = {
    "",
    "  " .. message,
    "",
    "  [y] Yes    [n] No",
    "",
  }

  local buf, win = create_float({
    title = "Confirm",
    width = math.max(#message + 10, 40),
    height = 7,
  })

  state.buf = buf
  state.win = win

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false

  vim.keymap.set("n", "y", function()
    close_float()
    callback(true)
  end, { buffer = buf, nowait = true })

  vim.keymap.set("n", "n", function()
    close_float()
    callback(false)
  end, { buffer = buf, nowait = true })

  vim.keymap.set("n", "q", function()
    close_float()
    callback(false)
  end, { buffer = buf, nowait = true })

  vim.keymap.set("n", "<Esc>", function()
    close_float()
    callback(false)
  end, { buffer = buf, nowait = true })
end

function M.show_diff_preview(changes, callback)
  if not changes or #changes == 0 then
    callback(true)
    return
  end

  close_float()

  local lines = { "" }
  for i, change in ipairs(changes) do
    table.insert(lines, string.format("  Change %d: %s", i, change.path or "buffer"))
    table.insert(lines, "")
    for _, line in ipairs(vim.split(change.content, "\n")) do
      table.insert(lines, "  + " .. line)
    end
    table.insert(lines, "")
  end
  table.insert(lines, "  [y] accept  [n/q] reject")

  local buf, win = create_float({
    title = "Review Changes",
    filetype = "diff",
  })

  state.buf = buf
  state.win = win

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false

  vim.keymap.set("n", "y", function()
    close_float()
    callback(true)
  end, { buffer = buf, nowait = true })

  vim.keymap.set("n", "n", function()
    close_float()
    callback(false)
  end, { buffer = buf, nowait = true })

  set_float_keymaps(buf, function() callback(false) end)
end

function M.create_code_buffer(content, filetype)
  close_float()

  local buf, win = create_float({
    title = "Generated Code",
    filetype = filetype or "lua",
  })

  state.buf = buf
  state.win = win

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(content, "\n"))
  vim.bo[buf].modifiable = false

  set_float_keymaps(buf)

  return buf
end

function M.open_prompt_input(opts)
  close_float()

  local buf, win = create_float({
    title = opts.title or "Prompt",
    width = math.floor(vim.o.columns * 0.6),
    height = 10,
  })

  state.input_buf = buf
  state.input_win = win

  vim.bo[buf].modifiable = true

  local placeholder = opts.placeholder or "Enter your prompt..."
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { placeholder })
  vim.cmd("startinsert")
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "" })

  vim.keymap.set({ "n", "i" }, "<CR>", function()
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local prompt = table.concat(lines, "\n")
    close_float()
    vim.cmd("stopinsert")
    if opts.callback and prompt ~= "" then
      opts.callback(prompt)
    end
  end, { buffer = buf, nowait = true })

  vim.keymap.set({ "n", "i" }, "<Esc>", function()
    close_float()
    vim.cmd("stopinsert")
  end, { buffer = buf, nowait = true })
end

function M.select_provider(providers, callback)
  close_float()

  local lines = { "" }
  for i, provider in ipairs(providers) do
    table.insert(lines, string.format("  [%d] %s", i, provider))
  end
  table.insert(lines, "")
  table.insert(lines, "  [q] cancel")

  local buf, win = create_float({
    title = "Select Provider",
    width = 40,
    height = #lines + 2,
  })

  state.buf = buf
  state.win = win

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false

  for i, provider in ipairs(providers) do
    vim.keymap.set("n", tostring(i), function()
      close_float()
      callback(provider)
    end, { buffer = buf, nowait = true })
  end

  set_float_keymaps(buf)
end

return M
