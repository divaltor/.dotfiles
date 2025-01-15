return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        formatters = {
          file = {
            filename_first = true,
          },
        },
        sources = {
          files = {
            hidden = true,
            follow = true,
          },
          grep = {
            glob = { "workflow/**" },
            follow = true,
          },
        },
      },
    },
  },
}
