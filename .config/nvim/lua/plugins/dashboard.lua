return {
  {
    "folke/snacks.nvim",
    opts = {
      dashboard = {
        preset = {
          -- stylua: ignore
          keys = {
            { icon = "󰈞 ", key = "f", desc = "Find File", action = function() require("fff").find_in_git_root() end },
            { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
            { icon = " ", key = "r", desc = "Recent Files", action = function() Snacks.picker.recent() end },
            { icon = " ", key = "g", desc = "Find Text", action = function() require("fff").live_grep() end },
            { icon = " ", key = "c", desc = "Config", action = function() require("fff").find_files_in_dir(vim.fn.stdpath("config")) end },
            { icon = " ", key = "s", desc = "Restore Session", action = function() require("persistence").load() end },
            { icon = " ", key = "x", desc = "Lazy Extras", action = ":LazyExtras" },
            { icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy" },
            { icon = " ", key = "q", desc = "Quit", action = ":qa" },
          },
        },
      },
    },
  },
}
