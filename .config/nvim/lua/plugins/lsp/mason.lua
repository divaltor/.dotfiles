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
}
