local buf_move_create = function(dir)
  return function()
    local cmd = dir == "next" and "BufferLineMoveNext" or "BufferLineMovePrev"
    local char = dir == "next" and "l" or "h"
    vim.cmd(cmd)

    local function repeat_me()
      local char_current = vim.fn.getcharstr()

      if char_current == char then
        vim.cmd(cmd)
        repeat_me()
      elseif char ~= nil then
        return
        -- vim.api.nvim_feedkeys(vim.keycode(char), "n", true)
      end
    end

    repeat_me()
  end
end

return {
  {
    "akinsho/bufferline.nvim",
    keys = {
      { "<leader>bh", buf_move_create("prev"), desc = "Move buffer (prev)" },
      { "<leader>bl", buf_move_create("next"), desc = "Move buffer (next)" },
    },
    opts = {
      options = {
        move_wraps_at_ends = true,
      },
    },
  },
  { "catppuccin", opts = { flavour = "latte" } },
  { "folke/tokyonight.nvim", enabled = false },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },
  {
    "mawkler/modicator.nvim",
    dependencies = "catppuccin", -- Add your colorscheme plugin here
    init = function()
      -- These are required for Modicator to work
      vim.o.cursorline = true
      vim.o.number = true
      vim.o.termguicolors = true
    end,
    opts = {},
  },
}
