-- QGIS API Docs Builder - Neovim Lua Configuration
-- Project-specific settings and which-key integration

-- Check if which-key is available
local ok, wk = pcall(require, "which-key")
if ok then
  wk.register({
    p = {
      name = "Project (QGIS API Docs)",
      b = { "<cmd>!nix run .#build<cr>", "Build API docs" },
      B = { "<cmd>!nix run .#build -- --clean<cr>", "Clean build API docs" },
      s = { "<cmd>!nix run .#serve &<cr>", "Serve docs locally" },
      c = { "<cmd>!nix run .#clean<cr>", "Clean build artifacts" },
      h = { "<cmd>!nix run .#build -- --help<cr>", "Show build help" },
      o = { "<cmd>!xdg-open output/index.html 2>/dev/null || open output/index.html<cr>", "Open docs in browser" },
      f = { "<cmd>e flake.nix<cr>", "Edit flake.nix" },
      r = { "<cmd>e README.md<cr>", "Edit README.md" },
    },
  }, { prefix = "<leader>" })
end

-- Set up file type associations
vim.filetype.add({
  extension = {
    dox = "cpp",
  },
})

-- Project-local settings
vim.opt_local.tabstop = 2
vim.opt_local.shiftwidth = 2
vim.opt_local.expandtab = true
