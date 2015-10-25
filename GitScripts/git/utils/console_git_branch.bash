function parse_git_branch () {
       git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

GREEN="\[\033[0;32m\]"
NO_COLOUR="\[\033[0m\]"

PS1="$NO_COLOUR\u$NO_COLOUR:\w$GREEN\$(parse_git_branch)$NO_COLOUR\$ "
