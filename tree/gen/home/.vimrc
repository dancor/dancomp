" Make escape work faster.
set timeoutlen=1000 ttimeoutlen=0

set backupdir=~/.vim/backup//
set directory=~/.vim/swp//

" Basics and Vundle.
set nocompatible
filetype off
set rtp+=~/.vim/bundle/Vundle.vim
"call vundle#begin()
"Plugin 'morhetz/gruvbox'
"Plugin 'junegunn/seoul256.vim'
"call vundle#end()
filetype plugin indent on

"colorscheme seoul256-light
"colorscheme gruvbox
"colorscheme koehler

autocmd BufEnter * :syntax sync fromstart

map <F4> :w<CR>
imap <F4> <ESC><F4>

map <F9>p :set paste<CR>
map <F9>P :set nopaste<CR>

set expandtab
set sw=4
set ts=4
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
