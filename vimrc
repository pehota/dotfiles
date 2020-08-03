if &compatible
  set nocompatible
endif

" Check if running in headless mode
let g:isHeadlessMode = exists('*nvim_list_uis') && len(nvim_list_uis()) == 0

" Allow project specific configurations
set exrc
set secure

let mapleader = "\<space>"
let g:mapleader = "\<space>"

call plug#begin()

" NERDTree {{{
Plug 'scrooloose/nerdtree'
  let NERDTreeShowHidden = 1
  let NERDTreeMinimalUI = 0
  let NERDTreeDirArrows = 0
  let NERDTreeIgnore = ['\.bs.js$', '\.git', '\.exrc', '\.DS_Store', 'node_modules', 'elm-stuff', 'package-lock.json', 'yarn.lock', '.cache']
  " Automatically delete buffers for nodes deleted from the tree
  let NERDTreeAutoDeleteBuffer = 1
  " Automatically close NERDTree on file open
  let NERDTreeQuitOnOpen = 1
  " Automatically close NERDTree if it's the only open window
  au bufenter * if (winnr("$") == 1 && exists("b:NERDTreeType") && b:NERDTreeType == "primary") | q | endif
" }}}

" Colorsheme
Plug 'dkasak/gruvbox'

" Lightline {{{
Plug 'itchyny/lightline.vim'
Plug 'shinchu/lightline-gruvbox.vim'
  let g:lightline = { 'active': {} }
  let g:lightline.active.left = [ ['mode', 'paste'], ['gitbranch', 'readonly', 'filename', 'modified'], [ 'linter_checking', 'linter_errors', 'linter_warnings', 'linter_ok' ] ]
  let g:lightline.component_function = { 'gitbranch': 'fugitive#head' }
  let g:lightline.separator = { 'left': '', 'right': '' }
  let g:lightline.subseparator = { 'left': '', 'right': '' }
  let g:lightline.colorscheme = 'gruvbox'
  let g:lightline.tabline = { 'left': [[ 'tabs' ]], 'right': [[ 'close' ]] }
" }}}

" Fzf {{{
Plug 'junegunn/fzf.vim'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
  let g:fzf_command_prefix = 'Fzf'
  " disable statusline overriding
  let g:fzf_nvim_statusline = 0
  let $FZF_DEFAULT_COMMAND = 'rg --files --hidden --follow --no-line-number --ignore-file ~/.gitignore'
" }}}

Plug 'tpope/vim-surround'
" Adjust 'shiftwidth' and 'expandtab' heuristically
Plug 'tpope/vim-sleuth'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-commentary'
" vim-vinegar {{{
Plug 'tpope/vim-vinegar' 
  let g:netrw_list_hide = '\(^\|\s\s\)\zs\.\S\+'
" }}}


Plug 'unblevable/quick-scope'
Plug 'alvan/vim-closetag'
Plug 'google/vim-searchindex'
Plug 'nathanaelkane/vim-indent-guides'
Plug 'vim-scripts/BufOnly.vim'
Plug 'jiangmiao/auto-pairs'
Plug 'sheerun/vim-polyglot'
Plug 'terryma/vim-multiple-cursors'
Plug 'ervandew/supertab'
" Plug 'ryanoasis/vim-devicons'
Plug 'zivyangll/git-blame.vim', { 'on': 'GitBlame' }
Plug 'mbbill/undotree'

" coc.nvim {{{
Plug 'neoclide/coc.nvim', {'branch': 'release'}
  nmap <leader>rn <Plug>(coc-rename)
  nmap <silent> gd <Plug>(coc-definition)
  nmap <silent> gy <Plug>(coc-type-definition)
  nmap <silent> gi <Plug>(coc-implementation)
  nmap <silent> gr <Plug>(coc-references)
  nmap <silent> ]w <Plug>(coc-diagnostic-next)
  nmap <silent> [w <Plug>(coc-diagnostic-prev)
  nmap <silent> <leader>rf <Plug>(coc-refactor)
  nmap <silent> <leader>? :call CocAction('doHover')<CR>
  nmap <localleader>? :CocList diagnostics<CR>
  nnoremap <expr><C-f> coc#util#has_float() ? coc#util#float_scroll(1) : "\<C-f>"
  nnoremap <expr><C-b> coc#util#has_float() ? coc#util#float_scroll(0) : "\<C-b>"
  nnoremap  <silent> <Leader>t :CocList outline<CR>
  nnoremap  <silent> <localleader>a :CocAction<CR>
" }}}

" Rooter {{{
Plug 'airblade/vim-rooter'
  let g:rooter_silent_chdir = 1
  let g:rooter_patterns = ['.git/', 'package.json', 'elm-package.json', 'elm.json', 'stack.yaml']
" }}}

" Signify {{{
Plug 'mhinz/vim-signify'
  let g:signify_vcs_list = ['git']
  let g:signify_sign_add               = '+'
  let g:signify_sign_delete            = '-'
  let g:signify_sign_delete_first_line = g:signify_sign_delete
  let g:signify_sign_change            = '~'
  let g:signify_sign_changedelete      = g:signify_sign_change
" }}}


" Auto Origami {{{
Plug 'benknoble/vim-auto-origami'
if !g:isHeadlessMode 
  augroup autofoldcolumn
    au!
    au BufWinEnter,WinEnter * AutoOrigamiFoldColumn
  augroup END
endif
" }}}

call plug#end()

" Session Management
" automatically load and save session on start/exit.
function! MakeSession()
  if g:isHeadlessMode
    return
  endif
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


" Protect changes between writes. Default values of
" updatecount (200 keystrokes) and updatetime
" (4 seconds) are fine
set swapfile
set directory=~/.vim/backup//

" protect against crash-during-write
set writebackup
" but do not persist backup after successful write
set nobackup
" use rename-and-write-new method whenever safe
set backupcopy=yes
" patch required to honor double slash at end
if has("patch-8.1.0251")
  " consolidate the writebackups -- not a big
  " deal either way, since they usually get deleted
  set backupdir=~/.vim/backup//
end

" persist the undo tree for each file
set undofile
set undodir^=~/.vim/undo//

set fileencoding=utf-8
set hidden
set hlsearch
set incsearch
set ignorecase
set smartcase
set nu
set mouse=n
set clipboard+=unnamedplus
set guifont=Hack\ Nerd\ Font:h12
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
set tabstop=2
set softtabstop=0
set switchbuf=usetab,vsplit
set autoindent
set visualbell
set showcmd
set cursorline " Highlight current line
set guicursor+=n:blinkon1
set laststatus=2
set wildmenu
set t_Co=256
set diffopt-=internal
set number
set relativenumber
set guioptions-=T " Removes top toolbar
set guioptions-=r " Removes right hand scroll bar
set guioptions-=L " Removes left hand scroll bar
set nojoinspaces
set showmatch
set updatetime=100
" fuzzy matching with :find *.ext*
set path+=**
" Ignore some folders
set wildignore+=**/node_modules/**
set wildignore+=**/elm-stuff/**
set wildignore+=**/debug/**
set wildignore+=**/build/**
set wildignore+=**/dist/**
set wildignore+=**/*.bs.js
set wildignore+=**/yarn.lock
set wildignore+=**/package-lock.json

colorscheme gruvbox
" transparent background for vim
highlight Normal ctermbg=NONE
" transarent background for signs column
highlight SignColumn guibg=NONE ctermbg=NONE

" Disable modeline
set nomodeline

" Autoreload file {{{
set autoread
au CursorMoved,CursorHold,FocusGained,BufEnter,InsertEnter * :checkt
" }}}

" Autochange currdir
au BufEnter * silent! lcd %:p:h


" Remember last location in file
au BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$")
      \| exe "normal g'\"" | endif

" Folding
" Set automatic folding for all files
augroup folding
  au!
  au BufEnter * setlocal foldmethod=indent
  " Open all folds by default
  au BufEnter * normal zR
augroup END

" File type specific settings {{{
au FileType html,htmldjango,css,scss,less,sass,stylus,json,javascript,coffee,typescript,typescript.tsx setlocal tabstop=2 softtabstop=2 colorcolumn=81
" Collapse folds for vim files
augroup vimrc
  au!
  au BufEnter vim normal zM
  au BufEnter vim setlocal foldmethod=marker
augroup END
" }}}

" Set correct filetypes {{{
au BufRead,BufNewFile *.jsx set filetype=javascript
au BufRead,BufNewFile *.md,markdown,*.mkd setlocal syntax=markdown
au BufRead,BufNewFile *.json set filetype=json
" }}}

" Bindings {{{
  nnoremap  <silent> <C-j> :+10<CR>
  vmap      <silent> <C-j> 10j<CR>
  nnoremap  <silent> <C-k> :-10<CR>
  vnoremap  <silent> <C-k> 10k<CR>
  imap      <silent> jj <ESC>
  nnoremap  <silent> <Leader><Leader>s <ESC>:w<CR>
  nmap      <silent> <Leader><Esc> :noh<CR>
  nmap      <silent> <Leader>bd :bufdo bd<CR><CR>
  map       <silent> <C-b> :NERDTreeToggleVCS<CR>
  nmap      <silent> <C-l> :NERDTreeFind<CR>
  nnoremap  <silent> <Leader>bc :FzfBCommits<CR>
  nnoremap  <silent> <C-p> :call fzf#vim#files('', fzf#vim#with_preview('right'))<CR>
  " nnoremap  <silent> <C-p> :FzfFiles<CR>
  nnoremap  <silent> <C-h> :FzfHistory<CR>
  nnoremap  <silent> <Leader>a :FzfRg<CR>
  nmap <silent> <Leader>f :FzfRg <C-R><C-W><CR>
  nnoremap  <silent> <Leader><Leader>b :FzfBuffers<CR>
  nnoremap  <silent> <Leader>= <C-w>=
  nnoremap <silent> <Leader>+ :tab split<CR>
  " Move visual block
  vnoremap J :m '>+1<CR>gv=gv
  vnoremap K :m '<-2<CR>gv=gv
" }}}

" Commands abbreviations {{{
  cnoreabbrev W! w!
  cnoreabbrev Q! q!
  cnoreabbrev Qall! qall!
  cnoreabbrev Wq wq
  cnoreabbrev Wa wa
  cnoreabbrev wQ wq
  cnoreabbrev WQ wq
  cnoreabbrev W w
  cnoreabbrev Q q
  cnoreabbrev Qall qall
" }}}
