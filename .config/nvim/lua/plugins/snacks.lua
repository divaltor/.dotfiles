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
    init = function()
      -- Backdrop overlay for fff.nvim (similar to Snacks picker)
      local backdrop_win, backdrop_buf
      local function open_backdrop()
        if backdrop_win and vim.api.nvim_win_is_valid(backdrop_win) then
          return
        end
        vim.api.nvim_set_hl(0, "FFFBackdrop", { bg = "#000000" })
        backdrop_buf = vim.api.nvim_create_buf(false, true)
        vim.bo[backdrop_buf].buftype = "nofile"
        backdrop_win = vim.api.nvim_open_win(backdrop_buf, false, {
          relative = "editor",
          width = vim.o.columns,
          height = vim.o.lines,
          col = 0,
          row = 0,
          focusable = false,
          style = "minimal",
          zindex = 1,
        })
        vim.wo[backdrop_win].winhighlight = "Normal:FFFBackdrop"
        vim.wo[backdrop_win].winblend = 60
      end
      local function close_backdrop()
        if backdrop_win and vim.api.nvim_win_is_valid(backdrop_win) then
          vim.api.nvim_win_close(backdrop_win, true)
        end
        backdrop_win = nil
        if backdrop_buf and vim.api.nvim_buf_is_valid(backdrop_buf) then
          vim.api.nvim_buf_delete(backdrop_buf, { force = true })
        end
        backdrop_buf = nil
      end

      local group = vim.api.nvim_create_augroup("FFFBackdrop", { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = "fff_list",
        callback = function()
          open_backdrop()
          -- Close backdrop when the fff window closes
          vim.api.nvim_create_autocmd("WinClosed", {
            group = group,
            once = true,
            callback = close_backdrop,
          })
        end,
      })
    end,
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
