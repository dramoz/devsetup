# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

alias h='history'
alias hg='history | grep '
alias restart='sudo shutdown -r 0'
alias count_files='find $1 -type f | wc -l'
alias sudo='sudo -E env "PATH=$PATH"'

# From
# https://gist.github.com/zachbrowne/8bc414c9f30192067831fafebd14255c
# Change directory aliases
alias home='cd ~'
alias cd..='cd ..'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# Remove a directory and all files
alias rm_dir='/bin/rm  --recursive --force --verbose '

# Alias's for archives
alias targz='tar -cvzf'
alias untargz='tar -xvzf'

# Funcs for coloring
red() { tput setaf 1; cat; tput sgr0; }
green() { tput setaf 2; cat; tput sgr0; }
yellow() { tput setaf 3; cat; tput sgr0; }
blue() { tput setaf 4; cat; tput sgr0; }
magenta() { tput setaf 5; cat; tput sgr0; }
cyan() { tput setaf 6; cat; tput sgr0; }

# terminal title
termtitle_func() { printf "\033]0;$*\007"; }
alias termtitle=termtitle_func

# Git shortcuts
alias git_ls="git ls-files | green; git ls-files --others --exclude-standard | red"
