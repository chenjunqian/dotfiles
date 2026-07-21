return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "css",
        "scss",
        "less",
      })
    end,
  },

  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        html = {},
        cssls = {},
      },
    },
  },

  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        html = { "prettierd", "prettier" },
        css = { "prettierd", "prettier" },
        scss = { "prettierd", "prettier" },
        less = { "prettierd", "prettier" },
      },
    },
  },

  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters_by_ft = {
        css = { "stylelint" },
        scss = { "stylelint" },
        less = { "stylelint" },
      },
    },
  },

  {
    "norcalli/nvim-colorizer.lua",
    event = "BufReadPre",
    opts = {},
  },

  {
    "mattn/emmet-vim",
    event = { "BufReadPre", "BufNewFile" },
    ft = { "html", "css", "scss", "less", "javascriptreact", "typescriptreact" },
  },
}
