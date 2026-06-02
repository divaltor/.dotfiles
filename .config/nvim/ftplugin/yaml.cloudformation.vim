" Filetype plugin for CloudFormation YAML templates.
"
" Why this file exists: Neovim's LSP/health machinery expects an ftplugin
" for every registered filetype. Without one, :checkhealth vim.lsp (and
" the LSP module's internal sanity checks) warn
" "Unknown filetype 'yaml.cloudformation'". Sourcing an ftplugin — even
" one that just delegates — clears the warning.
"
" What it does: delegates to the stock YAML ftplugin so the buffer
" inherits every buffer-local option, keymap, and b:undo_ftplugin hook
" that a plain YAML file would. The b:did_ftplugin_yaml_cloudformation
" guard marks the cloudformation-specific load as having run, parallel
" to b:did_ftplugin_yaml set by the stock file. :runtime! also picks up
" any ftplugin/yaml_*.vim added by plugins on the runtimepath.

runtime! ftplugin/yaml.vim ftplugin/yaml_*.vim

if exists("b:did_ftplugin") && !exists("b:did_ftplugin_yaml_cloudformation")
  let b:did_ftplugin_yaml_cloudformation = 1
endif
