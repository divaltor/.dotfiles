return {
  schema = "registry+v1",
  name = "cfn-lsp-extra",
  description = "Experimental CloudFormation language server built on top of cfn-lint.",
  homepage = "https://github.com/LaurenceWarne/cfn-lsp-extra",
  licenses = { "MIT" },
  languages = { "YAML", "JSON", "CloudFormation" },
  categories = { "LSP" },
  source = { id = "pkg:pypi/cfn-lsp-extra@0.7.5" },
  bin = {
    ["cfn-lsp-extra"] = "pypi:cfn-lsp-extra",
  },
}
