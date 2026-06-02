-- @type Symbol
local SymbolKind = vim.lsp.protocol.SymbolKind

local cci_pkg = vim.fn.stdpath("data") .. "/mason/packages/circleci-yaml-language-server"
local cci_bin = cci_pkg .. "/circleci-yaml-language-server"
local cci_schema = cci_pkg .. "/schema.json"

-- cci-language-server assumes every YAML in a project with a .circleci/
-- is a CircleCI config and demands `version: 2.1`, giving bogus errors on
-- every other YAML. Scope it to `.circleci/config.{yml,yaml}` via a
-- dedicated filetype. Registered here, not inside the lspconfig opts,
-- because LazyVim lazy-loads nvim-lspconfig on BufReadPre — opts would
-- run after the first file's filetype is already detected.
vim.filetype.add({
  pattern = {
    [".*/%.circleci/config%.ya?ml"] = "yaml.circleci",
  },
})

return {
  {
    "mason-org/mason.nvim",
    opts_extend = { "ensure_installed" },
    opts = {
      ensure_installed = {
        "circleci-yaml-language-server",
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      -- `opts` is mutated in place rather than replaced: lazy.nvim's _values
      -- uses the function's return value as-is, so returning a fresh table
      -- would drop LazyVim's defaults (folds, codelens, format, etc.) and
      -- break downstream code that reads opts.folds.enabled and similar.
      opts.servers = opts.servers or {}
      opts.servers["circleci-yaml-language-server"] = {
        cmd = { cci_bin, "-stdio", "-schema", cci_schema },
        filetypes = { "yaml.circleci" },
        root_dir = function(bufnr, on_dir)
          on_dir(vim.fs.root(bufnr, { ".circleci" }))
        end,
      }
      -- Add yaml.cloudformation to yamlls's filetypes. The full list is
      -- redeclared because lspconfig's tbl_deep_extend("keep", user,
      -- default) replaces arrays wholesale — list_extending into nil at
      -- opts-eval time would clobber the LazyVim defaults.
      opts.servers.yamlls = opts.servers.yamlls or {}
      opts.servers.yamlls.filetypes = {
        "yaml",
        "yaml.docker-compose",
        "yaml.gitlab",
        "yaml.helm-values",
        "yaml.cloudformation",
      }
      -- CFN intrinsic-function short tags. customTags is parser-level,
      -- runs before the schema — the goformation schema only describes
      -- the JSON form ({"Ref": ...}), so without this yamlls reports
      -- "Unresolved tag" on every !Ref / !Sub / !GetAtt. Safe globally:
      -- none appear in vanilla YAML 1.2.
      local cfn_intrinsics = {
        "!Ref", "!Sub", "!If", "!Not", "!Equals", "!Join", "!Split",
        "!FindInMap", "!Base64", "!Cidr", "!And", "!Or", "!ImportValue",
        "!Select", "!GetAtt", "!Transform", "!Condition",
      }
      opts.servers.yamlls.settings = opts.servers.yamlls.settings or {}
      opts.servers.yamlls.settings.yaml = opts.servers.yamlls.settings.yaml or {}
      opts.servers.yamlls.settings.yaml.customTags = vim.list_extend(
        opts.servers.yamlls.settings.yaml.customTags or {},
        cfn_intrinsics
      )
      -- Attach the goformation CFN schema, scoped to project CFN
      -- directories so it doesn't validate CircleCI orbs / docker-compose
      -- / etc. against CFN's top-level shape. Done in before_init rather
      -- than opts because LazyVim's default before_init runs after our
      -- opts and does
      --   tbl_deep_extend("force", settings.schemas, require("schemastore").yaml.schemas())
      -- with "force" the SchemaStore side wins, clobbering anything we
      -- set in opts. (customTags above doesn't have this problem —
      -- SchemaStore doesn't touch it.)
      local cfn_url = "https://raw.githubusercontent.com/awslabs/goformation/master/schema/cloudformation.schema.json"
      local cfn_project_globs = {
        "**/cloudformation/**",
      }
      opts.servers.yamlls.before_init = function(_, new_config)
        new_config.settings.yaml.schemas = vim.tbl_deep_extend(
          "force",
          new_config.settings.yaml.schemas or {},
          require("schemastore").yaml.schemas()
        )
        local existing = new_config.settings.yaml.schemas[cfn_url] or {}
        local seen = {}
        for _, g in ipairs(existing) do
          seen[g] = true
        end
        for _, g in ipairs(cfn_project_globs) do
          if not seen[g] then
            table.insert(existing, g)
            seen[g] = true
          end
        end
        new_config.settings.yaml.schemas[cfn_url] = existing
      end
      return opts
    end,
  },
  {
    "Wansmer/symbol-usage.nvim",
    event = "LspAttach",
    opts = function()
      local function h(name)
        return vim.api.nvim_get_hl(0, { name = name })
      end

      -- hl-groups can have any name
      vim.api.nvim_set_hl(0, "SymbolUsageRounding", { fg = h("CursorLine").bg, italic = true })
      vim.api.nvim_set_hl(0, "SymbolUsageContent", { fg = h("Comment").fg, italic = true })
      vim.api.nvim_set_hl(0, "SymbolUsageRef", { fg = h("Function").fg, italic = true })
      vim.api.nvim_set_hl(0, "SymbolUsageDef", { fg = h("Type").fg, italic = true })
      vim.api.nvim_set_hl(0, "SymbolUsageImpl", { fg = h("@keyword").fg, italic = true })

      local function text_format(symbol)
        local res = {}

        if symbol.references then
          local usage = symbol.references <= 1 and "usage" or "usages"
          local num = symbol.references == 0 and "no" or symbol.references
          table.insert(res, { "󰌹 ", "SymbolUsageRef" })
          table.insert(res, { ("%s %s"):format(num, usage), "SymbolUsageContent" })
        end

        if symbol.definition ~= nil and symbol.definition > 0 then
          if #res > 0 then
            table.insert(res, { ", ", "NonText" })
          end
          table.insert(res, { "󰳽 ", "SymbolUsageDef" })
          table.insert(res, { symbol.definition .. " defs", "SymbolUsageContent" })
        end

        if symbol.implementation ~= nil and symbol.implementation > 0 then
          if #res > 0 then
            table.insert(res, { ", ", "NonText" })
          end
          table.insert(res, { "󰡱 ", "SymbolUsageImpl" })
          table.insert(res, { symbol.implementation .. " impls", "SymbolUsageContent" })
        end

        return res
      end

      return {
        implementation = { enabled = true },
        text_format = text_format,
        disable = {
          lsp = { "pyright", "basedpyright" },
          filetypes = { "dockerfile" },
        },
        hl = { link = "GitSignsCurrentLineBlame" },
        filetypes = {
          rust = {
            kinds = {
              SymbolKind.Function,
              SymbolKind.Method,
              SymbolKind.Class,
              SymbolKind.Interface,
              SymbolKind.Enum,
              SymbolKind.Struct,
            },
          },
        },
      }
    end,
  },
  {
    "folke/trouble.nvim",
    keys = {
      { "<leader>xL", false }, -- Location list
      { "<leader>xQ", false }, -- Quickfix list
      { "<leader>xl", false }, -- Lsp references
      { "<leader>xq", false }, -- Lsp diagnostics
    },
  },
  {
    "luozhiya/lsp-virtual-improved.nvim",
    event = { "LspAttach" },
    opts = {},
  },
  {
    "divaltor/lsp_lines.nvim",
    event = { "LspAttach" },
    opts = {},
    branch = "cursor-hold",
  },
}
