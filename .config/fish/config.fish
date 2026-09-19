set fish_greeting ""

set -U -x HOMEBREW_NO_AUTO_UPDATE 1
set -U -x HOMEBREW_NO_ENV_HINTS 1
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
    set -U -x EDITOR nvim
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

if type -q opencode2
    alias opencode opencode2
end

if type -q yt-dlp
    function mp4
        # The PATH ffmpeg may exist yet be unrunnable (stale brew dylib
        # link), which yt-dlp reports as "ffmpeg is not installed" and
        # leaves a silent video + orphan audio. Verify before use.
        set -l ffmpeg_bin
        for candidate in (command -s ffmpeg 2>/dev/null) /opt/homebrew/bin/ffmpeg /opt/homebrew/opt/ffmpeg-full/bin/ffmpeg
            if test -x "$candidate" && "$candidate" -version >/dev/null 2>&1
                set ffmpeg_bin "$candidate"
                break
            end
        end

        if test -z "$ffmpeg_bin"
            echo "mp4: no working ffmpeg found (binary present but won't run?) — try `brew reinstall ffmpeg`, then retry" >&2
            return 1
        end

        set -l ffmpeg_dir (path dirname "$ffmpeg_bin")
        set -l js_runtime

        if type -q deno
            set js_runtime --js-runtimes deno
        else if type -q node
            set js_runtime --js-runtimes node
        end

        yt-dlp \
            $js_runtime \
            --ffmpeg-location "$ffmpeg_dir" \
            -S "vcodec:h264,lang,quality,res,fps,hdr:12,acodec:aac" \
            --merge-output-format mp4 \
            --remux-video mp4 \
            --sponsorblock-remove sponsor \
            --extractor-args "youtube:player-client=default,-tv_simply" \
            -o "$HOME/youtube/%(title)s.%(ext)s" \
            --remote-components ejs:github \
            $argv
    end
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

set -U -x DO_NOT_TRACK 1

set -U -x UV_PREVIEW_FEATURES content-addressed-cache

set -U -x AMP_DISABLE_AMP_COAUTHOR_TRAILER 1

fish_add_path /opt/homebrew/opt/ffmpeg-full/bin
