---@mod agentic.adapters.claude Claude Code adapter
---@brief [[
--- Adapter implementation for Claude Code CLI.
--- Handles spawning claude process and parsing stream-json responses.
---@brief ]]

local Base = require("agentic.adapters.base")

---@class ClaudeAdapter : Adapter
local Claude = Base:extend()

function Claude:new(opts)
  local instance = Base.new(self, opts)
  instance.opts.cmd = opts.cmd or "claude"
  instance.opts.args = opts.args or {}
  instance.opts.timeout = opts.timeout or 300000
  return instance
end

function Claude:is_available()
  return vim.fn.executable(self.opts.cmd) == 1
end

function Claude:parse_error(error_msg, exit_code)
  local lower = error_msg:lower()

  if lower:match("not logged in") or lower:match("authentication") or lower:match("unauthorized") or lower:match("api key") then
    return "Authentication required. Run 'claude login' to authenticate."
  end

  if lower:match("rate limit") then
    return "Rate limited. Please wait before trying again."
  end

  if lower:match("network") or lower:match("connection") then
    return "Network error. Check your internet connection."
  end

  if error_msg == "" then
    return string.format("Command failed with exit code %d", exit_code)
  end

  return error_msg
end

function Claude:build_args(prompt, context)
  local args = vim.list_extend({}, self.opts.args)

  table.insert(args, "-p")
  table.insert(args, "--output-format")
  table.insert(args, "stream-json")
  table.insert(args, "--verbose")

  local full_prompt = self:format_context(context) .. prompt
  table.insert(args, full_prompt)

  return args
end

function Claude:format_event(event)
  if event.type == "system" and event.subtype == "init" then
    return string.format("# Session started\nModel: %s\n", event.model or "unknown")
  end

  if event.type == "assistant" and event.message then
    local content = event.message.content
    if not content then return nil end

    local parts = {}
    for _, block in ipairs(content) do
      if block.type == "text" then
        table.insert(parts, block.text)
      elseif block.type == "tool_use" then
        local input_str = ""
        if block.input then
          if block.input.command then
            input_str = block.input.command
          elseif block.input.pattern then
            input_str = block.input.pattern
          elseif block.input.file_path then
            input_str = block.input.file_path
          else
            input_str = vim.fn.json_encode(block.input)
            if #input_str > 100 then
              input_str = input_str:sub(1, 100) .. "..."
            end
          end
        end
        table.insert(parts, string.format("\n**[%s]** `%s`\n", block.name, input_str))
      end
    end

    if #parts > 0 then
      return table.concat(parts, "")
    end
  end

  if event.type == "user" and event.tool_use_result then
    local result = event.tool_use_result
    if result:match("^Error:") then
      return string.format("\n> %s\n", result)
    end
    if #result > 500 then
      result = result:sub(1, 500) .. "\n... (truncated)"
    end
    return string.format("\n```\n%s\n```\n", result)
  end

  if event.type == "result" then
    return string.format("\n---\n*Completed in %.1fs | Cost: $%.4f*\n",
      (event.duration_ms or 0) / 1000,
      event.total_cost_usd or 0)
  end

  return nil
end

function Claude:ask(prompt, context, callback, on_event)
  if not self:is_available() then
    callback({ error = "Claude Code CLI not found. Install with: npm install -g @anthropic-ai/claude-code" })
    return
  end

  local args = self:build_args(prompt, context)
  local stdout = vim.loop.new_pipe(false)
  local stderr = vim.loop.new_pipe(false)
  local buffer = ""
  local error_chunks = {}
  local final_result = nil
  local callback_called = false

  local function safe_callback(result)
    if callback_called then return end
    callback_called = true
    vim.schedule(function()
      callback(result)
    end)
  end

  local function process_line(line)
    if line == "" then return end

    local ok, event = pcall(vim.json.decode, line)
    if not ok then
      return
    end

    if event.type == "result" then
      final_result = event.result
    end

    if on_event then
      local formatted = self:format_event(event)
      if formatted then
        vim.schedule(function()
          on_event(formatted)
        end)
      end
    end
  end

  local handle, spawn_err
  handle, spawn_err = vim.loop.spawn(self.opts.cmd, {
    args = args,
    stdio = { nil, stdout, stderr },
  }, function(code)
    stdout:close()
    stderr:close()
    handle:close()
    self.handle = nil

    if buffer ~= "" then
      process_line(buffer)
    end

    local errors = table.concat(error_chunks, "")

    if code ~= 0 then
      safe_callback({
        error = self:parse_error(errors, code),
        exit_code = code,
      })
      return
    end

    safe_callback({
      content = final_result or "",
      error = nil,
    })
  end)

  if not handle then
    stdout:close()
    stderr:close()
    safe_callback({
      error = string.format("Failed to spawn claude: %s", spawn_err or "unknown error"),
    })
    return
  end

  self.handle = handle

  stdout:read_start(function(err, data)
    if err then return end
    if data then
      buffer = buffer .. data
      while true do
        local newline_pos = buffer:find("\n")
        if not newline_pos then break end
        local line = buffer:sub(1, newline_pos - 1)
        buffer = buffer:sub(newline_pos + 1)
        process_line(line)
      end
    end
  end)

  stderr:read_start(function(err, data)
    if err then return end
    if data then
      table.insert(error_chunks, data)
    end
  end)

  if self.opts.timeout > 0 then
    self.timeout_timer = vim.defer_fn(function()
      if self.handle then
        self.handle:kill("sigterm")
        self.handle = nil
        safe_callback({ error = "Request timed out", timed_out = true })
      end
    end, self.opts.timeout)
  end
end

function Claude:cancel()
  if self.timeout_timer then
    self.timeout_timer:stop()
    self.timeout_timer:close()
    self.timeout_timer = nil
  end
  if self.handle then
    self.handle:kill("sigterm")
    self.handle = nil
  end
end

return Claude
