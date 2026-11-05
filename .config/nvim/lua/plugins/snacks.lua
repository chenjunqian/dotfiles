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
          -- Floating window layout
          layout = {
            preview = false, -- Hide the preview window
            layout = {
              box = "vertical",
              backdrop = false, -- Do not dim the background
              -- Values below 1 are screen ratios: 0.8 x 0.8 is about 60% of the screen
              width = 0.8,
              min_width = 40,
              height = 0.8,
              min_height = 15,
              border = "rounded",
              title = " Explorer ",
              title_pos = "center",
              { win = "input", height = 1, border = "bottom" },
              { win = "list", border = "none" },
            },
          },
          -- Close the floating picker after opening a file
          jump = { close = true },
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
