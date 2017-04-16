set nocompatible

call plug#begin()

source ~/.dotfiles/vimrc-sources/plugs.vim

call plug#end()

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
set t_Co=256
" set termguicolors
colorscheme molokai

" Highlight matching parenthesis
au VimEnter * DoMatchParen 

" Highlight current line
augroup CursorLine
  au!
  au VimEnter,WinEnter,BufWinEnter * setlocal cursorline
  au WinLeave * setlocal nocursorline
augroup END

" enable line numbers
set number
set backupdir=~/.vimfiles/backup/
set directory=~/.vimfiles/backup/
set backupcopy=yes
set fileencoding=utf-8
set encoding=utf-8
set guifont=Droid\ Sans\ Mono\ for\ Powerline:h11
set hidden
set hlsearch
set incsearch
set ignorecase
set smartcase
set nu
set mouse=
set splitright
set clipboard=unnamedplus

" == Autoreload file
set autoread
au CursorMoved,CursorHold,FocusGained,BufEnter,InsertEnter * :checkt

" Autochange currdir
autocmd BufEnter * silent! lcd %:p:h

" Add spaces after comment delimiters by default
let g:NERDSpaceDelims = 1

" == Identation and Spaces
autocmd FileType html,htmldjango,css,scss,less,sass,stylus,json,javascript,coffee setlocal expandtab shiftwidth=2 tabstop=2 softtabstop=2 colorcolumn=80
autocmd FileType python setlocal expandtab shiftwidth=4 tabstop=4 softtabstop=4 colorcolumn=80

" Session Management
" automatically load and save session on start/exit.
" Modified by robin burchell <w00t@inspircd.org> to only load/save sessions if started with no arguments.
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

" Try to improve scrolling speed
set lazyredraw

if !has('nvim')
  set ttyfast
endif

"============ mappings
source ~/.dotfiles/vimrc-sources/maps.vim
