## Installation

1. Clone the repository to $HOME/.dotfiles

`$ git clone git@github.com:Divaltor/.dotfiles.git $HOME/.dotfiles`

2. Install [Mackup](https://github.com/lra/mackup)
3. Create symlinks for mackup configs
```bash
ln -s $HOME/.dotfiles/.mackup.cfg $HOME/.mackup.cfg
ln -s $HOME/.dotfiles/.mackup $HOME/.mackup
```
4. Restore backup `mackup restore`
