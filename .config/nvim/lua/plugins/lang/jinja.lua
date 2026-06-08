vim.filetype.add({
  extension = {
    j2 = "jinja",
    jinja = "jinja",
    jinja2 = "jinja",
  },
  pattern = {
    [".*%.sql%.j2"] = "sql.jinja",
  },
})

return {
  {
    "KingMichaelPark/mason.nvim",
    opts_extend = { "ensure_installed" },
    opts = {
      ensure_installed = { "jinja-lsp" },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        jinja_lsp = {
          filetypes = { "jinja", "sql.jinja" },
        },
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = { "jinja", "sql" },
    },
  },
  {
    "cathaysia/nvim-jinja",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("nvim-jinja").setup({
        enabled = true,
        debug = false,
        filetypes = {
          extensions = {
            ["sql.j2"] = "sql",
          },
        },
        auto_install_parsers = false,
      })
    end,
  },
}
