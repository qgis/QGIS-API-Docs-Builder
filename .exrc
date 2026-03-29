" QGIS API Docs Builder - Neovim Configuration
" Leader key shortcuts under <leader>p (project)

" Ensure we're in normal mode for these mappings
nnoremap <leader>pb :!nix run .#build<CR>
nnoremap <leader>pB :!nix run .#build -- --clean<CR>
nnoremap <leader>ps :!nix run .#serve &<CR>
nnoremap <leader>pc :!nix run .#clean<CR>
nnoremap <leader>ph :!nix run .#build -- --help<CR>
nnoremap <leader>po :!xdg-open output/index.html 2>/dev/null || open output/index.html<CR>

" Quick access
nnoremap <leader>pf :e flake.nix<CR>
nnoremap <leader>pr :e README.md<CR>
