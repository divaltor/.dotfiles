return {
  {
    "mfussenegger/nvim-dap",

  -- stylua: ignore
    keys = {
      { "<leader>da", false },  -- Run with Args
      { "<leader>dg", false },  -- Go to Line (no execute)
      { "<leader>dj", false },  -- Down
      { "<leader>dk", false },  -- Up
      { "<leader>dO", function() require("dap").step_out() end, desc = "Step Out" },
      { "<leader>do", function() require("dap").step_over() end, desc = "Step Over" },
      { "<leader>dp", false },  -- Puase
      { "<leader>dr", false },  -- REPL
    },
  },
}
