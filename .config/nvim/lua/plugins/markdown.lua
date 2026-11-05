return {
  -- marksman (the markdown LSP) indexes the whole project: in a repo with
  -- thousands of .md files (4761 in deepseek-harness) it pushes diagnostics for
  -- every document after indexing, and Neovim's handle_diagnostics creates a
  -- buffer per URI - 1635 buffers / 700MB+ Lua heap / main thread spinning at
  -- 100%. We don't need go-to-definition or link diagnostics for md here, so
  -- turn it off. Preview (<leader>cp), render-markdown, treesitter highlighting,
  -- prettier / markdownlint-cli2 / markdown-toc are all unaffected.
  {
    "neovim/nvim-lspconfig",
    opts = { servers = { marksman = { enabled = false } } },
  },

  -- markdownlint-cli2 (invoked by nvim-lint) floods writing and preview with
  -- MD013 line-length, MD033 inline-HTML, MD041 first-line-heading and other
  -- warnings/errors. Drop the markdown linter entirely; formatting
  -- (<leader>cf, prettier / markdown-toc) is unaffected.
  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      opts.linters_by_ft = opts.linters_by_ft or {}
      opts.linters_by_ft.markdown = nil
      opts.linters_by_ft["markdown.mdx"] = nil
      return opts
    end,
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
