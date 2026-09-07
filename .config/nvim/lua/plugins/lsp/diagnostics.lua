return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      diagnostics = {
        virtual_text = false,
        virtual_improved = true,
      },
    },
  },
  {
    "folke/trouble.nvim",
    keys = {
      { "<leader>xL", false }, -- Location list
      { "<leader>xQ", false }, -- Quickfix list
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
