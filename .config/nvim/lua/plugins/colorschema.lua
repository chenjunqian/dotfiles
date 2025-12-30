return {
  {
    "ellisonleao/gruvbox.nvim",
    lazy = true,
    opts = {
      transparent_mode = true,
      styles = {
        sidebars = "transparent", -- make the sidebars (like neo-tree) transparent
        floats = "transparent", -- make floating windows transparent
      },
    },
  },
  -- Configure LazyVim to load gruvbox
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "gruvbox",
    },
  },
}
