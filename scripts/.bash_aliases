# ls & tree
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias lah='ls -lah'

alias t0='tree'
alias t1='tree -L 1'
alias t2='tree -L 2'
alias t3='tree -L 3'

# History & Grep
alias h='history'
alias hg='history | grep '

# Misc
alias count_files='find $1 -type f | wc -l'
alias sudo='sudo -E env "PATH=$PATH"'

# From
# https://gist.github.com/zachbrowne/8bc414c9f30192067831fafebd14255c
# Change directory aliases
alias home='cd ~'

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
alias newtab='gnome-terminal --tab --title'

# Git shortcuts
alias git_ls="git ls-files | green; git ls-files --others --exclude-standard | red"
alias git_cache="git config --global credential.helper 'cache --timeout 36000'"

# apt update all!
alias apt_update_all="sudo apt update -y && sudo apt upgrade -y && sudo apt dist-upgrade -y && sudo apt autoremove -y"
