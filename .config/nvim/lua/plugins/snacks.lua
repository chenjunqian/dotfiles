return {
  "folke/snacks.nvim",
  opts = {
    explorer = {
      hidden = true,
    },
    picker = {
      sources = {
        explorer = {
          hidden = true,
          ignored = true,
          watch = true,
          git_status = true,
          git_status_open = true,
          git_untracked = true,
          follow_file = true,
        },
      },
    },
    image = {
      -- your image configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    },
  },
}
