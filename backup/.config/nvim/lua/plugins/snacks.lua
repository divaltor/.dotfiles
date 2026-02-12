return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        formatters = {
          file = {
            filename_first = true,
          },
        },
        sources = {
          files = {
            hidden = true,
            follow = true,
          },
        },
      },
    },
    keys = {
      -- Disable snacks file-finding keys (replaced by fff.nvim)
      { "<leader><space>", false },
      { "<leader>ff", false },
      { "<leader>fF", false },
      { "<leader>fg", false },
    },
  },
  {
    "dmtrKovalenko/fff.nvim",
    build = function()
      require("fff.download").download_or_build_binary()
    end,
    lazy = false,
    opts = {
      layout = {
        prompt_position = "top",
      },
      max_threads = 10,
      prompt = "λ ",
      hl = {
        border = "FFFBorder",
        normal = "FFFNormal",
        cursor = "FFFCursor",
        matched = "FFFMatched",
        title = "FFFTitle",
        prompt = "FFFPrompt",
        active_file = "FFFActiveFile",
        frecency = "FFFFrequency",
        debug = "FFFDebug",
        combo_header = "FFFComboHeader",
        scrollbar = "FFFScrollbar",
        directory_path = "FFFDirectoryPath",
      },
    },
    keys = {
      {
        "<leader><space>",
        function()
          require("fff").find_in_git_root()
        end,
        desc = "Find Files (Root Dir)",
      },
      {
        "<leader>ff",
        function()
          require("fff").find_in_git_root()
        end,
        desc = "Find Files (Root Dir)",
      },
      {
        "<leader>fF",
        function()
          require("fff").find_files()
        end,
        desc = "Find Files (cwd)",
      },
      {
        "<leader>fg",
        function()
          require("fff").find_in_git_root()
        end,
        desc = "Find Files (git-files)",
      },
    },
  },
}
