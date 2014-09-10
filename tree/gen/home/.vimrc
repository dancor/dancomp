set nocompatible

set iskeyword=a-z,A-Z,_,.,39

" this is required for vundle; why?
filetype off

" Disable un-Ascii-fication of Haskell lines:
let g:haskell_conceal = 0

let g:syntastic_haskell_checker_args="--hlintOpt=-i=Use foldr"

" Vundle:
set rtp+=~/.vim/bundle/vundle/
call vundle#rc()
Bundle 'gmarik/vundle'
" Github repos:
Bundle 'dag/vim2hs'
Bundle 'eagletmt/ghcmod-vim'
Bundle 'godlygeek/tabular'
Bundle 'pbrisbin/html-template-syntax'
" Can't find a lot of imports?
"Bundle 'scrooloose/syntastic'
Bundle 'shougo/vimproc'
Bundle 'ujihisa/neco-ghc'

" this is required for vundle; why?
filetype plugin indent on

" safety
set backup
set backupdir=~/.vim/tmp,.
set directory=~/.vim/tmp,.

autocmd BufNew,BufRead,BufNewFile todo set filetype=todo
autocmd BufNew,BufRead,BufNewFile *.hsc set syntax=haskell

set vb t_vb=

" todo: should we also git push?  would want to detect internetness tho..
autocmd FileType todo
  \ autocmd BufWritePost <buffer>
  \ execute 'execute ''silent !git-checkpoint'' | redraw!'

set shellpipe=2>
"set errorformat=
"  \%-Z\ %#,
"  \%W%f:%l:%c:\ Warning:\ %m,
"  \%E%f:%l:%c:\ %m,
"  \%E%>%f:%l:%c:,
"  \%+C\ \ %#%m,
"  \%W%>%f:%l:%c:,
"  \%+C\ \ %#%tarning:\ %m,

set noerrorbells

" Highlight current line.
set cul

" If there are errors,open (but don't go to) the quickfix window.
" Close it when the quickfix list has become empty.
autocmd QuickFixCmdPost [^l]* nested cwindow
autocmd QuickFixCmdPost    l* nested lwindow

filetype plugin on
let g:haddock_browser = "/usr/bin/chromium"

set expandtab
set sw=2
autocmd FileType sql set shiftwidth=2|set expandtab|set autoindent|
  \set softtabstop=2
autocmd FileType javascript set shiftwidth=2|set expandtab|
  \set autoindent|set softtabstop=2
autocmd FileType python set shiftwidth=4|set expandtab|set autoindent|
  \set softtabstop=4
autocmd FileType perl set shiftwidth=4|set expandtab|set autoindent|
  \set softtabstop=4

set tags=tags;/

set background=dark
syntax on
set ruler
set incsearch

" XML autocommands
autocmd BufRead *.xml source ~/.vim-files/xml.vim
autocmd BufNewFile *.xml source ~/.vim-files/xml.vim

"colorscheme desert
"colorscheme habiLight
"colorscheme distinguished

" bash-like tab completion
set wildmode=list:longest

set viminfo='10,\"100,:20,%,n~/.viminfo
autocmd BufReadPost * if line("'\"") > 0|if line("'\"") <= line("$")|
  \execute("norm '\"")|else|execute("norm $")|endif|endif

"map ,:w<CR>
map <F4> :w<CR>
imap <F4> <ESC><F4>
map <F5> :w<CR>:make<CR>
imap <F5> <ESC><F4>

" F9 stands for executive actions
map <F9>r :so ~/.vimrc<CR>
map <F9>p :set paste<CR>
map <F9>P :set nopaste<CR>
map <F9>n :noh<CR>

" F10 stands for coding/refactor/eall/facebook
map <F10>& xiisset(<ESC>pa) && <ESC>p
map <F10>' :s/"/'/g
map <F10>? xiisset(<ESC>pa) ? <ESC>pa : null<ESC>
map <F10>t :s/tpl_set('\(.*\)',\(.*\)); *$/$\1 = \2;/<CR>j
map <F10>T :s/tpl_set('\(.*\)',\(.*\)); *$/$\1_tdata = \2;/<CR>j

map <F10>- :s/^/--/<CR>:noh<CR>
map <F10>_ :s/^--//<CR>
map <F10>/ :s@^@//@<CR>:noh<CR>
map <F10>\ :s@^//@\1@<CR>
map <F10># :s@^@#@<CR>:noh<CR>
map <F10>@ :s@^#@@<CR>:noh<CR>

map <F10># :s/^/#/<CR>:noh<CR>
map <F10>3 :s/^#//<CR>:noh<CR>

map <F10>b :set nowrap<CR>
  \:set scrollbind<CR>
  \:let f = expand('%')<CR>
  \:let linenum = line('.')<CR>
  \:execute 'vnew +0r\ !git\ blame\ '.f<CR>
  \:set buftype=nofile<CR>
  \:set scrollbind<CR>
  \:syncbind<CR>
  \17<C-W>\|
  \<C-W>l
  \:execute linenum<CR>

" there is a weird bug where this will jump to top on error..
function! NextThing()
  try
    cn
  catch /^Vim\%((\a\+)\)\=:E553/
    try
      next
    catch /^Vim\%((\a\+)\)\=:E16[35]/
      echo "No More Things."
    endtry
  endtry
endfunction

function! PrevThing()
  try
    cp
  catch /^Vim\%((\a\+)\)\=:E553/
    try
      previous
    catch /^Vim\%((\a\+)\)\=:E16[34]/
      echo "No More Things."
    endtry
  endtry
endfunction

map <F11> :silent! ':w'<CR>:call PrevThing()<CR>
map <F12> :silent! ':w'<CR>:call NextThing()<CR>
imap <F11> <ESC><F11>
imap <F12> <ESC><F12>

cmap w!! w !sudo tee %

set foldlevelstart=20

" Vim default error formats match row but not column for GHC errors.
" This gets me column matching for now, although the compressed one-line
" presentation of the error may be less readable than the default.
autocmd FileType haskell 
  \ set errorformat=%A%f:%l:%c:,%A%f:%l:%c:\ %m,%+C\ \ \ \ %m,%-Z%[%^\ ]
