local cfn_lsp_extra_pkg = vim.fn.stdpath("data") .. "/mason/packages/cfn-lsp-extra"
local cfn_lsp_extra_bin = cfn_lsp_extra_pkg .. "/venv/bin/cfn-lsp-extra"

return {
  -- Register the custom Mason registry so cfn-lsp-extra (not in the
  -- official mason-org/mason-registry) becomes a first-class Mason package:
  -- ensure_installed, :MasonInstall, :Mason, etc. all work on it.
  -- The default github registry is listed first so packages there keep
  -- winning on name conflicts.
  {
    "KingMichaelPark/mason.nvim",
    opts = function(_, opts)
      opts.registries = opts.registries or { "github:mason-org/mason-registry" }
      table.insert(opts.registries, "lua:mason-custom-registry")
      return opts
    end,
  },
  {
    "KingMichaelPark/mason.nvim",
    opts_extend = { "ensure_installed" },
    opts = {
      ensure_installed = { "cfn-lint", "cfn-lsp-extra" },
    },
  },
  -- LSP: hover, completion, goto-definition, diagnostics (via cfn-lint).
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        cfn_lsp = {
          cmd = { cfn_lsp_extra_bin },
          filetypes = { "yaml.cloudformation", "json.cloudformation" },
          root_markers = { ".git" },
          settings = {
            ["cfn-lsp-extra"] = {
              documentFormatting = false,
            },
          },
        },
      },
    },
  },
}
