local cfn_lsp_extra_pkg = vim.fn.stdpath("data") .. "/mason/packages/cfn-lsp-extra"
local cfn_lsp_extra_bin = cfn_lsp_extra_pkg .. "/venv/bin/cfn-lsp-extra"

return {
  -- Register the custom Mason registry so cfn-lsp-extra (not in the
  -- official mason-org/mason-registry) becomes a first-class Mason package:
  -- ensure_installed, :MasonInstall, :Mason, etc. all work on it.
  -- The default github registry is listed first so packages there keep
  -- winning on name conflicts.
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.registries = opts.registries or { "github:mason-org/mason-registry" }
      table.insert(opts.registries, "lua:mason-custom-registry")
      return opts
    end,
  },
  {
    "mason-org/mason.nvim",
    opts_extend = { "ensure_installed" },
    opts = {
      ensure_installed = { "cfn-lint", "cfn-lsp-extra" },
    },
  },
  -- Detect CloudFormation templates by their first lines so cfn-lint and
  -- cfn-lsp-extra only attach to actual CFN files, not every yaml/json.
  {
    "neovim/nvim-lspconfig",
    opts = function()
      local function is_cfn_yaml(l1)
        if not l1 then
          return false
        end
        return l1:match("^AWSTemplateFormatVersion") ~= nil
          or l1:match("^AWS::Serverless") ~= nil
      end
      local function is_cfn_json(l1, l2)
        for _, l in ipairs({ l1, l2 }) do
          if l and l:match([[^%s*["']AWSTemplateFormatVersion["']%s*:%s*]]) then
            return true
          end
          if l and l:match([[^%s*["']Transform["']%s*:%s*["']AWS::Serverless]]) then
            return true
          end
        end
        return false
      end
      vim.filetype.add({
        pattern = {
          [".*"] = {
            priority = math.huge,
            function(_, bufnr)
              local lines = vim.api.nvim_buf_get_lines(bufnr, 0, 2, false)
              local l1, l2 = lines[1], lines[2]
              if is_cfn_yaml(l1) then
                return "yaml.cloudformation"
              elseif is_cfn_json(l1, l2) then
                return "json.cloudformation"
              end
            end,
          },
        },
      })
    end,
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
  -- Linter: run cfn-lint directly on save/insert-leave as a backup
  -- diagnostics source and for ad-hoc :lua require("lint").try_lint() use.
  {
    "nvim-lint",
    opts = {
      linters_by_ft = {
        ["yaml.cloudformation"] = { "cfn_lint" },
        ["json.cloudformation"] = { "cfn_lint" },
      },
      linters = {
        cfn_lint = {
          cmd = "cfn-lint",
          stdin = false,
          args = { "--format", "json" },
          stream = "stdout",
          ignore_exitcode = true,
        },
      },
    },
  },
}
