return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    enabled = false,
  },
  {
    "nvim-mini/mini.files",
    enabled = false,
  },
  {
    "mikavilpas/yazi.nvim",
    lazy = false,
    keys = {
      {
        "<leader>fm",
        mode = { "n", "v" },
        "<cmd>Yazi<cr>",
        desc = "Open yazi at the current file",
      },
      {
        "<leader>fM",
        "<cmd>Yazi cwd<cr>",
        desc = "Open the file manager in nvim's working directory",
      },
      {
        "<c-->",
        "<cmd>Yazi toggle<cr>",
        desc = "Resume the last yazi session",
      },
    },
    opts = {
      floating_window_scaling_factor = {
        width = 0.95,
        height = 0.95,
      },
      open_multiple_tabs = true,
      open_for_directories = true,
      integrations = {
        grep_in_directory = "snacks.picker",
        grep_in_selected_files = "snacks.picker",
      },
    },
  },
}
