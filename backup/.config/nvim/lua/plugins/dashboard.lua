return {
  {
    "nvimdev/dashboard-nvim",
    opts = function(_, opts)
      local logo = [[
            _______   ________   ______   _______    ______   ______  _______  
          /       \ /        | /      \ /       \  /      \ /      |/       \ 
          $$$$$$$  |$$$$$$$$/ /$$$$$$  |$$$$$$$  |/$$$$$$  |$$$$$$/ $$$$$$$  |
          $$ |  $$ |$$ |__    $$ \__$$/ $$ |__$$ |$$ |__$$ |  $$ |  $$ |__$$ |
          $$ |  $$ |$$    |   $$      \ $$    $$/ $$    $$ |  $$ |  $$    $$< 
          $$ |  $$ |$$$$$/     $$$$$$  |$$$$$$$/  $$$$$$$$ |  $$ |  $$$$$$$  |
          $$ |__$$ |$$ |_____ /  \__$$ |$$ |      $$ |  $$ | _$$ |_ $$ |  $$ |
          $$    $$/ $$       |$$    $$/ $$ |      $$ |  $$ |/ $$   |$$ |  $$ |
          $$$$$$$/  $$$$$$$$/  $$$$$$/  $$/       $$/   $$/ $$$$$$/ $$/   $$/ 
      ]]

      logo = string.rep("\n", 8) .. logo .. "\n\n"

      opts.config = {
        header = vim.split(logo, "\n"),
        -- stylua: ignore
        center = {
          { action = "Telescope find_files",                                     desc = " Find file",       icon = " ", key = "f" },
          { action = "Telescope oldfiles",                                       desc = " Recent files",    icon = " ", key = "r" },
          { action = "Telescope live_grep",                                      desc = " Find text",       icon = " ", key = "g" },
          { action = [[lua require("lazyvim.util").telescope.config_files()()]], desc = " Config",          icon = " ", key = "c" },
          { action = 'lua require("persistence").load()',                        desc = " Restore Session", icon = " ", key = "s" },
          { action = "LazyExtras",                                               desc = " Lazy Extras",     icon = " ", key = "x" },
          { action = "Lazy",                                                     desc = " Lazy",            icon = "󰒲 ", key = "l" },
          { action = "qa",                                                       desc = " Quit",            icon = " ", key = "q" },
        },
        footer = function()
          local stats = require("lazy").stats()
          local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
          return { "⚡ Neovim loaded " .. stats.loaded .. "/" .. stats.count .. " plugins in " .. ms .. "ms" }
        end,
      }

      for _, button in ipairs(opts.config.center) do
        button.desc = button.desc .. string.rep(" ", 43 - #button.desc)
        button.key_format = "  %s"
      end

      return opts
    end,
  },
}
