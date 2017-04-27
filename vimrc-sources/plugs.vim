" == General editor plugins ==
Plug 'tpope/vim-surround'
Plug 'scrooloose/nerdcommenter'
Plug 'scrooloose/nerdtree'
Plug 'tpope/vim-repeat'
Plug 'jiangmiao/auto-pairs'
Plug 'airblade/vim-gitgutter'
Plug 'nathanaelkane/vim-indent-guides'
Plug 'tpope/vim-fugitive'
Plug 'mileszs/ack.vim'
Plug 'google/vim-searchindex'
Plug 'Yggdroot/indentLine'
Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'ntpeters/vim-better-whitespace'
Plug 'tiagofumo/vim-nerdtree-syntax-highlight'
Plug 'Olical/vim-enmasse'
Plug 'alvan/vim-closetag'
Plug 'tpope/vim-sleuth'
Plug 'vim-scripts/BufOnly.vim'
Plug 'kshenoy/vim-signature'
Plug 'mustache/vim-mustache-handlebars'

" == junegunn/fzf ==
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
let g:fzf_action = {
      \ 'ctrl-s': 'split',
      \ 'ctrl-v': 'vsplit'
      \ }
" disable statusline overwriting
let g:fzf_nvim_statusline=0

" == elm stuff ==
Plug 'elmcast/elm-vim'

Plug 'mileszs/ack.vim'
if executable('ag')
  let g:ackprg = 'ag --vimgrep'
endif

" == avh4/elm-format ==
Plug 'avh4/elm-format'
let g:elm_format_autosave = 1

" == ryanoasis/vim-devicons ==
Plug 'ryanoasis/vim-devicons'
let g:webdevicons_conceal_nerdtree_brackets=1

" == vim-airline/vim-airline ==
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

let g:airline_powerline_fonts=1
let g:airline_theme='badwolf'
let g:airline#extensions#tabline#enabled=1
let g:airline#extensions#tabline#fnamemod=':t'

let g:tmuxline_powerline_separators=1


" == Autocomplete plugins ==
Plug 'ervandew/supertab'

if has('nvim')
  Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins'  }
  Plug 'steelsojka/deoplete-flow'

  " == carlitux/deoplete-ternjs ==
  Plug 'carlitux/deoplete-ternjs', { 'do': 'npm install -g tern' }
  let g:deoplete#enable_at_startup = 1
  let g:SuperTabDefaultCompletionType = "<c-n>"
  " let g:deoplete#sources#flow#flow_bin = g:flow_path
  let g:tern_request_timeout = 1
  let g:tern_show_signature_in_pum = 0
  set completeopt-=preview
else
  Plug 'Valloric/YouCompleteMe', { 'do': './install.py --tern-completer' }
endif

set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*
let g:syntastic_always_populate_loc_list = 0
let g:syntastic_auto_jump = 0
let g:syntastic_auto_loc_list = 0
let g:syntastic_check_on_open = 0
let g:syntastic_check_on_wq = 1
let g:syntastic_javascript_checkers = ['eslint']


" == flowtype
Plug 'flowtype/vim-flow'



" == JavaScript syntax highlighting ==
Plug 'othree/yajs.vim'
Plug 'othree/es.next.syntax.vim'

" == mxw/vim-jsx ==
Plug 'mxw/vim-jsx'
let g:jsx_ext_required = 0

Plug 'othree/javascript-libraries-syntax.vim'

Plug 'ctrlpvim/ctrlp.vim'
Plug 'tomasr/molokai'

" == 'ctrlpvim/ctrlp.vim'
let g:ctrlp_custom_ignore = '\v[\/]\.(git|hg|svn|meteor)$|node_modules'
let g:ctrlp_max_height=25
let g:ctrlp_clear_cache_on_exit=0
let g:ctrlp_max_files=0
let g:ctrlp_max_depth=40


" == alvan/vim-closetag ==
Plug 'alvan/vim-closetag'
let g:closetag_filenames = "*.html,*.ejs,*.php,*.js"
