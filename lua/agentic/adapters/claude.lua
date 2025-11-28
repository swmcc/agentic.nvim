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
  local output_lines = {}
  local error_lines = {}

  self.job = vim.fn.jobstart(
    vim.list_extend({ self.opts.cmd }, args),
    {
      on_stdout = function(_, data)
        if data then
          for _, line in ipairs(data) do
            if line ~= "" then
              table.insert(output_lines, line)
            end
          end
        end
      end,
      on_stderr = function(_, data)
        if data then
          for _, line in ipairs(data) do
            if line ~= "" then
              table.insert(error_lines, line)
            end
          end
        end
      end,
      on_exit = function(_, exit_code)
        self.job = nil

        if exit_code ~= 0 then
          callback({
            error = table.concat(error_lines, "\n"),
            exit_code = exit_code,
          })
          return
        end

        local output = table.concat(output_lines, "\n")
        local result = self:parse_output(output)
        callback(result)
      end,
      stdout_buffered = false,
      stderr_buffered = false,
    }
  )

  -- Set up timeout
  if self.opts.timeout > 0 then
    vim.defer_fn(function()
      if self.job then
        vim.fn.jobstop(self.job)
        self.job = nil
        callback({ error = "Request timed out" })
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

return Claude
