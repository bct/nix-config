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
set noshowmode           " Don't show the current mode (lightline.vim takes care of us)

set colorcolumn=80,100   " Show where to break lines

let mapleader = '-'      " use a leader key that's convenient for dvorak

" <c-^> means 'Edit the alternate file' (i.e. go back to previous file)
nnoremap <leader><leader> <c-^>

" ==== lightline ====
let g:lightline#lsp#indicator_hints = "\uf002 "
let g:lightline#lsp#indicator_infos = "\uf129 "
let g:lightline#lsp#indicator_warnings = "\uf071 "
let g:lightline#lsp#indicator_errors = "\uf05e "
let g:lightline#lsp#indicator_ok = "\uf00c "

let g:lightline = {}
let g:lightline.colorscheme = "gruvbox"
let g:lightline.component_expand = {
  \   'lsp_warnings': 'lightline#lsp#warnings',
  \   'lsp_errors': 'lightline#lsp#errors',
  \   'lsp_infos': 'lightline#lsp#infos',
  \   'lsp_hints': 'lightline#lsp#hints',
  \   'lsp_ok': 'lightline#lsp#ok',
  \   'status': 'lightline#lsp#status',
  \ }

" Set color to the components:
let g:lightline.component_type = {
  \   'lsp_warnings': 'warning',
  \   'lsp_errors': 'error',
  \   'lsp_infos': 'right',
  \   'lsp_hints': 'right',
  \   'lsp_ok': 'right',
  \ }

" Add the components to the lightline:
let g:lightline.active = {
      \ 'left': [ [ 'mode', 'paste' ], [ 'readonly', 'relativepath', 'modified' ] ],
      \ 'right': [ [ 'lsp_infos', 'lsp_hints', 'lsp_errors', 'lsp_warnings', 'lsp_ok' ],
      \            [ 'lsp_status' ],
      \            [ 'lineinfo' ],
      \            [ 'percent' ],
      \            [ 'fileformat', 'fileencoding', 'filetype'] ] }
'';
