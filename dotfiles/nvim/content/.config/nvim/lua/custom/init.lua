vim.o.number = true                              -- Print line number
vim.o.relativenumber = true                      -- Relative line numbers
vim.o.exrc = true
vim.b.smartindent = true                         -- Insert indents automatically
vim.b.tabstop = 'indent'                         -- Number of spaces tabs count for
vim.b.softtabstop = 0                            -- Number of spaces tabs count for
vim.b.fileencoding = 'utf-8'
vim.o.updatetime = 1000
vim.o.inccommand = 'split'                       -- Show search results in a split
vim.o.hidden = true                              -- Enable modified buffers in background
vim.o.incsearch = true                           -- Enable modified buffers in background
vim.o.hlsearch = true                            -- Enable modified buffers in background
vim.o.ignorecase = true                          -- Ignore case
vim.o.joinspaces = false                         -- No double spaces with join after a dot
vim.o.scrolloff = 4                              -- Lines of context
vim.o.shiftround = true                          -- Round indent
vim.o.sidescrolloff = 8                          -- Columns of context
vim.o.smartcase = true                           -- Don't ignore case with capitals
vim.o.splitbelow = true                          -- Put new windows below current
vim.o.splitright = true                          -- Put new windows right of current
vim.o.termguicolors = true                       -- True color support
vim.o.wildmode = 'list:longest'                  -- Command-line completion mode
vim.o.list = true                                -- Show some invisible characters (tabs...)
vim.o.wrap = false                               -- Disable line wrap
vim.o.foldmethod = 'indent'                               -- Disable line wrap

vim.o.guifont = 'FiraCode Nerd Font:12'

-- Autoreload files {{{
vim.o.autoread = true
-- vim.cmd 'au BufEnter,FocusGained,InsertEnter * :checkt'
vim.api.nvim_create_autocmd({"BufEnter","FocusGained","InsertEnter"}, {
  pattern = "*",
  command = "checkt"
})
-- }}}


-- Auto-resize splits when vim resizes
vim.api.nvim_create_autocmd("VimResized", {
  pattern = "*",
  command = "wincmd ="
})

vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "*",
  command = "normal zR"
})

-- Autochange currdir
-- vim.cmd 'au BufEnter * lcd %:p:h'
-- vim.api.nvim_create_autocmd({ "BufEnter" }, {
--   pattern = "*",
--   command = "lcd %:p:h"
-- })
