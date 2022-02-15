local cmd = vim.cmd  -- to execute Vim commands e.g. cmd('pwd')
local fn = vim.fn    -- to call Vim functions e.g. fn.bufnr()
local g = vim.g      -- a table to access global variables

-- workaround for easily setting vim options
local scopes = {o = vim.o, b = vim.bo, w = vim.wo}

local function opt(scope, key, value)
  scopes[scope][key] = value
  if scope ~= 'o' then scopes['o'][key] = value end
end

local function get_opt(scope, key)
  if scopes[scope] ~= nil then
    return scopes[scope][key]
  end
  return nil
end

local function map(mode, lhs, rhs, opts)
  local options = {noremap = true, silent = true}
  if opts then options = vim.tbl_extend('force', options, opts) end
  vim.api.nvim_set_keymap(mode, lhs, rhs, options)
end

-- Session Management
-- Check if running in headless mode
local is_headless_mode = vim.api.nvim_list_uis and vim.api.nvim_list_uis().length == 0

-- automatically load and save session on start/exit.
local session_file = ""
local session_dir = ""

function makeSession()
  if is_headless_mode then
    return
  end
  if session_file ~= "" and vim.api.nvim_call_function("filewritable", {session_file}) then
    print("Saving session.")
    if (not vim.api.nvim_call_function('filewritable', {session_dir})) then
      cmd ('silent !mkdir -p ' .. session_dir)
      cmd 'redraw!'
    end
    cmd ("mksession! " .. session_file) 
  end
end

function loadSession()
  if vim.api.nvim_call_function('argc', {}) == 0 then
    session_dir = "~/.vim/sessions" .. vim.api.nvim_call_function('getcwd', {})
    session_file = session_dir .. "/session.vim"
    if vim.api.nvim_call_function('filereadable', {session_file}) then
      cmd ('source ' .. session_file)
    else
      print("No session loaded.") 
    end
  else
    session_dir = ""
    session_file = ""
  end
end


cmd ([[
au VimEnter * nested :lua loadSession()
au VimLeave * :lua makeSession()
]])

g['mapleader'] = '\\<space>'
g['deoplete#enable_at_startup'] = 1  -- enable deoplete at startup

local Plug = vim.fn['plug#']

vim.call('plug#begin', '~/.config/nvim/plugged')

-- packages (TODO: import relevant plugins and settings from .vimrc)

Plug 'hrsh7th/nvim-compe'

Plug 'google/vim-searchindex'

Plug 'jiangmiao/auto-pairs'
Plug('tpope/vim-commentary', { on = 'Commentary' })
Plug 'tpope/vim-surround'
Plug('tpope/vim-fugitive', { on = 'Git' })

-- Vim Signify {{{
Plug 'mhinz/vim-signify'
  g['signify_vcs_list'] = { 'git' }
  g['signify_sign_add']               = '+'
  g['signify_sign_delete']            = '-'
  g['signify_sign_delete_first_line'] = g['signify_sign_delete']
  g['signify_sign_change']            = '~'
  g['signify_sign_changedelete']      = g['signify_sign_change']
-- }}}

-- Plug 'sheerun/vim-polyglot'
Plug('pantharshit00/vim-prisma', { ['for'] = 'prisma' })
Plug('rescript-lang/rescript-vscode', { ['for'] = 'rescript' })
-- Plug 'nathanaelkane/vim-indent-guides'

-- Lightline {{{
Plug('glepnir/galaxyline.nvim', { run = function() 
  require('galaxyline').section.left[1]= {
    FileSize = {
      provider = 'FileSize',
      condition = function()
        if vim.fn.empty(vim.fn.expand('%:t')) ~= 1 then
          return true
        end
        return false
      end,
      icon = '   ',
      highlight = {colors.green,colors.purple},
      separator = '',
      separator_highlight = {colors.purple,colors.darkblue},
    }
  }
end })

-- tree-sitter {{{
Plug('nvim-treesitter/nvim-treesitter', { ['do'] = 'TSUpdate' })

-- }}}

-- Plug 'simrat39/rust-tools.nvim'
-- require("rust-tools").setup {}

-- LSP {{{
Plug 'ojroques/nvim-lspfuzzy'
Plug 'neovim/nvim-lspconfig'


-- Plug 'nvim-lua/plenary.nvim'
-- Plug 'nvim-telescope/telescope.nvim'

-- Fzf {{{
Plug 'junegunn/fzf.vim'
Plug('junegunn/fzf', { run = fn['fzf#install'] })

-- g.fzf_command_prefix = 'Fzf'
-- disable statusline overriding
g.fzf_nvim_statusline = 0

g['$FZF_DEFAULT_COMMAND'] = 'rg --files --hidden --follow --no-line-number --ignore-file ~/.gitignore'

-- }}}

Plug 'scrooloose/nerdtree'
Plug 'dkasak/gruvbox'

-- Adjust 'shiftwidth' and 'expandtab' heuristically
Plug 'tpope/vim-sleuth'
Plug('numtostr/BufOnly.nvim', { on = 'BufOnly' })
Plug 'tpope/vim-commentary'


vim.call('plug#end')

-- compe setup
require'compe'.setup {
  enabled = true;
  autocomplete = true;
  debug = false;
  min_length = 1;
  preselect = 'enable';
  throttle_time = 80;
  source_timeout = 200;
  resolve_timeout = 800;
  incomplete_delay = 400;
  max_abbr_width = 100;
  max_kind_width = 100;
  max_menu_width = 100;
  documentation = {
    border = { '', '' ,'', ' ', '', '', '', ' ' }, -- the border option is the same as `|help nvim_open_win|`
    winhighlight = "NormalFloat:CompeDocumentation,FloatBorder:CompeDocumentationBorder",
    max_width = 120,
    min_width = 60,
    max_height = math.floor(vim.o.lines * 0.3),
    min_height = 1,
  };

  source = {
    path = true;
    buffer = true;
    calc = true;
    nvim_lsp = true;
    nvim_lua = true;
    vsnip = true;
    ultisnips = true;
    luasnip = true;
  };
}

-- Treesitter setup
local ts = require 'nvim-treesitter.configs'
ts.setup {ensure_installed = 'maintained', highlight = {enable = true}}

-- LSP setup
local lsp = require 'lspconfig'
local lspfuzzy = require 'lspfuzzy'

local servers = { "elmls", "vimls", "tsserver", "prismals", "rescriptls" }
for _, server in ipairs(servers) do
  -- lsp[server].setup { on_attach = on_attach }
  lsp[server].setup {}
end

local sumneko_binary_path = vim.fn.exepath('lua-language-server')
local sumneko_root_path = vim.fn.fnamemodify(sumneko_binary_path, ':h:h:h')

local runtime_path = vim.split(package.path, ';')
table.insert(runtime_path, "lua/?.lua")
table.insert(runtime_path, "lua/?/init.lua")

require'lspconfig'.sumneko_lua.setup {
    cmd = {sumneko_binary_path, "-E", sumneko_root_path .. "/main.lua"};
    settings = {
        Lua = {
        runtime = {
            -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
            version = 'LuaJIT',
            -- Setup your lua path
            path = runtime_path,
        },
        diagnostics = {
            -- Get the language server to recognize the `vim` global
            globals = {'vim'},
        },
        workspace = {
            -- Make the server aware of Neovim runtime files
            library = vim.api.nvim_get_runtime_file("", true),
        },
        -- Do not send telemetry data containing a randomized but unique identifier
        telemetry = {
            enable = false,
        },
        },
    },
}

cmd 'au BufWritePre *.* lua vim.lsp.buf.formatting_sync(nil, 1000)'

local lspGutterSigns = { Error = " ", Warning = " ", Hint = " ", Information = " " }

for type, icon in pairs(lspGutterSigns) do
  local hl = "LspDiagnosticsSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
end


lspfuzzy.setup {}  -- Make the LSP client use FZF instead of the quickfix list

-- require('rust-tools').setup {}

-- Customize diagnostics appearance
vim.lsp.handlers["textDocument/publishDiagnostics"] =
  function(_, _, params, client_id, _)
    local bufnr = vim.uri_to_bufnr(uri)

    if not bufnr or not vim.api.nvim_buf_is_loaded(bufnr) then
      return
    end

    local config = { -- your config
      underline = true,
      virtual_text = false,
-- {
--         prefix = "",
--         spacing = 0,
--       }
      signs = true,
      update_in_insert = false,
    }
    local resolveDiagnosticsIcon = function(severity)
      if severity == 1 then
        return lspGutterSigns.Error
      end
      if severity == 2 then
        return lspGutterSigns.Warning

      end
      if severity == 3 then
        return lspGutterSigns.Hint
      end
      if severity == 4 then
        return lspGutterSigns.Information
      end
      return "?"
    end

    local uri = params.uri

    local diagnostics = params.diagnostics

    if config.virtual_text then
      for i, v in ipairs(diagnostics) do
        diagnostics[i].message = string.format("%s  %s: %s", resolveDiagnosticsIcon(v.severity), v.source, v.message)
      end
    end

    vim.lsp.diagnostic.save(diagnostics, bufnr, client_id)

    vim.lsp.diagnostic.display(diagnostics, bufnr, client_id, config)
  end

map('n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>')
map('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>')
map('n', 'gy', '<cmd>lua vim.lsp.buf.type_definition()<CR>')
map('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>')
map('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>')
map('n', '[w', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>')
map('n', ']w', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>')
-- nmap <silent> <space>rf <Plug>(coc-refactor)
map('n', '<space>?', '<cmd>lua vim.lsp.buf.hover()<CR>')
map('n', '<localleader>?', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics({focusable=false})<CR>')
-- map('n', '<localleader>?', '<cmd>Telescope lsp_document_diagnostics theme=get_ivy<CR>')
map('n', '<space>t', '<cmd>lua vim.lsp.buf.document_symbol()<CR>')
-- map('n', '<space>t', '<cmd>Telescope lsp_document_symbols<CR>')
map('n', '<localleader>a', '<cmd>lua vim.lsp.buf.code_action()<CR>')
-- map('n', '<localleader>a', '<cmd>Telescope lsp_code_actions theme=get_cursor<CR>')
map('n', '<localleader>f', '<cmd>lua vim.lsp.buf.formatting()<CR>')
-- }}}

-- require('telescope').setup {
--   defaults = {
--     use_less = false,
--     mappings = {
--       i = {
--         ["<esc>"] = require('telescope.actions').close
--       },
--     },
--   }

-- }

-- set options (TODO: port settings from .vimrc)
local indent = 2
-- colors
cmd 'colorscheme gruvbox'                             -- Put your favorite colorscheme here
cmd 'au VimResized * wincmd ='                        -- Auto-resize splits when vim resizes

opt('b', 'smartindent', true)                         -- Insert indents automatically
opt('b', 'tabstop', indent)                           -- Number of spaces tabs count for
opt('b', 'softtabstop', 0)                            -- Number of spaces tabs count for
opt('b', 'fileencoding', 'utf-8')
opt('o', 'updatetime', 1000)
opt('o', 'inccommand', 'split')                       -- Show search results in a split
opt('o', 'completeopt', 'menuone,noinsert,noselect')  -- Completion options (for deoplete)
opt('o', 'hidden', true)                              -- Enable modified buffers in background
opt('o', 'incsearch', true)                           -- Enable modified buffers in background
opt('o', 'hlsearch', true)                            -- Enable modified buffers in background
opt('o', 'ignorecase', true)                          -- Ignore case
opt('o', 'joinspaces', false)                         -- No double spaces with join after a dot
opt('o', 'scrolloff', 4 )                             -- Lines of context
opt('o', 'shiftround', true)                          -- Round indent
opt('o', 'sidescrolloff', 8 )                         -- Columns of context
opt('o', 'smartcase', true)                           -- Don't ignore case with capitals
opt('o', 'splitbelow', true)                          -- Put new windows below current
opt('o', 'splitright', true)                          -- Put new windows right of current
opt('o', 'termguicolors', true)                       -- True color support
opt('o', 'wildmode', 'list:longest')                  -- Command-line completion mode
opt('o', 'clipboard', get_opt('o', 'clipboard') .. 'unnamedplus')                  -- Setup global clipboard
-- Autoreload files {{{
opt('o', 'autoread', true)
cmd 'au BufEnter,FocusGained,InsertEnter * :checkt'
-- }}}


opt('w', 'list', true)                                -- Show some invisible characters (tabs...)
opt('w', 'number', true)                              -- Print line number
opt('w', 'relativenumber', true)                      -- Relative line numbers
opt('w', 'wrap', false)                               -- Disable line wrap


-- mapping BOF (TODO: port maps from .vimrc)
map('n', '<C-j>', ':+10<CR>')
map('v', '<C-j>', '10j<CR>', {noremap = false})
map('n', '<C-k>', ':-10<CR>')
map('v', '<C-k>', '10k<CR>')
map('n', '<space><Esc>', ':noh<CR>')
map('n', '<space>bd', ':bufdo bd<CR><CR>', {noremap = false})
map('', '<space>d', ':NERDTreeToggleVCS<CR>', {noremap = false})
map('n', '<space>l', ':NERDTreeFind<CR>', {noremap = false})
map('n', '<space>bc', ':BCommits<CR>')
map('n', '<C-p>', ':Files<CR>')
-- map('n', '<C-p>', ':Telescope find_files<CR>')
map('n', '<C-h>', ':History<CR>')
-- map('n', '<C-h>', ':Telescope oldfiles<CR>')
map('n', '<space>a', ':Rg<CR>')
map('n', '<space>f', ':Rg <C-R><C-W><CR>', {noremap = false})
-- map('n', '<space>f', ':Telescope live_grep <C-R><C-W><CR>', {noremap = false})
map('n', '<space><space>b', ':Buffers<CR>')
map('n', '<space>=', '<C-w>=')
map('n', '<space>+ :tab', 'split<CR>')
-- " Move visual block
-- vnoremap J :m '>+1<CR>gv=gv
-- vnoremap K :m '<-2<CR>gv=gv
