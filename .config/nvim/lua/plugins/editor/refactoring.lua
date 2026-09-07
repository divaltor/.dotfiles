return {
  {
    "Wansmer/sibling-swap.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    vscode = true,
    keys = {
      {
        "<leader>c<",
        function()
          require("sibling-swap").swap_with_left()
        end,
        desc = "Swap with left",
      },
      {
        "<leader>c>",
        function()
          require("sibling-swap").swap_with_right()
        end,
        desc = "Swap with right",
      },
      {
        "<leader>c,",
        function()
          require("sibling-swap").swap_with_left_with_opp()
        end,
        desc = "Swap with left with operator",
      },
      {
        "<leader>c.",
        function()
          require("sibling-swap").swap_with_right_with_opp()
        end,
        desc = "Swap with right with operator",
      },
    },
    opts = {
      use_default_keymaps = false,
    },
  },
  {
    "nvim-mini/mini.splitjoin",
    event = "LazyFile",
    opts = {},
    vscode = true,
  },
}
