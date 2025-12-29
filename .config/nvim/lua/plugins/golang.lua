return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      gopls = {
        settings = {
          gopls = {
            analyses = { unusedparams = true, shadow = true },
            gofumpt = true,
          },
        },
      },
    },
  },
}
