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
}
