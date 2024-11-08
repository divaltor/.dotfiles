-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Center cursor when navigating
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-b>", "<C-b>zz")
vim.keymap.set("n", "<C-f>", "<C-f>zz")

vim.keymap.set("n", "<leader>xe", function()
  vim.diagnostic.open_float()
end, { desc = "Open float window with diagnostics" })

-- Move yanked text to black hole register
-- vim.keymap.set("x", "<leader>p", )

-- Quit all without saving
vim.keymap.set("n", "<leader>qa", "<cmd>qa!<CR>", { desc = "Quit all without saving" })

-- Delete into Vim buffer
vim.keymap.set("n", "d", '"dd')
vim.keymap.set("x", "d", '"dd')

-- Remove useless mapping for buffer switching because there are already 2 shortucts with <S-H\L>
vim.keymap.del("n", "[b")
vim.keymap.del("n", "]b")
vim.keymap.del("n", "<leader>bb")

-- Useless python documentation mapping
vim.keymap.del("n", "<leader>K")

-- Disable terminal keymaps
vim.keymap.del("n", "<leader>ft")
vim.keymap.del("n", "<leader>fT")
vim.keymap.del("n", "<c-/>")
vim.keymap.del("n", "<c-_>")

-- Disable LazyVim changelog
vim.keymap.del("n", "<leader>L")

-- Disable highlight under cursor
vim.keymap.del("n", "<leader>ui")
