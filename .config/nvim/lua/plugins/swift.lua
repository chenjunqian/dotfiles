return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      sourcekit = {
        cmd = { "sourcekit-lsp" },
        filetypes = { "swift", "swiftpm" },
      },
    },
  },
}
