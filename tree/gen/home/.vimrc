" Make escape work faster.
set timeoutlen=1000 ttimeoutlen=0

set backupdir=~/.vim/backup//
set directory=~/.vim/swp//

" Basics and Vundle.
set nocompatible
"filetype off
execute pathogen#infect()
filetype plugin indent on

autocmd BufEnter * :syntax sync fromstart

" Remember position when reopening a file
autocmd BufReadPost * if @% !~# '\.git[\/\\]COMMIT_EDITMSG$' && line("'\"") > 1 && line("'\"") <= line("$") | exe

map <F4> :w<CR>
imap <F4> <ESC><F4>

map <F9>p :set paste<CR>
map <F9>P :set nopaste<CR>

set expandtab
set sw=4
set ts=4
" todo change for py files?
set si

" Tell vim to remember certain things when we exit
"  '10  :  marks will be remembered for up to 10 previously edited files
"  "100 :  will save up to 100 lines for each register
"  :20  :  up to 20 lines of command-line history will be remembered
"  %    :  saves and restores the buffer list
"  n... :  where to save the viminfo files
set viminfo='10,\"10000,:20,%,n~/.viminfo

" When editing a file, always jump to the last known cursor position.
" Don't do it when the position is invalid or when inside an event handler
" (happens when dropping a file on gvim).
autocmd BufReadPost *
  \ if line("'\"") > 0 && line("'\"") <= line("$") |
  \   exe "normal g`\"" |
  \ endif

colo zellner
