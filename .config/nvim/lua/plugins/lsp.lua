-- @type Symbol
local SymbolKind = vim.lsp.protocol.SymbolKind

local cci_pkg = vim.fn.stdpath("data") .. "/mason/packages/circleci-yaml-language-server"
local cci_bin = cci_pkg .. "/circleci-yaml-language-server"
local cci_schema = cci_pkg .. "/schema.json"

-- CircleCI's LSP assumes every YAML in a project with a .circleci/ folder is
-- a CircleCI config and demands `version: 2.1`, giving bogus "version is
-- required" diagnostics on every other YAML. Scope the LSP to actual
-- `.circleci/config.{yml,yaml}` files via a dedicated filetype.
--
-- Register the filetype at module load time, NOT inside the lspconfig opts:
-- LazyVim lazy-loads nvim-lspconfig on BufReadPre, so opts runs after the
-- first file's filetype is already detected. Running vim.filetype.add at
-- the top of this file means it executes when lazy.nvim loads this spec
-- file during startup, before any buffer is opened.
--
-- Pattern notes:
-- - vim.filetype.add implicitly anchors user patterns with `^...$`, so the
--   pattern here omits both anchors (no double `$$`).
-- - `.*/` ensures the `.circleci` literal dot is preceded by a path
--   component, so `circleci/foo.yml` (no leading dot) doesn't match.
-- - `%.ya?ml` matches `yml` or `yaml` with literal dots.
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
