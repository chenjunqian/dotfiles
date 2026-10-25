return {
  -- marksman（markdown LSP）会索引整个工程：在含数千个 md 的仓库里（如
  -- deepseek-harness，4761 个 md）它索引完后会为每个文档推一份诊断，Neovim 的
  -- handle_diagnostics 会给每个 URI 建 buffer，导致 1635 个 buffer / 700MB+
  -- Lua 堆 / 主线程 100% 空转卡死。这里不需要 md 的跳转与链接诊断，直接关掉。
  -- 预览（<leader>cp）、render-markdown 渲染、treesitter 高亮、prettier /
  -- markdownlint-cli2 / markdown-toc 均不受影响。
  {
    "neovim/nvim-lspconfig",
    opts = { servers = { marksman = { enabled = false } } },
  },

  {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = {
      code = {
        sign = false,
        width = "block",
        right_pad = 1,
      },
      heading = {
        sign = true,
        icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
      },
      checkbox = {
        enabled = true,
      },
      pipe_table = {
        enabled = true,
        style = "full",
        -- Wrap wide tables across multiple lines instead of letting Neovim
        -- soft-wrap the row and break the table borders (requires nvim 0.11+,
        -- conceal level 2/3 and tables with pipes on both sides).
        wrap = true,
      },
      callout = {
        note = { raw = "[!NOTE]", rendered = "󰋽 Note", highlight = "RenderMarkdownInfo" },
        tip = { raw = "[!TIP]", rendered = "󰌶 Tip", highlight = "RenderMarkdownSuccess" },
        important = { raw = "[!IMPORTANT]", rendered = "󰅾 Important", highlight = "RenderMarkdownHint" },
        warning = { raw = "[!WARNING]", rendered = "󰀪 Warning", highlight = "RenderMarkdownWarn" },
        caution = { raw = "[!CAUTION]", rendered = "󰳦 Caution", highlight = "RenderMarkdownError" },
      },
    },
    ft = { "markdown", "norg", "rmd", "org", "codecompanion" },
  },
}
