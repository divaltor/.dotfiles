return {
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
