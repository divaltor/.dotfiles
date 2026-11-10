## Installation

1. Clone the repository `git clone <git@github.com>:Divaltor/.dotfiles.git $HOME/.dotfiles`

1. `stow --adapt .`

Might need to copy `opencode` folder (`tools` especially) manually because it can't handle symlinks yet

## Agent skills

All skills live in `.agents/skills/<name>/`, and the directory name must equal the `name:` in `SKILL.md`. `stow` links them into `~/.agents/skills`, which Amp and OpenCode both read. Private skills (the `emil-*` set) are real directories in `~/.agents/skills` that are never committed here.

`mise run skills:sync` mirrors them into the Amp User Skills repository, which is overwritten and must never be edited by hand. Use `-- --dry-run` to preview. It stops with an error on anything Amp rejects: a name that differs from the directory, a description over 1024 characters, invalid YAML or a binary file.

A skill that must stay on this laptop (FT-specific, or bundling a binary) is marked in its frontmatter:

```yaml
metadata:
  scope: local
```

Skills that exist only in the Amp repository are left alone. `interface-design` stays in `.config/opencode/skills` because it has no frontmatter.
