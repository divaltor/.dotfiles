return {
  {
    "folke/which-key.nvim",
    opts = {
      defaults = {
        ["<leader>r"] = { name = "+refactoring" },
      },
    },
  },
  {
    "ThePrimeagen/refactoring.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    event = "BufRead",
    keys = {
      {
        "<leader>rr",
        function()
          require("refactoring").select_refactor()
        end,
        desc = "Select refactoring",
      },
    },
    config = function(opts, _)
      require("refactoring").setup(opts)
    end,
  },
  {
    "Wansmer/sibling-swap.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function(_, opts)
      require("sibling-swap").setup(opts)
    end,
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
}
