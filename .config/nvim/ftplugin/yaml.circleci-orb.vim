runtime! ftplugin/yaml.vim ftplugin/yaml_*.vim

if exists("b:did_ftplugin") && !exists("b:did_ftplugin_yaml_circleci_orb")
  let b:did_ftplugin_yaml_circleci_orb = 1
endif
