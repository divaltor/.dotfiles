return {
  {
    "telescope.nvim",
    dependencies = {
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "make",
      config = function()
        require("telescope").load_extension("fzf")
      end,
    },
    keys = {
      { "<leader>sp", "<cmd>Telescope pickers<CR>", desc = "Pickers" },
      { "<leader>sb", false }, -- Buffers
      { "<leader>sM", false }, -- Man pages
      { "<leader>sm", false }, -- marks
      { "<leader>sT", false }, -- TODO without FIXME and so on
      { "<leader>sH", false }, -- Treesitter highlight groups
      { "<leader>so", false }, -- vim options
      { "<leader>sh", false }, -- help pages
      { "<leader>sa", false }, -- auto commands
      { "<leader>sC", false }, -- commands
      { '<leader>s"', false }, -- registers
    },
    opts = {
      defaults = {
        layout_strategy = "vertical",
        layout_config = { prompt_position = "top", mirror = true },
        sorting_strategy = "ascending",
        winblend = 0,
      },
      pickers = {
        find_files = {
          find_command = { "rg", "--files", "-L", "--hidden", "--glob", "!**/.git/*" },
        },
        live_grep = {
          additional_args = function(_)
            return { "--hidden", "--glob", "!**/.git/*" }
          end,
        },
      },
    },
  },
}
