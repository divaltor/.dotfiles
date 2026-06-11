return {
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
