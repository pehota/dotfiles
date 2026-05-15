function cz --description "chezmoi wrapper: sync, add, rm"
    switch $argv[1]
        case sync
            chezmoi re-add
            chezmoi git -- add -A
            chezmoi git -- commit -m "chore: sync dotfiles" 2>/dev/null || true
            chezmoi git -- pull --rebase
            chezmoi apply
            chezmoi git -- push
        case add
            chezmoi add $argv[2..]
            chezmoi git -- add -A
            chezmoi git -- commit -m "track $argv[2]"
            chezmoi git -- push
        case rm forget
            chezmoi forget --force $argv[2..]
            chezmoi git -- add -A
            chezmoi git -- commit -m "untrack $argv[2]"
            chezmoi git -- push
        case status
            chezmoi status
        case '*'
            chezmoi $argv
    end
end
