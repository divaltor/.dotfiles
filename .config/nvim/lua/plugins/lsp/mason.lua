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
  -- Install Mason packages through faster tools: npm -> bun, pip -> uv.
  -- Needs upstream mason: swapson patches private modules
  -- (SystemPackage.sfw, install_extra_args) the fork doesn't have.
  {
    "Senal-D-A-Gunaratna/swapson.nvim",
    dependencies = {
      "mason-org/mason.nvim",
    },
    opts = {
      npm = {
        enabled = true,
        tool = "bun",
      },
      pip = {
        -- Replaces the fork's pip.use_uv.
        enabled = true,
        tool = "uv",
      },
    },
  },
}
