" colour scheme
let g:gruvbox_italic=1
set background=dark
set termguicolors
colorscheme gruvbox

filetype indent on
filetype plugin on
filetype on

" be OCD about stray whitespace
autocmd ColorScheme *
  \ highlight RedundantSpaces term=standout ctermbg=red guibg=red
match RedundantSpaces /\s\+$\| \+\ze\t/

set encoding=utf-8
set fileencoding=utf-8

set expandtab
set tabstop=2
set shiftwidth=2

set linebreak            " don't break lines in the middle of words

set hlsearch

set laststatus=2

set relativenumber
set number

set formatoptions+=j     " Delete comment character when joining commented lines

set colorcolumn=80,88,100   " Show where to break lines

let mapleader = '-'      " use a leader key that's convenient for dvorak

" <c-^> means 'Edit the alternate file' (i.e. go back to previous file)
nnoremap <leader><leader> <c-^>
