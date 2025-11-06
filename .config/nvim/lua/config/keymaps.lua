-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Buffer navigation
vim.keymap.set("n", "<Tab>", ":bnext<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "<C-Tab>", ":bprevious<CR>", { desc = "Previous buffer" })

-- Line navigation
vim.keymap.set("n", "L", "$", { desc = "Go to end of line" })
vim.keymap.set("n", "H", "^", { desc = "Go to beginning of line" })
