return {
  {
    "Wansmer/sibling-swap.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    vscode = true,
    keys = {
      {
        "<leader>sh",
        function()
          require("sibling-swap").swap_with_left()
        end,
        desc = "Swap with left",
      },
      {
        "<leader>sl",
        function()
          require("sibling-swap").swap_with_right()
        end,
        desc = "Swap with right",
      },
      {
        "<leader>s<",
        function()
          require("sibling-swap").swap_with_left_with_opp()
        end,
        desc = "Swap with left with operator",
      },
      {
        "<leader>s>",
        function()
          require("sibling-swap").swap_with_right_with_opp()
        end,
        desc = "Swap with right with operator",
      },
    },
    opts = {
      use_default_keymap = false,
    },
  },
  {
    "nvim-mini/mini.splitjoin",
    event = "LazyFile",
    opts = {},
    vscode = true,
  },
  {
    "folke/flash.nvim",
    vscode = true,
  },
  {
    "nvim-mini/mini.move",
    vscode = true,
    opts = function(opts)
      if vim.g.vscode then
        return {
          mappings = {
            left = "˙",
            right = "¬",
            down = "∆",
            up = "˚",

            line_left = "˙",
            line_right = "¬",
            line_down = "∆",
            line_up = "˚",
          },
          options = {
            reindent_linewise = true,
          },
        }
      end

      return opts
    end,
  },
}
