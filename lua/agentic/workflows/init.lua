---@mod agentic.workflows Workflow engine
---@brief [[
--- Manages complex multi-step agentic workflows.
--- Provides workflow registration, execution, and state management.
---@brief ]]

local M = {}

local ui = require("agentic.ui")

---@type table<string, table> Registered workflows
local workflows = {}

---@type table|nil Currently running workflow state
local current_workflow = nil

--- Register a workflow
---@param name string Workflow name
---@param definition table Workflow definition
function M.register(name, definition)
  workflows[name] = definition
end

--- Get a registered workflow
---@param name string Workflow name
---@return table|nil
function M.get(name)
  return workflows[name]
end

--- Run a workflow
---@param name string Workflow name
---@param opts table Workflow options
---@param callback? fun(result: table) Completion callback
function M.run(name, opts, callback)
  local workflow = workflows[name]

  if not workflow then
    vim.notify(string.format("Agentic: Unknown workflow '%s'", name), vim.log.levels.ERROR)
    if callback then
      callback({ error = "Unknown workflow" })
    end
    return
  end

  -- Initialize workflow state
  current_workflow = {
    name = name,
    step_index = 1,
    state = {
      prompt = opts.prompt,
      context = opts.context,
      results = {},
    },
    adapter = opts.adapter,
    require_confirmation = opts.require_confirmation,
    callback = callback,
  }

  -- Start execution
  M._execute_step()
end

--- Execute the current workflow step
function M._execute_step()
  if not current_workflow then
    return
  end

  local workflow = workflows[current_workflow.name]
  local step_name = workflow.steps[current_workflow.step_index]

  if not step_name then
    -- Workflow complete
    M._complete_workflow()
    return
  end

  local handler = workflow.handlers[step_name]
  if not handler then
    vim.notify(
      string.format("Agentic: Missing handler for step '%s'", step_name),
      vim.log.levels.ERROR
    )
    M._fail_workflow("Missing step handler")
    return
  end

  -- Show progress
  ui.show_status(string.format(
    "Workflow '%s': Step %d/%d - %s",
    current_workflow.name,
    current_workflow.step_index,
    #workflow.steps,
    step_name
  ))

  -- Execute step handler
  handler(current_workflow.state, current_workflow.adapter, function(result)
    if result.error then
      M._fail_workflow(result.error)
      return
    end

    -- Store step result
    current_workflow.state.results[step_name] = result

    -- Check if confirmation needed before next step
    if current_workflow.require_confirmation and result.requires_confirmation then
      ui.confirm(
        string.format("Proceed with step '%s'?", step_name),
        function(confirmed)
          if confirmed then
            current_workflow.step_index = current_workflow.step_index + 1
            M._execute_step()
          else
            M._cancel_workflow()
          end
        end
      )
    else
      current_workflow.step_index = current_workflow.step_index + 1
      M._execute_step()
    end
  end)
end

--- Complete the workflow successfully
function M._complete_workflow()
  if not current_workflow then
    return
  end

  local result = {
    success = true,
    state = current_workflow.state,
  }

  ui.show_status(string.format("Workflow '%s' completed", current_workflow.name))

  if current_workflow.callback then
    current_workflow.callback(result)
  end

  current_workflow = nil
end

--- Fail the workflow with error
---@param error_msg string
function M._fail_workflow(error_msg)
  if not current_workflow then
    return
  end

  local result = {
    success = false,
    error = error_msg,
    state = current_workflow.state,
  }

  ui.show_error(string.format(
    "Workflow '%s' failed: %s",
    current_workflow.name,
    error_msg
  ))

  if current_workflow.callback then
    current_workflow.callback(result)
  end

  current_workflow = nil
end

--- Cancel the workflow
function M._cancel_workflow()
  if not current_workflow then
    return
  end

  local result = {
    success = false,
    cancelled = true,
    state = current_workflow.state,
  }

  ui.show_status(string.format("Workflow '%s' cancelled", current_workflow.name))

  if current_workflow.callback then
    current_workflow.callback(result)
  end

  current_workflow = nil
end

--- Cancel any running workflow
function M.cancel()
  if current_workflow and current_workflow.adapter then
    current_workflow.adapter:cancel()
  end
  M._cancel_workflow()
end

--- Check if a workflow is running
---@return boolean
function M.is_running()
  return current_workflow ~= nil
end

--- Get current workflow status
---@return table|nil
function M.get_status()
  if not current_workflow then
    return nil
  end

  local workflow = workflows[current_workflow.name]
  return {
    name = current_workflow.name,
    step = current_workflow.step_index,
    total_steps = #workflow.steps,
    current_step = workflow.steps[current_workflow.step_index],
  }
end

-- Register built-in workflows

M.register("ask", {
  steps = { "query" },
  handlers = {
    query = function(state, adapter, callback)
      adapter:ask(state.prompt, state.context, callback)
    end,
  },
})

M.register("summarize", {
  steps = { "summarize" },
  handlers = {
    summarize = function(state, adapter, callback)
      adapter:run_workflow("summarize", state, callback)
    end,
  },
})

M.register("refactor", {
  steps = { "analyze", "refactor" },
  handlers = {
    analyze = function(state, adapter, callback)
      adapter:ask(
        "Analyze the following code and identify what needs to be refactored:\n" .. state.prompt,
        state.context,
        function(result)
          result.requires_confirmation = true
          callback(result)
        end
      )
    end,
    refactor = function(state, adapter, callback)
      adapter:run_workflow("refactor", state, callback)
    end,
  },
})

M.register("generate", {
  steps = { "generate" },
  handlers = {
    generate = function(state, adapter, callback)
      adapter:run_workflow("generate", state, callback)
    end,
  },
})

M.register("multi_file", {
  steps = { "plan", "confirm", "execute" },
  handlers = {
    plan = function(state, adapter, callback)
      adapter:ask(
        "Create a plan listing all files that need to be modified for the following task:\n" .. state.prompt,
        state.context,
        function(result)
          result.requires_confirmation = true
          callback(result)
        end
      )
    end,
    confirm = function(state, adapter, callback)
      -- Plan was confirmed, proceed to execution
      callback({ success = true })
    end,
    execute = function(state, adapter, callback)
      -- Execute the planned changes
      adapter:ask(
        "Execute the planned changes. Show the exact modifications for each file.",
        state.context,
        callback
      )
    end,
  },
})

return M
