-- The debugger is gone: we don't use nvim-dap anywhere anymore.
--
-- LazyVim's language extras (go, python, java, kotlin, clangd, typescript) each
-- declare an `optional` spec for nvim-dap. With the dap.core extra gone those
-- optional specs are the only declarations left, and lazy.nvim then loads
-- nvim-dap -- plus mason.nvim, through mason-nvim-dap -- on every startup.
-- Re-adding dap.core later means deleting this file.
return {
  { "mfussenegger/nvim-dap", enabled = false },
  { "rcarriga/nvim-dap-ui", enabled = false },
  { "theHamsta/nvim-dap-virtual-text", enabled = false },
  { "jay-babu/mason-nvim-dap.nvim", enabled = false },
  { "leoluz/nvim-dap-go", enabled = false },
  { "mfussenegger/nvim-dap-python", enabled = false },
  { "nvim-neotest/nvim-nio", enabled = false },
}
