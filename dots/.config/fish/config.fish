if status is-login
    source ~/.config/fish/auto-Hypr.fish
end

if status is-interactive # Commands to run in interactive sessions can go here

    # No greeting
    set fish_greeting

    starship init fish | source
    if test -f ~/.local/state/quickshell/user/generated/terminal/sequences.txt
        cat ~/.local/state/quickshell/user/generated/terminal/sequences.txt
    end

    fastfetch -c ~/.config/fastfetch/examples/16.jsonc

    alias pamcan pacman
    alias ls 'eza --icons'
    alias pamcan pacman
    alias q 'qs -c ii'
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
