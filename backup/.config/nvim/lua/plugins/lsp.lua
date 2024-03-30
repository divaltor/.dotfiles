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
    event = "BufReadPre",
    opts = function(_, opts)
      opts.vt_position = "end_of_line"
      opts.request_pending_text = "symbol"
      opts.hl = { link = "GitSignsCurrentLineBlame" }
      opts.text_format = function(symbol)
        local text = require("symbol-usage.options")._default_opts.text_format(symbol)

        return "󰌹 " .. text
      end
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
