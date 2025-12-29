-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Buffer navigation
vim.keymap.set("n", "<Tab>", ":bnext<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "<S-Tab>", ":bprevious<CR>", { desc = "Previous buffer" })

vim.keymap.set("n", "<C-\\>", function() Snacks.terminal()
end, { desc = "Terminal (Root Dir)" })
vim.keymap.set("t", "<C-\\>", "<cmd>close<cr>", { desc = "Hide Terminal" })
vim.keymap.set("n", "L", "$", { desc = "Go to end of line" })
vim.keymap.set("n", "H", "^", { desc = "Go to beginning of line" })
