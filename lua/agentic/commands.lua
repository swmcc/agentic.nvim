---@mod agentic.commands User command registration
---@brief [[
--- Registers all user-facing commands for the plugin.
---@brief ]]

local M = {}

local api = require("agentic.api")
local config = require("agentic.config")
local ui = require("agentic.ui")

--- Register all user commands
function M.register()
  -- :PamojaAsk [prompt]
  vim.api.nvim_create_user_command("PamojaAsk", function(opts)
    local prompt = opts.args

    if prompt == "" then
      -- Open prompt input
      ui.open_prompt_input({
        title = "Ask Agent",
        placeholder = "What would you like to ask?",
        callback = function(p)
          if p and p ~= "" then
            api.ask({ prompt = p, context = { include_file = true } })
          end
        end,
      })
    else
      api.ask({ prompt = prompt, context = { include_file = true } })
    end
  end, {
    nargs = "*",
    desc = "Ask the AI agent a question",
  })

  -- :PamojaSummarise (visual mode)
  vim.api.nvim_create_user_command("PamojaSummarise", function(opts)
    api.summarize({
      use_selection = opts.range > 0,
    })
  end, {
    range = true,
    desc = "Summarise selected text",
  })

  -- :PamojaRefactor [instruction]
  vim.api.nvim_create_user_command("PamojaRefactor", function(opts)
    local instruction = opts.args

    if instruction == "" then
      ui.open_prompt_input({
        title = "Refactor",
        placeholder = "Describe the refactoring to apply...",
        callback = function(p)
          if p and p ~= "" then
            api.refactor({
              prompt = p,
              use_selection = opts.range > 0,
            })
          end
        end,
      })
    else
      api.refactor({
        prompt = instruction,
        use_selection = opts.range > 0,
      })
    end
  end, {
    nargs = "*",
    range = true,
    desc = "Refactor code with instruction",
  })

  -- :PamojaGenerate [description]
  vim.api.nvim_create_user_command("PamojaGenerate", function(opts)
    local description = opts.args

    if description == "" then
      ui.open_prompt_input({
        title = "Generate Code",
        placeholder = "Describe the code to generate...",
        callback = function(p)
          if p and p ~= "" then
            api.generate({ prompt = p })
          end
        end,
      })
    else
      api.generate({ prompt = description })
    end
  end, {
    nargs = "*",
    desc = "Generate new code",
  })

  -- :PamojaTask [description]
  vim.api.nvim_create_user_command("PamojaTask", function(opts)
    local description = opts.args

    if description == "" then
      ui.open_prompt_input({
        title = "Task",
        placeholder = "Describe the multi-step task...",
        callback = function(p)
          if p and p ~= "" then
            api.run_workflow("multi_file", {
              prompt = p,
              require_confirmation = true,
            })
          end
        end,
      })
    else
      api.run_workflow("multi_file", {
        prompt = description,
        require_confirmation = true,
      })
    end
  end, {
    nargs = "*",
    desc = "Run a multi-step task",
  })

  -- :PamojaUse {provider}
  vim.api.nvim_create_user_command("PamojaUse", function(opts)
    local provider = opts.args

    if provider == "" then
      local providers = config.get_available_providers()
      ui.select_provider(providers, function(choice)
        if choice then
          api.switch_provider(choice)
          ui.show_status("Switched to " .. choice)
        end
      end)
    else
      api.switch_provider(provider)
      ui.show_status("Switched to " .. provider)
    end
  end, {
    nargs = "?",
    complete = function()
      return config.get_available_providers()
    end,
    desc = "Switch AI provider",
  })

  -- :PamojaStatus
  vim.api.nvim_create_user_command("PamojaStatus", function()
    local provider = api.get_current_provider()
    local ready = api.is_ready()
    local status = ready and "ready" or "not available"
    ui.show_status(string.format("Provider: %s (%s)", provider, status))
  end, {
    desc = "Show current provider status",
  })

  -- :PamojaCancel
  vim.api.nvim_create_user_command("PamojaCancel", function()
    api.cancel()
  end, {
    desc = "Cancel running operation",
  })
end

return M
