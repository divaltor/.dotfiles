return {
  {
    "catppuccin",
    opts = {
      flavour = "latte",
      integrations = {
        neotree = true,
        lsp_trouble = true,
        mason = true,
      },
    },
  },
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
      },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "rose-pine-dawn",
    },
  },
}
