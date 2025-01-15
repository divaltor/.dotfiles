return {
  {
    "rose-pine/neovim",
    name = "rose-pine",
    opts = {
      styles = {
        italic = false,
      },
      highlight_groups = {
        EndOfBuffer = { fg = "base" },
        Constant = { fg = "rose" },
        Number = { fg = "rose" },
        ["@variable.member"] = { fg = "text" },
        ["@constant"] = { fg = "foam" },
        ["@constant.builtin"] = { fg = "rose", bold = true },
        ["@constant.macro"] = { fg = "foam" },
        CurSearch = { fg = "base", bg = "leaf", inherit = false },
        Search = { fg = "text", bg = "leaf", blend = 20, inherit = false },
      },
    },
  },
  { "folke/tokyonight.nvim", enabled = false },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "rose-pine-dawn",
    },
  },
}
