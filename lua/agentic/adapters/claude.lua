---@mod agentic.adapters.claude Claude Code adapter
---@brief [[
--- Adapter implementation for Claude Code CLI.
--- Handles spawning claude process and parsing responses.
---@brief ]]

local Base = require("agentic.adapters.base")

---@class ClaudeAdapter : Adapter
local Claude = Base:extend()

--- Create a new Claude adapter instance
---@param opts table Adapter configuration
---@return ClaudeAdapter
function Claude:new(opts)
  local instance = Base.new(self, opts)
  instance.opts.cmd = opts.cmd or "claude"
  instance.opts.args = opts.args or {}
  instance.opts.timeout = opts.timeout or 120000
  return instance
end

--- Check if Claude CLI is available
---@return boolean
function Claude:is_available()
  return vim.fn.executable(self.opts.cmd) == 1
end

--- Parse error messages for known error types
---@param error_msg string Raw error message
---@param exit_code number Exit code from process
---@return string Formatted error message
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

--- Build command arguments for Claude CLI
---@param prompt string The prompt
---@param context table The context
---@return string[] args
function Claude:build_args(prompt, context)
  local args = vim.list_extend({}, self.opts.args)

  -- Add print flag to output directly
  table.insert(args, "--print")

  -- Build the full prompt with context
  local full_prompt = self:format_context(context) .. prompt

  -- Claude uses the prompt as the last argument
  table.insert(args, full_prompt)

  return args
end

--- Send a prompt to Claude
---@param prompt string The prompt to send
---@param context table Context information
---@param callback fun(result: table) Callback with result
function Claude:ask(prompt, context, callback)
  if not self:is_available() then
    callback({ error = "Claude CLI not found. Please install claude-code." })
    return
  end

  local args = self:build_args(prompt, context)
  local stdout = vim.loop.new_pipe(false)
  local stderr = vim.loop.new_pipe(false)
  local output_chunks = {}
  local error_chunks = {}
  local callback_called = false

  local function safe_callback(result)
    if callback_called then return end
    callback_called = true
    vim.schedule(function()
      callback(result)
    end)
  end

  local handle
  handle, _ = vim.loop.spawn(self.opts.cmd, {
    args = args,
    stdio = { nil, stdout, stderr },
  }, function(code)
    stdout:close()
    stderr:close()
    handle:close()
    self.handle = nil

    local output = table.concat(output_chunks, "")
    local errors = table.concat(error_chunks, "")

    if code ~= 0 then
      safe_callback({
        error = self:parse_error(errors ~= "" and errors or output, code),
        exit_code = code,
      })
      return
    end

    local result = self:parse_output(output)
    safe_callback(result)
  end)

  self.handle = handle

  stdout:read_start(function(err, data)
    if err then return end
    if data then
      table.insert(output_chunks, data)
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

--- Parse Claude output for structured changes
---@param output string Raw output from CLI
---@return table result
function Claude:parse_output(output)
  local result = {
    content = output,
    changes = nil,
    error = nil,
  }

  -- Try to parse code blocks for changes
  local changes = {}
  local in_code_block = false
  local current_block = {}
  local current_lang = nil

  for line in output:gmatch("[^\r\n]+") do
    if line:match("^```") then
      if in_code_block then
        -- End of code block
        if #current_block > 0 then
          table.insert(changes, {
            type = "code",
            language = current_lang,
            content = table.concat(current_block, "\n"),
          })
        end
        current_block = {}
        current_lang = nil
        in_code_block = false
      else
        -- Start of code block
        current_lang = line:match("^```(%w+)")
        in_code_block = true
      end
    elseif in_code_block then
      table.insert(current_block, line)
    end
  end

  if #changes > 0 then
    result.code_blocks = changes
  end

  return result
end

--- Apply an edit based on instructions
---@param instructions string Edit instructions
---@param callback fun(result: table) Callback with result
function Claude:apply_edit(instructions, callback)
  local prompt = string.format([[
You are editing code. Apply the following instructions and return ONLY the modified code.
Do not include explanations, just the code.

Instructions: %s
]], instructions)

  self:ask(prompt, {}, callback)
end

--- Run a workflow with Claude
---@param workflow_name string Name of the workflow
---@param state table Current workflow state
---@param callback fun(result: table) Callback with result
function Claude:run_workflow(workflow_name, state, callback)
  local prompts = {
    summarize = "Summarize the following code concisely:",
    refactor = "Refactor the following code according to the instructions. Return the refactored code:",
    generate = "Generate code based on the following description:",
    plan = "Create a detailed step-by-step plan for the following task:",
  }

  local base_prompt = prompts[workflow_name] or "Process the following:"
  local full_prompt = base_prompt

  if state.prompt then
    full_prompt = full_prompt .. "\n\n" .. state.prompt
  end

  self:ask(full_prompt, state.context or {}, callback)
end

function Claude:cancel()
  self.timeout_timer = nil
  if self.handle then
    self.handle:kill("sigterm")
    self.handle = nil
  end
end

return Claude
