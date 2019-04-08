if &compatible
  set nocompatible
endif

" Allow project specific configurations
set exrc
set secure

call plug#begin()

" == NERDTree
Plug 'scrooloose/nerdtree'
let NERDTreeShowHidden=1
let NERDTreeIgnore=['\.bs.js$', '\.git', '\.exrc', '\.DS_Store', 'node_modules', 'elm-stuff', 'package-lock.json', 'yarn.lock', '.cache']

" == Colorsheme
Plug 'morhetz/gruvbox'

" == Git related plugins
Plug 'airblade/vim-gitgutter'
let g:gitgutter_override_sign_column_highlight = 0

Plug 'tpope/vim-fugitive'

" == Buffer Line
" Plug 'bling/vim-bufferline'

" == Lightline
Plug 'itchyny/lightline.vim'
Plug 'shinchu/lightline-gruvbox.vim'
let g:lightline = { 'active': {} }
let g:lightline.active.left = [ ['mode', 'paste'], ['gitbranch', 'readonly', 'filename', 'modified'], [ 'linter_checking', 'linter_errors', 'linter_warnings', 'linter_ok' ] ]
let g:lightline.component_function = { 'gitbranch': 'fugitive#head' }
let g:lightline.separator = { 'left': '', 'right': '' }
let g:lightline.subseparator = { 'left': '', 'right': '' }
let g:lightline.colorscheme = 'gruvbox'
let g:lightline.tabline = { 'left': [[ 'tabs' ]], 'right': [[ 'close' ]] }

let g:tmuxline_powerline_separators=1

" == Fzf
Plug 'junegunn/fzf.vim'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
let g:fzf_command_prefix = 'Fzf'
" disable statusline overriding
let g:fzf_nvim_statusline = 0

if executable('rg')
  let $FZF_DEFAULT_COMMAND = 'rg --files --hidden --follow --glob "!.git/*" --no-line-number'
elseif executable('ag')
  let $FZF_DEFAULT_COMMAND = 'ag --hidden --ignore .git -g ""'
  let g:ackprg = 'ag --nogroup --nocolor --column'
endif


Plug 'tpope/vim-surround'
Plug 'alvan/vim-closetag'
Plug 'google/vim-searchindex'

" Better Whitespace
Plug 'ntpeters/vim-better-whitespace'
autocmd FileType *.* autocmd BufWritePre <buffer> StripWhitespace

Plug 'nathanaelkane/vim-indent-guides'
Plug 'Olical/vim-enmasse'
Plug 'tpope/vim-sleuth'
Plug 'vim-scripts/BufOnly.vim'
Plug 'jiangmiao/auto-pairs'

" == JavaScript syntax highlighting ==
Plug 'othree/yajs.vim'
Plug 'othree/es.next.syntax.vim'
Plug 'mxw/vim-jsx'
let g:jsx_ext_required = 0
Plug 'othree/javascript-libraries-syntax.vim'

" == Fixmyjs
Plug 'ruanyl/vim-fixmyjs'
let g:fixmyjs_use_local = 1
let g:fixmyjs_rc_local = 1

" == Prettier
Plug 'prettier/vim-prettier', { 'do': 'npm install' }
let g:prettier#quickfix_enabled = 0
let g:prettier#config#config_precedence = 'file-override'
" autocmd BufWritePre *.js,*.jsx,*.mjs,*.ts,*.tsx,*.css,*.less,*.scss,*.json,*.graphql,*.md PrettierAsync



" == NERDCommenter
Plug 'scrooloose/nerdcommenter'
" Add spaces after comment delimiters by default
let g:NERDSpaceDelims = 1


" == elm
Plug 'elmcast/elm-vim'
let g:elm_format_autosave = 1

" == Rooter
Plug 'airblade/vim-rooter'
let g:rooter_silent_chdir = 1
let g:rooter_patterns = ['.git/', 'package.json', '.git', 'elm.json']

Plug 'terryma/vim-multiple-cursors'
Plug 'airblade/vim-gitgutter'
Plug 'ervandew/supertab'
Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'zivyangll/git-blame.vim'


Plug 'neovimhaskell/haskell-vim'
let g:haskell_classic_highlighting = 1
let g:haskell_indent_disable = 1

Plug 'nbouscal/vim-stylish-haskell'
Plug 'eagletmt/neco-ghc'

" == ALE
" Enable completion where available.
" This setting must be set before ALE is loaded.
let g:ale_completion_enabled = 1

Plug 'w0rp/ale'

let g:ale_linters = {
\   'javascript': ['eslint'],
\   'haskell': ['hdevtools', 'hlint'],
\}

let g:ale_fixers = {
\   '*': ['remove_trailing_lines', 'trim_whitespace'],
\   'css': ['prettier'],
\   'elm': ['elm-format'],
\   'haskell': ['brittany'],
\   'javascript': ['prettier'],
\   'json': ['prettier'],
\   'typescript': ['prettier'],
\}

" Do not lint or fix minified files.
let g:ale_pattern_options = {
\ '\.min\.*$': {'ale_linters': [], 'ale_fixers': []},
\}

let g:ale_javascript_prettier_use_local_config = 1
let g:ale_lint_on_text_changed = 'never'
let g:ale_fix_on_save = 1
let g:ale_set_highlights = 0

let g:ale_sign_error = "\uf05e"
let g:ale_sign_warning = "\uf071"
let g:ale_sign_info = "\uf05a"


let g:ale_echo_msg_error_str = 'Error'
let g:ale_echo_msg_warning_str = 'Warning'
let g:ale_echo_msg_format = '%severity%: %s'

let g:ale_set_loclist = 0
let g:ale_set_quickfix = 1

" == Autotags
Plug 'craigemery/vim-autotag'
let g:autotagCtagsCmd = 'ctags'

" == TypeScript start
Plug 'HerringtonDarkholme/yats.vim'
Plug 'mhartington/nvim-typescript', {'do': './install.sh'}
" == TypeScript end

" For async completion
Plug 'Shougo/deoplete.nvim'
" Enable deoplete at startup
let g:deoplete#enable_at_startup = 1

" == Rust
Plug 'rust-lang/rust.vim'

" == GraphQL
Plug 'jparise/vim-graphql'

" For Denite features
Plug 'Shougo/denite.nvim'

Plug 'jceb/vim-orgmode'

Plug 'cespare/vim-toml'

call plug#end()

" Session Management
" automatically load and save session on start/exit.
function! MakeSession()
  if g:sessionfile != ""
    echo "Saving."
    if (filewritable(g:sessiondir) != 2)
      exe 'silent !mkdir -p ' g:sessiondir
      redraw!
    endif
    exe "mksession! " . g:sessionfile
  endif
endfunction

function! LoadSession()
  if argc() == 0
    let g:sessiondir = $HOME . "/.vim/sessions" . getcwd()
    let g:sessionfile = g:sessiondir . "/session.vim"
    if (filereadable(g:sessionfile))
      exe 'source ' g:sessionfile
    else
      echo "No session loaded."
    endif
  else
    let g:sessionfile = ""
    let g:sessiondir = ""
  endif
endfunction

au VimEnter * nested :call LoadSession()
au VimLeave * :call MakeSession()

" Auto-resize splits when vim resizes
au VimResized * wincmd =



set backupdir=~/.vimfiles/backup/
set directory=~/.vimfiles/backup/
set backupcopy=yes
set fileencoding=utf-8
set hidden
set hlsearch
set incsearch
set ignorecase
set smartcase
set nu
set mouse=
set clipboard+=unnamedplus
set guifont=DroidSansMonoForPowerline\ Nerd\ Font:h12
set backspace=2
" Position splits below and right
set splitright
set splitbelow
set whichwrap+=<,>,h,l,[,]

filetype indent on
filetype plugin indent on

" Visual
syntax on
set completeopt=menu
set gcr=a:blinkon1
set tabstop=2
set softtabstop=0
set shiftwidth=2
set autoindent
set expandtab
set visualbell
set showcmd
set cursorline " Highlight current line
set laststatus=2
set wildmenu
set t_Co=256
set diffopt-=internal
set nonu
set relativenumber
colorscheme gruvbox
highlight ColorColumn guibg=NONE ctermbg=NONE
highlight SignColumn guibg=NONE ctermbg=NONE
highlight Directory guibg=darkgrey ctermfg=darkgrey
" transparent background for vim
highlight Normal ctermbg=NONE

highlight GitGutterAdd ctermfg=green ctermbg=NONE
highlight GitGutterChange ctermfg=yellow ctermbg=NONE
highlight GitGutterDelete ctermfg=red ctermbg=NONE
highlight GitGutterChangeDelete ctermfg=red ctermbg=NONE

if g:colors_name == 'molokai'
  highlight MatchParen cterm=bold ctermbg=none ctermfg=208
endif



" == Identation and Spaces
autocmd FileType html,htmldjango,css,scss,less,sass,stylus,json,javascript,coffee,typescript setlocal shiftwidth=2 tabstop=2 softtabstop=2 colorcolumn=80
autocmd FileType sh setlocal expandtab


" == Filetypes
autocmd BufRead,BufNewFile *.jsx,*.ejs set filetype=javascript
autocmd BufRead,BufNewFile *.md,markdown,*.mkd setlocal syntax=markdown
autocmd BufRead,BufNewFile *.json set filetype=json

" == Autoreload file
set autoread
au CursorMoved,CursorHold,FocusGained,BufEnter,InsertEnter * :checkt

" Autochange currdir
autocmd BufEnter * silent! lcd %:p:h


" Remember last location in file
au BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$")
      \| exe "normal g'\"" | endif

" Folding
" Set automatic folding for all files
autocmd Syntax * setlocal foldmethod=syntax
" Open all folds by default
autocmd Syntax * normal zR


" Bindings
let mapleader = "\<space>"
let g:mapleader = "\<space>"
nmap      <silent> <F9> :Gblame<CR>
nmap      <Tab> :b#<CR>
nnoremap  <silent> <C-j> :+10<CR>
vmap      <silent> <C-j> 10j<CR>
nnoremap  <silent> <C-k> :-10<CR>
vnoremap  <silent> <C-k> 10k<CR>
imap      <silent> jj <ESC>
nnoremap  <silent> <Leader><Leader>s <ESC>:w<CR>
nmap      <silent> <M-w> :bp\|bd#<CR>
nmap      <silent> <M-k> :wincmd k<CR>
nmap      <silent> <M-j> :wincmd j<CR>
nmap      <silent> <M-h> :wincmd h<CR>
nmap      <silent> <M-l> :wincmd l<CR>
nmap      <silent> <M-K> :wincmd K<CR>
nmap      <silent> <M-J> :wincmd J<CR>
nmap      <silent> <M-H> :wincmd H<CR>
nmap      <silent> <M-L> :wincmd L<CR>
nmap      <silent> <Leader><Esc> :noh<CR>
nmap      <silent> <Leader>bd :bufdo bd<CR><CR>
map       <silent> <F3> :NERDTreeToggle<CR>
nmap      <silent> <F2> :NERDTreeFind<CR>
nnoremap  <silent> <Leader>bc :FzfBCommits<CR>
nnoremap  <silent> <C-p> :call fzf#vim#files('', fzf#vim#with_preview('right'))<CR>
" nnoremap  <silent> <C-p> :FzfFiles<CR>
nnoremap  <silent> <Leader><Leader>h :FzfHistory<CR>
nnoremap  <silent> <C-h> :FzfHistory<CR>
nnoremap  <silent> <Leader>a :FzfRg<CR>
nnoremap  <silent> <Leader><Leader>b :FzfBuffers<CR>
nnoremap  <silent> <Leader>t :FzfBTags<CR>
nnoremap  <silent> <Leader>= <C-w>=
nmap <silent> <Leader>f :FzfRg <C-R><C-W><CR>
