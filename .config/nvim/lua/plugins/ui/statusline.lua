return {
  {
    "akinsho/bufferline.nvim",
    opts = {
      options = {
        move_wraps_at_ends = true,
      },
    },
  },
  {
    "folke/which-key.nvim",
    opts = {
      preset = "helix",
      delay = 0,
      plugins = {
        spelling = {
          enabled = false,
        },
      },
      icons = {
        colors = false,
        rules = false,
        separator = "",
        mappings = false,
      },
      show_help = false,
    },
  },
  {
    "nvim-mini/mini.indentscope",
    enabled = false,
  },
}
