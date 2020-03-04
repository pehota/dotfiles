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

" == NERDTree
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
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTreeType") && b:NERDTreeType == "primary") | q | endif

" == Colorsheme
Plug 'dkasak/gruvbox'

Plug 'tpope/vim-fugitive'

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
let $FZF_DEFAULT_COMMAND = 'rg --files --hidden --follow --no-line-number --ignore-file ~/.gitignore'


Plug 'tpope/vim-surround'
Plug 'unblevable/quick-scope'
Plug 'alvan/vim-closetag'
Plug 'google/vim-searchindex'

Plug 'nathanaelkane/vim-indent-guides'
Plug 'tpope/vim-sleuth'
Plug 'vim-scripts/BufOnly.vim'
Plug 'jiangmiao/auto-pairs'

" == NERDCommenter
Plug 'scrooloose/nerdcommenter'
" Add spaces after comment delimiters by default
let g:NERDSpaceDelims = 1

" == Vim polyglot
Plug 'sheerun/vim-polyglot'

" == coc.nvim
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


" == Rooter
Plug 'airblade/vim-rooter'
let g:rooter_silent_chdir = 1
let g:rooter_patterns = ['.git/', 'package.json', 'elm-package.json', 'elm.json', 'stack.yaml']

Plug 'terryma/vim-multiple-cursors'

Plug 'mhinz/vim-signify'
let g:signify_vcs_list = ['git']
let g:signify_sign_add               = '+'
let g:signify_sign_delete            = '-'
let g:signify_sign_delete_first_line = g:signify_sign_delete
let g:signify_sign_change            = '~'
let g:signify_sign_changedelete      = g:signify_sign_change

Plug 'ervandew/supertab'
Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'tiagofumo/vim-nerdtree-syntax-highlight'
let g:NERDTreeFileExtensionHighlightFullName = 1
let g:NERDTreeExactMatchHighlightFullName = 1
let g:NERDTreePatternMatchHighlightFullName = 1
let g:NERDTreeLimitedSyntax = 1

Plug 'ryanoasis/vim-devicons'

Plug 'zivyangll/git-blame.vim', { 'on': 'GitBlame' }

Plug 'mbbill/undotree'

Plug 'benknoble/vim-auto-origami'
  if !g:isHeadlessMode 
    augroup autofoldcolumn
      au!
      au BufWinEnter,WinEnter * AutoOrigamiFoldColumn
    augroup END
  endif

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
set backupcopy=auto
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
set guifont=Hack\ Nerd\ Font\ Complete:h12
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
set switchbuf=usetab,vsplit
set autoindent
set expandtab
set visualbell
set showcmd
set cursorline " Highlight current line
set guicursor=n:blinkon1
set laststatus=2
set wildmenu
set t_Co=256
set diffopt-=internal
set number
set relativenumber
set guioptions-=T " Removes top toolbar
set guioptions-=r " Removes right hand scroll bar
set go-=L " Removes left hand scroll bar
set nojoinspaces
set showmatch
set updatetime=100
" fuzzy matching with :find *.ext*
set path+=**
" Ignore some folders
set wildignore+=**/node_modules/**
set wildignore+=**/.git/**
set wildignore+=**/build/**
set wildignore+=**/dist/**

colorscheme gruvbox
highlight SignColumn guibg=NONE ctermbg=NONE
highlight Directory guibg=darkgrey ctermfg=darkgrey
" transparent background for vim
highlight Normal ctermbg=NONE

if g:colors_name == 'molokai'
  highlight MatchParen cterm=bold ctermbg=none ctermfg=208
endif

" == Disable modeline
set nomodeline

" == Identation and Spaces
autocmd FileType html,htmldjango,css,scss,less,sass,stylus,json,javascript,coffee,typescript,typescript.tsx setlocal shiftwidth=2 tabstop=2 softtabstop=2 colorcolumn=81
autocmd FileType sh setlocal expandtab


" == Filetypes
autocmd BufRead,BufNewFile *.jsx set filetype=javascript
autocmd BufRead,BufNewFile *.md,markdown,*.mkd setlocal syntax=markdown
autocmd BufRead,BufNewFile *.json set filetype=json
" Set .rc (e.g. .eslintrc) files filetype to json but skip vimrc


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
autocmd BufEnter * setlocal foldmethod=indent
" Open all folds by default
autocmd BufEnter * normal zR


" Bindings
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
