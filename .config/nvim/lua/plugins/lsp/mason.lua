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
    -- VeryLazy, not eager: without a trigger lazy.nvim loads the plugin (and
    -- its mason.nvim dependency, ~40ms of registry setup) on every startup.
    -- swapson's own guard defers patching until mason has setup, so it only
    -- needs to be loaded before the first install, not before the first buffer.
    event = "VeryLazy",
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
