set fish_greeting ""

set -U -x HOMEBREW_NO_AUTO_UPDATE 1
set -U -x XDG_CONFIG_HOME $HOME/.config
set -U -x nvm_default_version lts

eval "$(/opt/homebrew/bin/brew shellenv)"

if type -q devbox
    devbox global shellenv --init-hook | source
end

set -U -x PKG_CONFIG_PATH $DEVBOX_PACKAGES_DIR/lib/pkgconfig

# uv
fish_add_path "/Users/divaltor/.local/bin"

if type -q bat
    alias cat bat
end

if type -q eza
    alias ls 'eza --long --icons --classify --all --header --git --no-user --tree --level 1'
    alias ll ls
end

if type -q nvim
    alias vim nvim
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

if type -q starship
    starship init fish | source
end

if type -q zoxide
    zoxide init fish | source
end

if type -q z
    alias cd z
end

if type -q yt-dlp
    alias mp4 'yt-dlp -t mp4 --sponsorblock-remove sponsor --extractor-args "youtube:player-client=default,-tv_simply" -o "~/youtube/%(title)s.%(ext)s"'
end

function y
    set tmp (mktemp -t "yazi-cwd.XXXXXX")
    yazi $argv --cwd-file="$tmp"
    if set cwd (command cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
        builtin cd -- "$cwd"
    end
    rm -f -- "$tmp"
end

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init2.fish 2>/dev/null || :

fish_add_path "/Users/divaltor/.bun/bin"
fish_add_path $HOME/.local/bin

set -U -x OPENCODE_EXPERIMENTAL_LSP_TY true
set -U -x OPENCODE_ENABLE_EXA false
set -U -x OPENCODE_EXPERIMENTAL_MARKDOWN true
set -U -x OPENCODE_ENABLE_QUESTION_TOOL true
set -U -x OPENCODE_EXPERIMENTAL_FILEWATCHER true
set -U -x OPENCODE_EXPERIMENTAL_OXFMT true
