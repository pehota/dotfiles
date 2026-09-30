function unalias --wraps='functions --erase $argv' --description 'alias unalias functions --erase $argv'
    functions --erase $argv $argv
end
