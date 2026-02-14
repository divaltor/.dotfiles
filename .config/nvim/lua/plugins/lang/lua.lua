return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        lua_ls = {
          settings = {
            Lua = {
              runtime = {
                version = "LuaJIT",
              },
              diagnostics = {
                globals = { "vim", "require" },
              },
              telemetry = {
                enable = false,
              },
            },
          },
        },
      },
    },
  },
}
