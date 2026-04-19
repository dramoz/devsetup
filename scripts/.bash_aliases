# Common aliases — sourced from ~/.bashrc_user.
# Distro-aware where it matters (Fedora 43 / Ubuntu 24.04+).

# --------------------------------------------------------------------------
# ls & tree
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias lah='ls -lah'

alias t0='tree'
alias t1='tree -L 1'
alias t2='tree -L 2'
alias t3='tree -L 3'

# History
alias h='history'
alias hg='history | grep'

# --------------------------------------------------------------------------
# Misc helpers — functions, not aliases ($1 doesn't work inside aliases)
count_files() { find "${1:-.}" -type f | wc -l; }
showpath() { tr ':' '\n' <<<"${PATH}"; }

# --------------------------------------------------------------------------
# Navigation / files
alias home='cd ~'
alias rm_dir='/bin/rm --recursive --force --verbose'

# Archives
alias targz='tar -cvzf'
alias untargz='tar -xvzf'

# --------------------------------------------------------------------------
# Color funcs (cat-style filters)
red()     { tput setaf 1; cat; tput sgr0; }
green()   { tput setaf 2; cat; tput sgr0; }
yellow()  { tput setaf 3; cat; tput sgr0; }
blue()    { tput setaf 4; cat; tput sgr0; }
magenta() { tput setaf 5; cat; tput sgr0; }
cyan()    { tput setaf 6; cat; tput sgr0; }

# Set terminal title (works on any TTY emulator)
termtitle() { printf '\033]0;%s\007' "$*"; }

# Open a new tab in the system terminal — Fedora 42+ ships Ptyxis by default.
if command -v ptyxis >/dev/null 2>&1; then
    alias newtab='ptyxis --tab'
elif command -v gnome-terminal >/dev/null 2>&1; then
    alias newtab='gnome-terminal --tab --title'
fi

# --------------------------------------------------------------------------
# Git shortcuts
alias gls='git ls-files | green; git ls-files --others --exclude-standard | red'
alias gcache="git config --global credential.helper 'cache --timeout 36000'"
alias gpush='git push'
alias gci='git commit -m'
alias gcia='git commit -am'
alias gpull='git pull'
alias gsync='git pull && git push'
alias gmerge='git merge'
alias gshow_remote='git remote -v'
alias gmerge_fork='git merge upstream/'

# https://www.fizerkhan.com/blog/posts/clean-up-your-local-branches-after-merge-and-delete-in-github
alias ghelp_cleanup='echo https://www.fizerkhan.com/blog/posts/clean-up-your-local-branches-after-merge-and-delete-in-github'

# Use curl (already a base dep); wget is not guaranteed to be installed.
alias gignore='curl -fsSL https://www.toptal.com/developers/gitignore/api/c,c++,python,jupyternotebooks,backup -o .gitignore'

# --------------------------------------------------------------------------
# OS package-manager wrappers — distro-agnostic surface so the same command
# works on Fedora (dnf) and Ubuntu/Debian (apt). Functions, not aliases, so
# they accept positional arguments. Detect once at shell startup.
if command -v dnf >/dev/null 2>&1; then
    __OS_PKG=dnf
elif command -v apt >/dev/null 2>&1; then
    __OS_PKG=apt
else
    __OS_PKG=
fi

os_update() {
    case "${__OS_PKG}" in
        dnf) sudo dnf update -y && sudo dnf clean all ;;
        apt) sudo apt update -y && sudo apt upgrade -y && sudo apt dist-upgrade -y && sudo apt autoremove -y ;;
        *)   echo "os_update: no supported package manager" >&2; return 1 ;;
    esac
}

os_install() {
    case "${__OS_PKG}" in
        dnf) sudo dnf install -y "$@" ;;
        apt) sudo apt install -y "$@" ;;
        *)   echo "os_install: no supported package manager" >&2; return 1 ;;
    esac
}

os_remove() {
    case "${__OS_PKG}" in
        dnf) sudo dnf remove -y "$@" ;;
        apt) sudo apt remove -y "$@" ;;
    esac
}

os_search() {
    case "${__OS_PKG}" in
        dnf) dnf search "$@" ;;
        apt) apt search "$@" ;;
    esac
}

os_info() {
    case "${__OS_PKG}" in
        dnf) dnf info "$@" ;;
        apt) apt show "$@" ;;
    esac
}

os_list() {
    # List installed packages (filter optional, e.g. `os_list python3`)
    case "${__OS_PKG}" in
        dnf) dnf list --installed "$@" ;;
        apt) apt list --installed "$@" 2>/dev/null ;;
    esac
}

os_clean() {
    case "${__OS_PKG}" in
        dnf) sudo dnf clean all ;;
        apt) sudo apt clean && sudo apt autoclean ;;
    esac
}

os_autoremove() {
    case "${__OS_PKG}" in
        dnf) sudo dnf autoremove -y ;;
        apt) sudo apt autoremove -y ;;
    esac
}

os_owns() {
    # Which installed package owns this file? Usage: os_owns /usr/bin/git
    case "${__OS_PKG}" in
        dnf) rpm -qf "$@" ;;
        apt) dpkg -S "$@" ;;
    esac
}

os_provides() {
    # Which package provides this file/capability? Usage: os_provides /usr/bin/foo
    case "${__OS_PKG}" in
        dnf) dnf provides "$@" ;;
        apt) command -v apt-file >/dev/null 2>&1 && apt-file search "$@" || dpkg -S "$@" ;;
    esac
}

# --------------------------------------------------------------------------
# Project marker — single-quoted so $(pwd) evaluates at use, not at definition.
alias start_project='export PRJ=$(pwd)'

# Pull devsetup repo on demand (replaces the auto git-pull-on-shell-start
# that used to live in .bashrc_devsetup and blocked every new terminal).
alias devsetup_update='( cd "${DEVSETUP_DIR:-${HOME}/dev/devsetup}" && git pull )'
