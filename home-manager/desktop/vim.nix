{ pkgs, ... }:

{
  # Packages that should be installed to the user profile.
  home.packages = [
    # neovim needs xclip for clipboard access
    pkgs.xclip

    # LSP servers
    pkgs.nodePackages.pyright
    pkgs.nil
    pkgs.hoonLanguageServer
    pkgs.gopls
  ];

  programs.neovim = {
    enable = true;

    extraConfig = ''
      " colour scheme
      let g:gruvbox_italic=1
      set background=dark
      autocmd vimenter * ++nested colorscheme gruvbox

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

      let mapleader = '-'      " use a leader key that's convenient for dvorak

      " <c-^> means 'Edit the alternate file' (i.e. go back to previous file)
      nnoremap <leader><leader> <c-^>

      " ==== lightline ====
      let g:lightline#lsp#indicator_info = "\uf129"
      let g:lightline#lsp#indicator_warnings = "\uf071 "
      let g:lightline#lsp#indicator_errors = "\uf05e "

      let g:lightline = {}
      let g:lightline.component_expand = {
        \   'lsp_warnings': 'lightline#lsp#warnings',
        \   'lsp_errors': 'lightline#lsp#errors',
        \   'lsp_info': 'lightline#lsp#info',
        \   'lsp_hints': 'lightline#lsp#hints',
        \   'lsp_ok': 'lightline#lsp#ok',
        \   'status': 'lightline#lsp#status',
        \ }

      " Set color to the components:
      let g:lightline.component_type = {
        \   'lsp_warnings': 'warning',
        \   'lsp_errors': 'error',
        \   'lsp_info': 'info',
        \   'lsp_hints': 'hints',
        \   'lsp_ok': 'left',
        \ }

      " Add the components to the lightline:
      let g:lightline.active = {
            \ 'right': [ [ 'lsp_info', 'lsp_hints', 'lsp_errors', 'lsp_warnings', 'lsp_ok' ],
            \            [ 'lsp_status' ],
            \            [ 'lineinfo' ],
            \            [ 'percent' ],
            \            [ 'fileformat', 'fileencoding', 'filetype'] ] }

      " LSP configuration
      :luafile ~/.config/nvim/lsp.lua
    '';

    plugins = with pkgs.vimPlugins;
     [
        gruvbox-community
        vim-nix
        bufexplorer
        hoon-vim
        lightline-vim
        nvim-lspconfig
        nvim-lightline-lsp
      ]; # Only loaded if programs.neovim.extraConfig is set

    vimAlias = true;
  };

  home.file.".config/nvim/lsp.lua".source = ./files/lsp.lua;
}
