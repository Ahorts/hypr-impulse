if status is-login
    source ~/.config/fish/auto-Hypr.fish
end

if status is-interactive # Commands to run in interactive sessions can go here

    # No greeting
    set fish_greeting

    # Use starship
    function starship_transient_prompt_func
        starship module character
    end
    if test "$TERM" != "linux"
        starship init fish | source
        enable_transience
    end
    
    # Colors
    if test -f ~/.local/state/quickshell/user/generated/terminal/sequences.txt
        cat ~/.local/state/quickshell/user/generated/terminal/sequences.txt
    end

    fastfetch -c ~/.config/fastfetch/examples/16.jsonc

    alias pamcan pacman
    alias ls 'eza --icons'
    # Aliases
    # kitty doesn't clear properly so we need to do this weird printing
    alias clear "printf '\033[2J\033[3J\033[1;1H'"
    alias celar "printf '\033[2J\033[3J\033[1;1H'"
    alias claer "printf '\033[2J\033[3J\033[1;1H'"
    alias pamcan pacman
    alias q 'qs -c ii'
    if test "$TERM" != "linux"
        alias ls 'eza --icons'
    end
    alias vim nvim
    alias pn=pnpm
    alias nv=nvim
    alias cd=z
    alias pls=sudo

    function nvim
        kitten @ set-spacing margin=0

        command nvim $argv

        kitten @ set-spacing margin=21.75
    end

    zoxide init fish | source
    fzf --fish | source

end

# function fish_prompt
#   set_color cyan; echo (pwd)
#   set_color green; echo '> '
# end

# Created by `pipx` on 2026-01-29 16:31:06
set PATH $PATH /home/ahorts/.local/bin
