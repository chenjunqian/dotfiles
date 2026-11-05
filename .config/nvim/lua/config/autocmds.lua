-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "html", "css", "scss", "less" },
  callback = function()
    vim.b.autoformat = true
  end,
  desc = "Enable autoformat for HTML/CSS",
})

-- Markdown: hide diagnostics (markdownlint's MD013 line-length / MD033 inline HTML
-- warnings are very noisy while writing and previewing). Re-enable temporarily with
-- :lua vim.diagnostic.enable(true).
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "markdown.mdx", "rmd", "norg", "org" },
  callback = function(ev)
    vim.diagnostic.enable(false, { bufnr = ev.buf })
  end,
  desc = "Disable diagnostics in markdown buffers",
})
