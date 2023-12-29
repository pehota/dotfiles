-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local unmap = vim.keymap.del

local map = function(modes, keymap, cmd, opts)
  if opts == nil then
    opts = {}
  end

  if opts.unique == nil then
    opts.unique = true
  end

  if opts.overwriteExisting == true then
    unmap(modes, keymap)
    opts.overwriteExisting = nil
  end

  vim.keymap.set(modes, keymap, cmd, opts)
end

map("n", "<C-p>", "<cmd>Telescope find_files<cr>", { silent = true, desc = "Find Files" })
map("n", "<Space>bd", "<cmd>bufdo bd!<cr>", { silent = false, desc = "Delete all buffers", overwriteExisting = true })

unmap("i", "<Tab>")
