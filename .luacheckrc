-- Luacheck configuration for Neovim plugin

-- Neovim globals
globals = {
  "vim",
}

-- Test framework globals (plenary.nvim)
files["tests/**/*.lua"] = {
  globals = {
    "describe",
    "it",
    "before_each",
    "after_each",
    "assert",
  },
}

-- Ignore unused loop variable '_'
ignore = {
  "211/_.*",  -- unused variable starting with _
  "212/_.*",  -- unused argument starting with _
}
