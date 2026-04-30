function bup
    if ! type -f brew &>/dev/null
        print 'brew is not installed'
        exit 1
    end

    brew update && brew upgrade && brew cleanup -s && brew doctor
end
