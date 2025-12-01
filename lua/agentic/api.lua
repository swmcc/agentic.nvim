---@mod agentic.api Internal plugin API
---@brief [[
--- This module provides the internal API for agentic.nvim.
--- All plugin functionality routes through this module.
--- This API is private and not intended for direct user consumption.
---@brief ]]

local M = {}

local config = require("agentic.config")
local ui = require("agentic.ui")
local workflows = require("agentic.workflows")

---@type table|nil Current adapter instance
local adapter = nil

---@type table|nil Current running job
local current_job = nil

--- Initialize the API with the configured provider
function M.init()
  local provider = config.get_provider()
  M.switch_provider(provider)
end

--- Check if the API is ready
---@return boolean
function M.is_ready()
  return adapter ~= nil and adapter:is_available()
end

--- Switch to a different provider
---@param provider "claude"|"gemini"
function M.switch_provider(provider)
  if current_job then
    M.cancel()
  end

  config.set_provider(provider)

  local provider_config = config.get_provider_config(provider)
  local adapter_module = require("agentic.adapters." .. provider)
  adapter = adapter_module:new(provider_config)
end

--- Get the current provider name
---@return string
function M.get_current_provider()
  return config.get_provider()
end

--- Build context from current buffer state
---@param opts? table Context options
---@return table context
function M.get_context(opts)
  opts = opts or {}
  local ctx = {
    cwd = vim.fn.getcwd(),
    buffer = vim.api.nvim_get_current_buf(),
    filename = vim.fn.expand("%:p"),
    filetype = vim.bo.filetype,
    cursor = vim.api.nvim_win_get_cursor(0),
  }

  -- Include buffer content if requested
  if opts.include_file then
    ctx.content = table.concat(vim.api.nvim_buf_get_lines(ctx.buffer, 0, -1, false), "\n")
  end

  -- Include visual selection if in visual mode or requested
  if opts.selection then
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")
    local start_line = start_pos[2]
    local end_line = end_pos[2]

    if start_line > 0 and end_line > 0 then
      local lines = vim.api.nvim_buf_get_lines(ctx.buffer, start_line - 1, end_line, false)

      -- Handle partial line selection
      if #lines > 0 then
        local start_col = start_pos[3]
        local end_col = end_pos[3]

        if #lines == 1 then
          lines[1] = string.sub(lines[1], start_col, end_col)
        else
          lines[1] = string.sub(lines[1], start_col)
          lines[#lines] = string.sub(lines[#lines], 1, end_col)
        end
      end

      ctx.selection = {
        text = table.concat(lines, "\n"),
        start_line = start_line,
        end_line = end_line,
        start_col = start_pos[3],
        end_col = end_pos[3],
      }
    end
  end

  return ctx
end

---@class AskOpts
---@field prompt string The prompt to send
---@field context? table Additional context
---@field workflow? string Workflow to use
---@field output? "split"|"float"|"new_buffer" Output destination
---@field apply_changes? boolean Whether to apply changes automatically

--- Send a prompt to the current provider
---@param opts AskOpts
---@param callback? fun(result: table) Optional callback for result
function M.ask(opts, callback)
  if not adapter then
    vim.notify("Agentic: No provider configured", vim.log.levels.ERROR)
    return
  end

  -- Build context
  local ctx = M.get_context(opts.context or {})

  -- Create output buffer
  local output_buf = ui.create_output_buffer({
    title = "Agentic Response",
    output = opts.output or config.get("ui.output"),
  })

  -- Track the job
  current_job = {
    type = "ask",
    buffer = output_buf,
  }

  -- Send request to adapter
  adapter:ask(opts.prompt, ctx, function(result)
    current_job = nil

    if result.error then
      ui.show_error(result.error)
      return
    end

    ui.show_response(result.content)

    if opts.apply_changes and result.changes then
      M.apply_changes(result)
    end

    if callback then
      callback(result)
    end
  end)
end

---@class PlanOpts
---@field prompt string The task to plan
---@field context? table Additional context

--- Request a structured plan from the provider
---@param opts PlanOpts
---@param callback fun(plan: table)
function M.plan(opts, callback)
  if not adapter then
    vim.notify("Agentic: No provider configured", vim.log.levels.ERROR)
    return
  end

  local ctx = M.get_context(opts.context or {})
  local plan_prompt = string.format(
    "Create a step-by-step plan for the following task. " ..
    "Return the plan as a structured list of steps.\n\nTask: %s",
    opts.prompt
  )

  adapter:ask(plan_prompt, ctx, function(result)
    if result.error then
      ui.show_error(result.error)
      return
    end

    callback({
      content = result.content,
      steps = result.steps or {},
    })
  end)
end

---@class ApplyChangesResult
---@field changes table List of changes to apply
---@field content? string Raw content

--- Apply file changes from a provider response
---@param result ApplyChangesResult
function M.apply_changes(result)
  if not result.changes or #result.changes == 0 then
    vim.notify("Agentic: No changes to apply", vim.log.levels.INFO)
    return
  end

  -- Show diff preview if confirmation is enabled
  if config.get("ui.confirm_changes") then
    ui.show_diff_preview(result.changes, function(confirmed)
      if confirmed then
        M._do_apply_changes(result.changes)
      else
        vim.notify("Agentic: Changes cancelled", vim.log.levels.INFO)
      end
    end)
  else
    M._do_apply_changes(result.changes)
  end
end

--- Actually apply the changes (internal)
---@param changes table
function M._do_apply_changes(changes)
  for _, change in ipairs(changes) do
    if change.type == "replace" then
      -- Replace lines in buffer
      local buf = vim.fn.bufnr(change.path)
      if buf == -1 then
        buf = vim.fn.bufadd(change.path)
      end

      vim.api.nvim_buf_set_lines(
        buf,
        change.start_line - 1,
        change.end_line,
        false,
        vim.split(change.content, "\n")
      )
    elseif change.type == "insert" then
      -- Insert lines at position
      local buf = vim.fn.bufnr(change.path)
      if buf == -1 then
        buf = vim.fn.bufadd(change.path)
      end

      vim.api.nvim_buf_set_lines(
        buf,
        change.line - 1,
        change.line - 1,
        false,
        vim.split(change.content, "\n")
      )
    elseif change.type == "create" then
      -- Create new file
      local buf = vim.api.nvim_create_buf(true, false)
      vim.api.nvim_buf_set_name(buf, change.path)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(change.content, "\n"))
    end
  end

  vim.notify(string.format("Agentic: Applied %d change(s)", #changes), vim.log.levels.INFO)
end

---@class WorkflowOpts
---@field prompt? string Initial prompt
---@field context? table Additional context
---@field require_confirmation? boolean Require confirmation at each step

--- Run a named workflow
---@param name string Workflow name
---@param opts WorkflowOpts
---@param callback? fun(result: table)
function M.run_workflow(name, opts, callback)
  if not adapter then
    vim.notify("Agentic: No provider configured", vim.log.levels.ERROR)
    return
  end

  local ctx = M.get_context(opts.context or {})

  workflows.run(name, {
    adapter = adapter,
    prompt = opts.prompt,
    context = ctx,
    require_confirmation = opts.require_confirmation,
  }, callback)
end

--- Cancel the current running operation
function M.cancel()
  if current_job then
    if adapter and adapter.cancel then
      adapter:cancel()
    end
    current_job = nil
    vim.notify("Agentic: Operation cancelled", vim.log.levels.INFO)
  end
end

--- Generate code into a new buffer
---@param opts table
function M.generate(opts)
  M.ask({
    prompt = opts.prompt,
    context = opts.context,
    workflow = "generate",
    output = "new_buffer",
  })
end

--- Summarize selected text
---@param opts table
function M.summarize(opts)
  local ctx = M.get_context({ selection = true })

  if not ctx.selection then
    vim.notify("Agentic: No selection", vim.log.levels.WARN)
    return
  end

  M.ask({
    prompt = "Summarize the following code or text concisely:\n\n" .. ctx.selection.text,
    context = {},
    output = "float",
  })
end

--- Refactor code with instruction
---@param opts table
function M.refactor(opts)
  local ctx_opts = { include_file = true }
  if opts.use_selection then
    ctx_opts.selection = true
  end

  M.ask({
    prompt = opts.prompt,
    context = ctx_opts,
    workflow = "refactor",
    apply_changes = true,
  })
end

return M
