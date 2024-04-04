-- @type Symbol
local SymbolKind = vim.lsp.protocol.SymbolKind

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      inlay_hints = {
        enabled = true,
      },
      diagnostics = {
        virtual_text = {
          prefix = "icons",
        },
      },
    },
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
}
