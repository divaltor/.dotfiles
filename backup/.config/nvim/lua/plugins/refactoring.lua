return {
  {
    "Wansmer/sibling-swap.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
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
    "echasnovski/mini.splitjoin",
    event = "LazyFile",
    opts = {},
  },
}
