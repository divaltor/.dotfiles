-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Center cursor when navigating
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-b>", "<C-b>zz")
vim.keymap.set("n", "<C-f>", "<C-f>zz")

-- Move yanked text to black hole register
-- vim.keymap.set("x", "<leader>p", '"_dP')

-- Delete to black hole register
vim.keymap.set("n", "<leader>D", '"_d', { desc = "Delete to black hole register" })
vim.keymap.set("v", "<leader>D", '"_d', { desc = "Delete to black hole register" })

-- Quit all without saving
vim.keymap.set("n", "<leader>qa", "<cmd>qa!<CR>", { desc = "Quit all without saving" })

-- Remove useless mapping for buffer switching because there are already 2 shortucts with <S-H\L>
vim.keymap.del("n", "[b")
vim.keymap.del("n", "]b")
vim.keymap.del("n", "<leader>bb")

-- Tabbing visual blocks
vim.keymap.set("v", "<Tab>", ">gv")
vim.keymap.set("v", "<S-Tab>", "<gv")

-- Useless python documentation mapping
vim.keymap.del("n", "<leader>K")

-- Disable terminal keymaps
vim.keymap.del("n", "<leader>ft")
vim.keymap.del("n", "<leader>fT")
vim.keymap.del("n", "<c-/>")
vim.keymap.del("n", "<c-_>")

vim.keymap.del("t", "<esc><esc>")
vim.keymap.del("t", "<C-h>")
vim.keymap.del("t", "<C-j>")
vim.keymap.del("t", "<C-k>")
vim.keymap.del("t", "<C-l>")
vim.keymap.del("t", "<C-/>")
vim.keymap.del("t", "<C-_>")

-- Disable LazyVim changelog
vim.keymap.del("n", "<leader>L")

-- Disable highlight under cursor
vim.keymap.del("n", "<leader>ui")
