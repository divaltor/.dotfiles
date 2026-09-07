return {
  {
    "folke/flash.nvim",
    vscode = true,
  },
  {
    "nvim-mini/mini.move",
    vscode = true,
    opts = function(_, opts)
      if vim.g.vscode then
        opts.mappings = {
          left = "˙",
          right = "¬",
          down = "∆",
          up = "˚",

          line_left = "˙",
          line_right = "¬",
          line_down = "∆",
          line_up = "˚",
        }
      end

      return opts
    end,
  },
}
