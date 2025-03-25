if status is-interactive
    # Commands to run in interactive sessions can go here
end

set fish_greeting ""

function fish
    source ~/.config/fish/config.fish
end

fish_add_path /opt/homebrew/bin/

if type -q bat
    alias cat bat
end

if type -q nvim
    alias vim nvim
end

if type -q eza
    alias ls 'eza --long --icons --classify --all --header --git --no-user --tree --level 1'
    alias ll ls
end

if type -q lazygit
    alias lg lazygit
end

if type -q lazydocker
    alias ld lazydocker
end

if type -q helix
    alias hx helix
end

set -U nvm_default_version lts
set -U -x EDITOR /opt/homebrew/bin/nvim
set -U -x HOMEBREW_NO_AUTO_UPDATE ""
set -U -x XDG_CONFIG_HOME $HOME/.config

starship init fish | source
zoxide init fish | source

if type -q z
    alias cd z
end

function y
    set tmp (mktemp -t "yazi-cwd.XXXXXX")
    yazi $argv --cwd-file="$tmp"
    if set cwd (command cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
        builtin cd -- "$cwd"
    end
    rm -f -- "$tmp"
end

export PKG_CONFIG_PATH="$(brew --prefix)/opt/mysql-client/lib/pkgconfig"

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init2.fish 2>/dev/null || :
