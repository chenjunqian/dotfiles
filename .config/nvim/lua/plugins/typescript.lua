return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "typescript", "tsx" } },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        vtsls = {
          settings = {
            typescript = {
              diagnostics = {
                ignoredCodes = { 6133 }, -- Code for "declared but never read"
              },
            },
          },
        },
      },
    },
  },
}
