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
        -- ["@property"] = { fg = "rose", italic = true },
        -- ["@attribute"] = { fg = "rose" },
        -- ["@attribute.builtin"] = { fg = "rose" },
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
