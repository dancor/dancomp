map <F4> :noh<CR>:w<CR>
imap <F4> <ESC><F4>

map <F2> :set rl<CR>
map <F3> :set norl<CR>
imap <F2> <ESC><F2>a
imap <F3> <ESC><F3>a

map <F9>p :set paste<CR>
map <F9>P :set nopaste<CR>

set expandtab
set sw=4
set ts=4
set si

set clipboard=unnamedplus

filetype on
au BufNewFile,BufRead todoDanlCal.txt set syntax=mytodo
