---@mod agentic Dual-agent agentic workflow plugin for Neovim
---@brief [[
--- agentic.nvim provides agentic AI workflows using Claude Code and Gemini CLI.
--- Switch between providers seamlessly while using consistent commands.
---@brief ]]

local M = {}

local config = require("agentic.config")
local commands = require("agentic.commands")
local api = require("agentic.api")

---@class AgenticSetupOpts
---@field default_provider? "claude"|"gemini" Default AI provider
---@field providers? table Provider-specific configuration
---@field ui? table UI preferences
---@field keymaps? table Optional keymaps

--- Initialize the plugin with user configuration
---@param opts? AgenticSetupOpts
function M.setup(opts)
  opts = opts or {}

  -- Merge user config with defaults
  config.setup(opts)

  -- Initialize the API with the configured provider
  api.init()

  -- Register commands
  commands.register()

  -- Setup keymaps if provided
  if opts.keymaps then
    M.setup_keymaps(opts.keymaps)
  end
end

--- Setup optional keymaps
---@param keymaps table
function M.setup_keymaps(keymaps)
  local map = vim.keymap.set

  if keymaps.ask then
    map("n", keymaps.ask, "<cmd>AgenticAsk<cr>", { desc = "Agentic: Ask" })
  end

  if keymaps.summarize then
    map("v", keymaps.summarize, "<cmd>AgenticSummarize<cr>", { desc = "Agentic: Summarize" })
  end

  if keymaps.refactor then
    map({ "n", "v" }, keymaps.refactor, "<cmd>AgenticRefactor<cr>", { desc = "Agentic: Refactor" })
  end

  if keymaps.generate then
    map("n", keymaps.generate, "<cmd>AgenticGenerate<cr>", { desc = "Agentic: Generate" })
  end

  if keymaps.task then
    map("n", keymaps.task, "<cmd>AgenticTask<cr>", { desc = "Agentic: Task" })
  end
end

--- Get the current provider name
---@return string
function M.get_provider()
  return config.get_provider()
end

--- Switch to a different provider
---@param provider "claude"|"gemini"
function M.use(provider)
  api.switch_provider(provider)
end

--- Check if the plugin is ready
---@return boolean
function M.is_ready()
  return api.is_ready()
end

--- Get plugin version
---@return string
function M.version()
  return "0.1.0"
end

return M
