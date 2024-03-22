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
    config = function(_, opts)
      require("symbol-usage").setup(opts)
    end,
    opts = function()
      local function h(name)
        return vim.api.nvim_get_hl(0, { name = name })
      end

      -- hl-groups can have any name
      vim.api.nvim_set_hl(0, "SymbolUsageRounding", { fg = h("CursorLine").bg, italic = true })
      vim.api.nvim_set_hl(0, "SymbolUsageContent", { bg = h("CursorLine").bg, fg = h("Comment").fg, italic = true })
      vim.api.nvim_set_hl(0, "SymbolUsageRef", { fg = h("Function").fg, bg = h("CursorLine").bg, italic = true })
      vim.api.nvim_set_hl(0, "SymbolUsageDef", { fg = h("Type").fg, bg = h("CursorLine").bg, italic = true })
      vim.api.nvim_set_hl(0, "SymbolUsageImpl", { fg = h("@keyword").fg, bg = h("CursorLine").bg, italic = true })

      local function text_format(symbol)
        local res = {}

        local round_start = { "", "SymbolUsageRounding" }
        local round_end = { "", "SymbolUsageRounding" }

        if symbol.references then
          local usage = symbol.references <= 1 and "usage" or "usages"
          local num = symbol.references == 0 and "no" or symbol.references
          table.insert(res, round_start)
          table.insert(res, { "󰌹 ", "SymbolUsageRef" })
          table.insert(res, { ("%s %s"):format(num, usage), "SymbolUsageContent" })
          table.insert(res, round_end)
        end

        if symbol.definition then
          if #res > 0 then
            table.insert(res, { " ", "NonText" })
          end
          table.insert(res, round_start)
          table.insert(res, { "󰳽 ", "SymbolUsageDef" })
          table.insert(res, { symbol.definition .. " defs", "SymbolUsageContent" })
          table.insert(res, round_end)
        end

        if symbol.implementation then
          if #res > 0 then
            table.insert(res, { " ", "NonText" })
          end
          table.insert(res, round_start)
          table.insert(res, { "󰡱 ", "SymbolUsageImpl" })
          table.insert(res, { symbol.implementation .. " impls", "SymbolUsageContent" })
          table.insert(res, round_end)
        end

        return res
      end

      return {
        implementation = { enabled = true },
        text_format = text_format,
        disable = {
          lsp = { "pyright", "basedpyright", "tsserver", "rust-analyzer", "lua_ls" },
          filetypes = { "dockerfile" },
        },
      }
    end,
  },
  {
    "folke/trouble.nvim",
    keys = {
      { "<leader>xL", false },
      { "<leader>xQ", false },
    },
  },
}
