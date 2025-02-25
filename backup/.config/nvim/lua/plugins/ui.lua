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
    "echasnovski/mini.indentscope",
    enabled = false,
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    dependencies = {
      "saifulapm/neotree-file-nesting-config",
    },
    opts = {
      -- hide_root_node = true,
      -- retain_hidden_root_indent = true,
      filesystem = {
        filtered_items = {
          show_hidden_count = false,
          never_show = {
            ".DS_Store",
          },
          always_show = { ".env", "devlog.md" },
        },
      },
      default_component_configs = {
        indent = {
          with_expanders = true,
          expander_collapsed = "",
          expander_expanded = "",
        },
      },
      window = {
        mappings = {
          ["e"] = {
            "toggle_node",
            nowait = false,
          },
        },
      },
    },
  },
  {
    "echasnovski/mini.files",
    enabled = false,
    opts = {
      options = {
        use_as_default_explorer = true,
      },
      windows = {
        preview = true,
        width_focus = 60,
        width_preview = 70,
      },
    },
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    enabled = false,
  },
  {
    "mikavilpas/yazi.nvim",
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
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        matcher = {
          frecency = true,
          cwd_bonus = true,
        },
      },
    },
  },
}
