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

      -- TypeScript 7 native LSP (`tsc --lsp --stdio`), replacing the
      -- deprecated tsgo extra (@typescript/native-preview). nvim-lspconfig's
      -- `tsc` config prefers <project>/node_modules/.bin/tsc and falls back
      -- to `tsc` on PATH. `tsc` has no Mason package, so it must be installed
      -- from npm (typescript@7, globally or per project).
      opts.servers.tsc = vim.tbl_deep_extend("force", opts.servers.tsc or {}, {
        filetypes = {
          "javascript",
          "javascriptreact",
          "javascript.jsx",
          "typescript",
          "typescriptreact",
          "typescript.tsx",
        },
        settings = {
          typescript = {
            inlayHints = {
              enumMemberValues = { enabled = true },
              functionLikeReturnTypes = { enabled = false },
              parameterNames = {
                enabled = "literals",
                suppressWhenArgumentMatchesName = true,
              },
              parameterTypes = { enabled = true },
              propertyDeclarationTypes = { enabled = true },
              variableTypes = { enabled = false },
            },
          },
        },
      })

      -- The typescript extra defaults to vtsls now that the tsgo extra is
      -- gone. Disable all the TS servers it knows about (vtsls also ships
      -- keymaps that target vtsls-only commands, so clear its keys too).
      for _, server in ipairs({ "tsgo", "vtsls", "ts_ls", "tsserver" }) do
        opts.servers[server] = vim.tbl_deep_extend("force", opts.servers[server] or {}, {
          enabled = false,
          keys = {},
        })
      end
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
