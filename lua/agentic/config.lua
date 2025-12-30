---@mod agentic.config Configuration management
---@brief [[
--- Manages plugin configuration with defaults and validation.
---@brief ]]

local M = {}

---@type table Default configuration
local defaults = {
  default_provider = "claude",

  providers = {
    claude = {
      cmd = "claude",
      args = {},
      timeout = 120000,
    },
    gemini = {
      cmd = "gemini",
      args = {},
      timeout = 120000,
    },
  },

  ui = {
    output = "split",
    split_direction = "below",
    split_size = 15,
    float_width = 0.8,
    float_height = 0.6,
    confirm_changes = true,
  },

  keymaps = nil,
}

---@type table Current configuration (merged with defaults)
local current = vim.deepcopy(defaults)

---@type string Currently active provider
local active_provider = defaults.default_provider

--- Setup configuration with user options
---@param opts table User configuration
function M.setup(opts)
  current = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})
  active_provider = current.default_provider

  -- Validate provider
  if not current.providers[active_provider] then
    vim.notify(
      string.format("Pamoja: Unknown provider '%s', falling back to claude", active_provider),
      vim.log.levels.WARN
    )
    active_provider = "claude"
  end
end

--- Get a configuration value by dot-separated path
---@param path string Configuration path (e.g., "ui.output")
---@return any
function M.get(path)
  local parts = vim.split(path, ".", { plain = true })
  local value = current

  for _, part in ipairs(parts) do
    if type(value) ~= "table" then
      return nil
    end
    value = value[part]
  end

  return value
end

--- Get the current provider name
---@return string
function M.get_provider()
  return active_provider
end

--- Set the current provider
---@param provider string Provider name
function M.set_provider(provider)
  if not current.providers[provider] then
    vim.notify(string.format("Pamoja: Unknown provider '%s'", provider), vim.log.levels.ERROR)
    return
  end
  active_provider = provider
end

--- Get provider-specific configuration
---@param provider? string Provider name (defaults to current)
---@return table
function M.get_provider_config(provider)
  provider = provider or active_provider
  return current.providers[provider] or {}
end

--- Get all available provider names
---@return string[]
function M.get_available_providers()
  local providers = {}
  for name, _ in pairs(current.providers) do
    table.insert(providers, name)
  end
  return providers
end

--- Get the full current configuration
---@return table
function M.get_all()
  return vim.deepcopy(current)
end

return M
