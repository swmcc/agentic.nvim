---@mod agentic.adapters.base Base adapter interface
---@brief [[
--- Defines the contract that all provider adapters must implement.
--- Adapters handle communication with external AI CLI tools.
---@brief ]]

---@class Adapter
---@field opts table Adapter configuration
---@field job table|nil Current running job
local Adapter = {}
Adapter.__index = Adapter

--- Create a new adapter instance
---@param opts table Adapter configuration
---@return Adapter
function Adapter:new(opts)
  local instance = setmetatable({}, self)
  instance.opts = opts or {}
  instance.job = nil
  return instance
end

--- Extend the base adapter (for inheritance)
---@return table
function Adapter:extend()
  local child = {}
  child.__index = child
  setmetatable(child, { __index = self })
  return child
end

--- Check if the adapter's CLI tool is available
---@return boolean
function Adapter:is_available()
  local cmd = self.opts.cmd or "echo"
  local result = vim.fn.executable(cmd)
  return result == 1
end

--- Send a prompt to the provider
---@param prompt string The prompt to send
---@param context table Context information (buffer, selection, etc.)
---@param callback fun(result: table) Callback with result
function Adapter:ask(prompt, context, callback)
  error("Adapter:ask() must be implemented by subclass")
end

--- Apply an edit based on instructions
---@param instructions string Edit instructions
---@param callback fun(result: table) Callback with result
function Adapter:apply_edit(instructions, callback)
  error("Adapter:apply_edit() must be implemented by subclass")
end

--- Run a workflow
---@param workflow_name string Name of the workflow
---@param state table Current workflow state
---@param callback fun(result: table) Callback with result
function Adapter:run_workflow(workflow_name, state, callback)
  -- Default implementation: just run as a regular ask
  local prompt = string.format(
    "Execute workflow '%s' with the following state:\n%s",
    workflow_name,
    vim.inspect(state)
  )
  self:ask(prompt, state.context or {}, callback)
end

--- Cancel any running operation
function Adapter:cancel()
  if self.job then
    vim.fn.jobstop(self.job)
    self.job = nil
  end
end

--- Build the command arguments for the CLI
---@param prompt string The prompt
---@param context table The context
---@return string[] args
function Adapter:build_args(prompt, context)
  error("Adapter:build_args() must be implemented by subclass")
end

--- Parse the output from the CLI
---@param output string Raw output from CLI
---@return table result Parsed result
function Adapter:parse_output(output)
  return {
    content = output,
    changes = nil,
    error = nil,
  }
end

--- Format context for inclusion in prompt
---@param context table The context
---@return string formatted
function Adapter:format_context(context)
  local parts = {}

  if context.filename and context.filename ~= "" then
    table.insert(parts, string.format("File: %s", context.filename))
  end

  if context.filetype and context.filetype ~= "" then
    table.insert(parts, string.format("Filetype: %s", context.filetype))
  end

  if context.selection and context.selection.text then
    table.insert(parts, string.format(
      "Selected code (lines %d-%d):\n```\n%s\n```",
      context.selection.start_line,
      context.selection.end_line,
      context.selection.text
    ))
  elseif context.content then
    table.insert(parts, string.format("File content:\n```\n%s\n```", context.content))
  end

  if #parts > 0 then
    return "Context:\n" .. table.concat(parts, "\n") .. "\n\n"
  end

  return ""
end

return Adapter
