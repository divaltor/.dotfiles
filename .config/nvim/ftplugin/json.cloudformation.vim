" Filetype plugin for CloudFormation JSON templates.
"
" Why this file exists: Neovim's LSP/health machinery expects an ftplugin
" for every registered filetype. Without one, :checkhealth vim.lsp (and
" the LSP module's internal sanity checks) warn
" "Unknown filetype 'json.cloudformation'". Sourcing an ftplugin — even
" one that just delegates — clears the warning.
"
" What it does: delegates to the stock JSON ftplugin so the buffer
" inherits every buffer-local option, keymap, and b:undo_ftplugin hook
" that a plain JSON file would. The b:did_ftplugin_json_cloudformation
" guard marks the cloudformation-specific load as having run, parallel
" to b:did_ftplugin_json set by the stock file. :runtime! also picks up
" any ftplugin/json_*.vim added by plugins on the runtimepath.

runtime! ftplugin/json.vim ftplugin/json_*.vim

if exists("b:did_ftplugin") && !exists("b:did_ftplugin_json_cloudformation")
  let b:did_ftplugin_json_cloudformation = 1
endif
