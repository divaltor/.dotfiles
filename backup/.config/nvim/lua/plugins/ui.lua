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
    config = function(_, opts)
      -- Adding rules from plugin
      opts.nesting_rules = require("neotree-file-nesting-config").nesting_rules
      opts.nesting_rules["pyproject.toml"] = {
        files = {
          "pyproject%.toml",
          "pdm%.lock",
          "%.pdm%.toml",
          "%.pdm-python",
          "poetry%.lock",
          "poetry%.toml",
          "setup%.py",
          "setup%.cfg",
          "MANIFEST%.in",
          "requirements*%.txt",
          "requirements*%.in",
          "requirements*%.pip",
          "tox%.ini",
          "%.flake8",
          "%.isort%.cfg",
          "%.python-version",
          "Pipfile",
          "Pipfile%.lock",
          "tox%.ini",
          "%.flake8",
          "%.isort%.cfg",
          "%.python-version",
          "hatch%.toml",
          "%.editorconfig",
          "%.flake8",
          "%.isort%.cfg",
          "%.python-version",
          "%.commitlint*",
          "%.dlint%.json",
          "%.dprint%.json*",
          "%.eslint*",
          "%.flowconfig",
          "%.jslint*",
          "%.lintstagedrc*",
          "%.markdownlint*",
          "%.prettier*",
          "%.pylintrc",
          "%.ruff%.toml",
          "%.stylelint*",
          "%.textlint*",
          "%.xo-config*",
          "%.yamllint*",
          "biome%.json",
          "commitlint*",
          "dangerfile*",
          "dlint%.json",
          "dprint%.json*",
          "eslint*",
          "lint-staged*",
          "phpcs%.xml",
          "prettier*",
          "pyrightconfig%.json",
          "ruff%.toml",
          "stylelint*",
          "tslint*",
          "xo%.config%.*",
        },
        pattern = "pyproject%.toml$",
      }
      require("neo-tree").setup(opts)
    end,
  },
}
