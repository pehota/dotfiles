" enable mapping for Alt key on Ubuntu
if has('vim')
  let c='a'
  while c <= 'z'
    exec "set <A-".c.">=\e".c
    exec "imap \e".c." <A-".c.">"
    let c = nr2char(1+char2nr(c))
  endw
endif

let s:uname = system("uname")

set timeout ttimeoutlen=50

let mapleader = "\<space>"
let g:mapleader = "\<space>"

" == scrooloose/nerdtree ==
let NERDTreeShowHidden=1
map <silent> <F3> :NERDTreeToggle<CR>
nmap <silent> <F2> :NERDTreeFind<CR>
nmap <silent> <Leader>t :!npm run test<CR>

nmap <silent> <A-k> :wincmd k<CR>
nmap <silent> <A-j> :wincmd j<CR>
nmap <silent> <A-h> :wincmd h<CR>
nmap <silent> <A-l> :wincmd l<CR>

if s:uname == "Darwin\n"
  nmap <silent> ˚ :wincmd k<CR>
  nmap <silent> ª :wincmd j<CR>
  nmap <silent> ˙ :wincmd h<CR>
  nmap <silent> ¬ :wincmd l<CR>
endif

nmap <silent> <A-w> :bp\|bd#<CR>
nmap <silent> <Leader><Esc> :noh<CR>

nmap <silent> <F9> :Gblame<CR>
nmap <silent> <Tab> :b#<CR>
nmap <silent> <S-Tab> :bn<CR>

nmap <silent> <C-j> :+10<CR>
vmap <silent> <C-j> 10j<CR>
nnoremap <silent> <C-k> :-10<CR>
vnoremap <silent> <C-k> 10k<CR>


set pastetoggle=<F4>

cnoreabbrev Ack Ack!
nnoremap <Leader>a :Ack!<Space>
nnoremap <C-p> :FZF<cr>
