-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.g.loaded_node_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0

-- do not warn for incorrect plugins order
vim.g.lazyvim_check_order = false

-- OSC52 clipboard bridge for tmux/SSH sessions, shipped by omarchy;
-- pcall since the module only exists on omarchy hosts, not the mac
pcall(function()
  require("config.remote_clipboard").setup()
end)
vim.opt.clipboard = "unnamedplus"
vim.opt.relativenumber = true
vim.g.autoformat = true
