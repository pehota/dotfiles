set nocompatible

" === Plugins ===
call plug#begin()

try
  source ~/.vimrc.js/vimrc.plugs
  source ~/.vimrc.js/vimrc.plugs.local
catch
endtry

call plug#end()

syntax enable

function! StrTrim(txt)
  return substitute(a:txt, '^\n*\s*\(.\{-}\)\n*\s*$', '\1', '')
endfunction

let g:flow_path = StrTrim(system('PATH=$(npm bin):$PATH && which flow'))

" === Plugin settings ===

if has('nvim')
  " == Shougo/deoplete.nvim ==
  " == carlitux/deoplete-ternjs ==
  let g:deoplete#enable_at_startup = 1
  let g:SuperTabDefaultCompletionType = "<c-n>"
  let g:deoplete#sources#flow#flow_bin = g:flow_path
  let g:tern_request_timeout = 1
  let g:tern_show_signature_in_pum = 0
  set completeopt-=preview

  " == neomake/neomake ==
  let g:neomake_warning_sign = {
  \ 'text': 'W',
  \ 'texthl': 'WarningMsg',
  \ }
  let g:neomake_error_sign = {
  \ 'text': 'E',
  \ 'texthl': 'ErrorMsg',
  \ }
  let g:neomake_javascript_enabled_makers = ['eslint', 'flow']
  let g:neomake_jsx_enabled_makers = ['eslint', 'flow']

  let g:neomake_javascript_flow_exe = g:flow_path
  let g:neomake_jsx_flow_exe = g:flow_path

  autocmd! BufWritePost * Neomake
else
  " == scrooloose/syntastic ==
  set statusline+=%#warningmsg#
  set statusline+=%{SyntasticStatuslineFlag()}
  set statusline+=%*
  let g:syntastic_always_populate_loc_list = 0
  let g:syntastic_auto_jump = 0
  let g:syntastic_auto_loc_list = 0
  let g:syntastic_check_on_open = 0
  let g:syntastic_check_on_wq = 1
  let g:syntastic_javascript_checkers = ['eslint']
endif

" == mxw/vim-jsx ==
let g:jsx_ext_required = 0


" == scrooloose/nerdtree ==
map <F3> :NERDTreeToggle<CR>
map <C-`> :terminal<CR>

try
  source ~/.vimrc.js/vimrc
catch
endtry


" Settings
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
let loaded_matchparen=1
set splitright
" set clipboard=unnamed
set clipboard=unnamedplus


filetype plugin indent on

" Visual
syntax on
set completeopt=menu
set gcr=a:blinkon1
set tabstop=4
set softtabstop=0
set shiftwidth=4
set expandtab
set visualbell
set t_Co=256
colorscheme molokai
highlight ColorColumn ctermbg=darkgrey

" Powerline
set rtp+=$HOME/.local/lib/python2.7/site-packages/powerline/bindings/vim/
set laststatus=2

" Bindings
nmap <F5> :%w !pbcopy<Return>
nmap <F6> :r !pbpaste<Return>
nmap <F9> :exec "!git blame ".(expand('%:p'))." -L".(line("."))<cr>
nmap <Tab> :b#<CR>
set pastetoggle=<F4>

" Identation and Spaces
autocmd FileType html,htmldjango,css,scss,less,sass,stylus,json,javascript,coffee setlocal expandtab shiftwidth=2 tabstop=2 softtabstop=2 colorcolumn=80
autocmd FileType python setlocal expandtab shiftwidth=4 tabstop=4 softtabstop=4 colorcolumn=80

" Filetypes
autocmd BufRead,BufNewFile *.jsx,*.ejs set filetype=javascript
autocmd BufRead,BufNewFile *.md,markdown,*.mkd setlocal syntax=markdown
autocmd BufRead,BufNewFile *.json set filetype=json

" Autoreload file
set autoread
au CursorMoved,CursorHold,FocusGained,BufEnter,InsertEnter * :checkt

" Autochange currdir
autocmd BufEnter * silent! lcd %:p:h

" ctrlp
let g:ctrlp_custom_ignore = '\v[\/]\.(git|hg|svn|meteor)$|node_modules'
let g:ctrlp_max_height=25
let g:ctrlp_clear_cache_on_exit=0
let g:ctrlp_max_files=0
let g:ctrlp_max_depth=40
let g:ackprg = 'ag --nogroup --nocolor --column'

" Remember last location in file
if has("autocmd")
  au BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$")
        \| exe "normal g'\"" | endif
endif

" Emmet
let g:user_emmet_install_global = 1
autocmd FileType html,htmldjango,css,scss,sass,styl,javascript EmmetInstall

" Better Whitespace
autocmd FileType css,sass,less,scss,coffee,python,html,javascript,htmldjango,markdown autocmd BufWritePre <buffer> StripWhitespace

" Autocomplete with tern
set omnifunc=syntaxcomplete#Complete
let g:tern_map_keys=1
let g:tern_show_argument_hints="on_hold"

let g:neomake_javascript_eslint_exe = '/Users/gabrielhpugliese/Workspace/merchant-frontend/merchant-app/node_modules/.bin/eslint'

" CSSComb

autocmd BufWritePre,FileWritePre *.css,*.less,*.scss,*.sass silent! :CSScomb
