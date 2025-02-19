return {
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      current_line_blame = true,
      current_line_blame_opts = {
        delay = 1000,
      },
      current_line_blame_formatter = " 󰞗 <author>  <author_time:%R>  <summary>",
      preview_config = {
        border = "rounded",
      },
    },
  },
  {
    "divaltor/tsugit.nvim",
    keys = {
      {
        "<leader>gg",
        function()
          require("tsugit").toggle()
        end,
        desc = "Open LazyGit (cwd)",
      },
      {
        "<leader>gG",
        function()
          require("tsugit").toggle_for_file(LazyVim.root.git())
        end,
        desc = "Open LazyGit (root)",
      },
    },
    opts = {
      keys = {
        toggle = "<C-q>",
        force_quit = "<C-z>",
      },
    },
  },
}
