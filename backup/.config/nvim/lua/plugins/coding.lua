return {
  {
    "Saghen/blink.cmp",
    opts = {
      keymap = {
        preset = "super-tab",
        ["<CR>"] = { "accept", "fallback" },
      },
    },
  },
  {
    "pteroctopus/faster.nvim",
  },
  {
    "snacks.nvim",
    opts = {
      bigfile = { enabled = false },
    },
  },
}
