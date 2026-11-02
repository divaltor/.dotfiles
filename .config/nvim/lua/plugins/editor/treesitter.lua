return {
  {
    "nvim-treesitter/nvim-treesitter",
    -- LazyVim loads treesitter on LazyFile (BufReadPost), which is after
    -- filetype detection. Loading it that late changes what extension-only
    -- filetypes resolve to: `x.tf` ends up as `tf` instead of `terraform`
    -- (and terraformls then never attaches). BufReadPre keeps detection
    -- intact while still keeping treesitter off the plain-`nvim` startup path.
    event = "BufReadPre",
  },
}
