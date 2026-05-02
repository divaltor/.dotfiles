return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}

      opts.servers.oxlint = vim.tbl_deep_extend("force", opts.servers.oxlint or {}, {
        root_markers = {
          ".oxlintrc.json",
          "oxlint.config.ts",
          "package.json",
          ".git",
        },
      })
    end,
  },
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters = opts.formatters or {}
      opts.formatters.biome = vim.tbl_deep_extend("force", opts.formatters.biome or {}, {
        require_cwd = true,
      })
      opts.formatters.oxfmt = vim.tbl_deep_extend("force", opts.formatters.oxfmt or {}, {
        require_cwd = true,
      })

      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft.javascript = { "biome", "oxfmt", stop_after_first = true }
      opts.formatters_by_ft.javascriptreact = { "biome", "oxfmt", stop_after_first = true }
      opts.formatters_by_ft.typescript = { "biome", "oxfmt", stop_after_first = true }
      opts.formatters_by_ft.typescriptreact = { "biome", "oxfmt", stop_after_first = true }
      opts.formatters_by_ft.json = { "biome", "oxfmt", stop_after_first = true }
      opts.formatters_by_ft.vue = { "biome", "oxfmt", stop_after_first = true }
    end,
  },
}
