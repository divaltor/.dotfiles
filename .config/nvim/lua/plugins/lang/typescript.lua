return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}

      opts.servers.vtsls = vim.tbl_deep_extend("force", opts.servers.vtsls or {}, {
        enabled = false,
      })

      local tsgo = vim.tbl_deep_extend("force", opts.servers.tsgo or {}, {
        enabled = true,
      })
      local tsgo_on_attach = tsgo.on_attach
      tsgo.on_attach = function(client, bufnr)
        if client.name == "tsgo" and not client._tsgo_completion_guard then
          client._tsgo_completion_guard = true

          -- blink.cmp forwards trigger-character completion requests to every LSP client
          -- in the buffer. tsgo currently panics on characters it did not register, like ":".
          local request = client.request
          client.request = function(self, method, params, handler, req_bufnr)
            local trigger_character = vim.tbl_get(params, "context", "triggerCharacter")
            local trigger_characters = vim.tbl_get(self.server_capabilities, "completionProvider", "triggerCharacters")
              or {}

            if
              method == "textDocument/completion"
              and trigger_character
              and not vim.tbl_contains(trigger_characters, trigger_character)
            then
              params = vim.deepcopy(params)
              params.context.triggerKind = vim.lsp.protocol.CompletionTriggerKind.Invoked
              params.context.triggerCharacter = nil
            end

            return request(self, method, params, handler, req_bufnr)
          end
        end

        if tsgo_on_attach then
          tsgo_on_attach(client, bufnr)
        end
      end
      opts.servers.tsgo = tsgo

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
