-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Center cursor when navigating
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-b>", "<C-b>zz")
vim.keymap.set("n", "<C-f>", "<C-f>zz")

-- Keep deletes in register d.
vim.keymap.set("n", "d", '"dd')
vim.keymap.set("x", "d", '"dd')

-- Use H/L for buffer navigation and <leader>` for the alternate buffer.
vim.keymap.del("n", "[b")
vim.keymap.del("n", "]b")
vim.keymap.del("n", "<leader>bb")

-- Use LSP hover instead of keywordprg.
vim.keymap.del("n", "<leader>K")

-- Disable terminal keymaps
vim.keymap.del("n", "<leader>ft")
vim.keymap.del("n", "<leader>fT")
vim.keymap.del("n", "<c-/>")
vim.keymap.del("n", "<c-_>")
vim.keymap.del("t", "<c-/>")
vim.keymap.del("t", "<c-_>")

-- Disable LazyVim changelog
vim.keymap.del("n", "<leader>L")

-- Save without formatting
vim.keymap.set("n", "<leader>S", function()
  local buf = vim.api.nvim_get_current_buf()
  local autoformat = vim.b[buf].autoformat
  vim.b[buf].autoformat = false
  local ok, err = pcall(vim.cmd.write)
  vim.b[buf].autoformat = autoformat
  if not ok then
    error(err, 0)
  end
end, { desc = "Save without formatting" })
