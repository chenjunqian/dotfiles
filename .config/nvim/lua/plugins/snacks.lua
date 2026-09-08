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
          -- 悬浮窗口显示
          layout = {
            preview = false, -- 不显示预览窗口
            layout = {
              box = "vertical",
              backdrop = false, -- 不遮罩背景
              -- 小于 1 表示按屏幕比例：0.8 x 0.8 ≈ 60% 屏幕面积
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
          -- 打开文件后自动关闭悬浮窗口
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
