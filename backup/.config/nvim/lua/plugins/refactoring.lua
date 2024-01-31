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
}
