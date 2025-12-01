local plenary_path = vim.fn.stdpath("data") .. "/lazy/plenary.nvim"
if not vim.loop.fs_stat(plenary_path) then
  vim.fn.system({
    "git", "clone", "--depth", "1",
    "https://github.com/nvim-lua/plenary.nvim",
    plenary_path,
  })
end
vim.opt.rtp:prepend(plenary_path)

local plugin_path = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h")
vim.opt.rtp:prepend(plugin_path)

vim.cmd("runtime plugin/plenary.vim")
