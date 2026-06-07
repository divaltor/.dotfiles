-- @type Symbol
local SymbolKind = vim.lsp.protocol.SymbolKind

local cci_pkg = vim.fn.stdpath("data") .. "/mason/packages/circleci-yaml-language-server"
local cci_bin = cci_pkg .. "/circleci-yaml-language-server"
local cci_schema = cci_pkg .. "/schema.json"

local function has_cfn_marker(_, bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, 200, false)
  for _, line in ipairs(lines) do
    if line:find("AWSTemplateFormatVersion", 1, true) then
      return true
    end
  end
  return false
end

local function is_circleci_orb_source(path)
  local dir = vim.fs.dirname(path)
  return #vim.fs.find({ "@orb.yml", "@orb.yaml" }, { path = dir, upward = true }) > 0
end

local function is_packed_circleci_orb(path, bufnr)
  local name = vim.fs.basename(path)
  if name ~= "@orb.yml" and name ~= "@orb.yaml" and name ~= "orb.yml" and name ~= "orb.yaml" then
    return false
  end

  local has_version = false
  local has_orb_section = false
  local orb_sections = {
    description = true,
    display = true,
    orbs = true,
    commands = true,
    jobs = true,
    executors = true,
    examples = true,
  }
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, 40, false)
  for _, line in ipairs(lines) do
    if line:match("^%s*version:%s*2%.1%s*$") then
      has_version = true
    else
      local section = line:match("^%s*([%w_-]+):")
      has_orb_section = has_orb_section or orb_sections[section] == true
    end
  end

  return has_version and has_orb_section
end

local function yaml_filetype(path, bufnr)
  if path:match("[/\\]%.circleci[/\\]config.*%.yml$") or path:match("[/\\]%.circleci[/\\]config.*%.yaml$") then
    return "yaml.circleci"
  elseif path:match("[/\\]%.circleci[/\\].*%.yml$")
    or path:match("[/\\]%.circleci[/\\].*%.yaml$")
    or is_circleci_orb_source(path)
    or is_packed_circleci_orb(path, bufnr)
  then
    return "yaml.circleci-orb"
  elseif has_cfn_marker(path, bufnr) then
    return "yaml.cloudformation"
  end
end

-- Registered here, not inside lspconfig opts, because LazyVim lazy-loads
-- nvim-lspconfig on BufReadPre — opts would run after the first file's
-- filetype is already detected.
vim.filetype.add({
  pattern = {
    [".*%.yml"] = yaml_filetype,
    [".*%.yaml"] = yaml_filetype,
    [".*%.json"] = {
      priority = -math.huge,
      function(path, bufnr)
        if has_cfn_marker(path, bufnr) then
          return "json.cloudformation"
        end
      end,
    },
  },
})

return {
  {
    "KingMichaelPark/mason.nvim",
    opts_extend = { "ensure_installed" },
    opts = {
      ensure_installed = {
        "circleci-yaml-language-server",
      },
      pip = {
        use_uv = true,
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
        root_markers = { ".circleci", ".git" },
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
        "yaml.circleci-orb",
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
          filetypes = { "dockerfile", "yaml.circleci-orb" },
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
    init = function()
      vim.tbl_islist = vim.tbl_islist or vim.islist
    end,
    opts = {},
  },
  {
    "divaltor/lsp_lines.nvim",
    event = { "LspAttach" },
    opts = {},
    branch = "cursor-hold",
  },
}
