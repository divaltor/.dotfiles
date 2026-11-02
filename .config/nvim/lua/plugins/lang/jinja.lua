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
    "mason-org/mason.nvim",
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
    -- Its plugin/ file only registers a FileType autocmd for `j2`; nothing is
    -- needed at startup, so let the first jinja buffer load it.
    ft = { "jinja", "sql.jinja", "j2" },
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
