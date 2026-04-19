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

# --------------------------------------------------------------------------
# Terminal-aware helpers — detect the actual terminal at call time via env
# vars set by the emulator (or by tmux/screen). Detection happens on every
# call because the user can switch contexts (enter tmux, ssh out, etc.).
__detect_term() {
    if   [[ -n "${TMUX:-}" ]];               then echo tmux
    elif [[ -n "${STY:-}" ]];                then echo screen
    elif [[ -n "${PTYXIS_VERSION:-}" ]];     then echo ptyxis
    elif [[ -n "${KONSOLE_VERSION:-}" ]];    then echo konsole
    elif [[ -n "${KITTY_WINDOW_ID:-}" ]];    then echo kitty
    elif [[ -n "${ALACRITTY_SOCKET:-}" ]] || [[ -n "${ALACRITTY_LOG:-}" ]]; then echo alacritty
    elif [[ -n "${WEZTERM_PANE:-}" ]];       then echo wezterm
    elif [[ -n "${TILIX_ID:-}" ]];           then echo tilix
    elif [[ -n "${TERMINATOR_UUID:-}" ]];    then echo terminator
    elif [[ -n "${WT_SESSION:-}" ]];         then echo windows-terminal
    elif [[ -n "${VTE_VERSION:-}" ]];        then echo vte    # gnome-terminal et al.
    else                                          echo unknown
    fi
}

# Write an OSC-0 title to the current terminal, with DCS passthrough when
# we're inside tmux or screen (their default config strips OSC sequences).
__write_title() {
    local title="$1"
    if [[ -n "${TMUX:-}" ]]; then
        printf '\033Ptmux;\033\033]0;%s\007\033\\' "${title}"
    elif [[ "${TERM:-}" == screen* ]] || [[ -n "${STY:-}" ]]; then
        printf '\033P\033]0;%s\007\033\\' "${title}"
    else
        printf '\033]0;%s\007' "${title}"
    fi
}

# termtitle <text>  — set the terminal window title persistently.
# Old version printed the OSC sequence once, which Fedora's /etc/bashrc
# PROMPT_COMMAND immediately clobbered. New version sets _TERMTITLE; the
# prompt function in ~/.bashrc_user writes that as the title on every redraw.
# `termtitle` with no args clears the override and returns to default behavior.
termtitle() {
    if [[ -n "$*" ]]; then
        export _TERMTITLE="$*"
    else
        unset _TERMTITLE
    fi
    # Also write immediately so the change shows before the next prompt.
    __write_title "${_TERMTITLE:-${USER}@${HOSTNAME%%.*}: ${PWD/#$HOME/\~}}"
}

# newtab [title]  — open a new tab in the current terminal emulator.
# Inside tmux/screen we open a multiplexer window instead (which is what the
# user almost always wants). Falls back to launching Ptyxis or gnome-terminal
# if neither the current terminal nor a multiplexer is detected.
newtab() {
    local title="${1:-}"
    case "$(__detect_term)" in
        tmux)
            if [[ -n "${title}" ]]; then tmux new-window -n "${title}"
            else                         tmux new-window
            fi
            ;;
        screen)
            screen
            ;;
        ptyxis)
            ptyxis --tab ${title:+--title "${title}"}
            ;;
        konsole)
            konsole --new-tab ${title:+-p "tabtitle=${title}"}
            ;;
        kitty)
            if command -v kitty >/dev/null 2>&1; then
                kitty @ launch --type=tab ${title:+--title "${title}"}
            fi
            ;;
        wezterm)
            wezterm cli spawn --new-tab
            ;;
        tilix)
            tilix --action=session-add-right
            ;;
        terminator)
            terminator --new-tab 2>/dev/null || xdotool key ctrl+shift+t
            ;;
        vte)
            # gnome-terminal, mate-terminal, xfce4-terminal — all VTE-based
            if command -v gnome-terminal >/dev/null 2>&1; then
                gnome-terminal --tab ${title:+--title "${title}"}
            elif command -v xfce4-terminal >/dev/null 2>&1; then
                xfce4-terminal --tab ${title:+--title="${title}"}
            elif command -v mate-terminal >/dev/null 2>&1; then
                mate-terminal --tab ${title:+--title="${title}"}
            else
                echo "newtab: VTE terminal detected but launcher not found" >&2
                return 1
            fi
            ;;
        *)
            # Last-resort fallback: launch whatever is installed
            if   command -v ptyxis >/dev/null 2>&1;         then ptyxis --tab
            elif command -v gnome-terminal >/dev/null 2>&1; then gnome-terminal --tab
            else
                echo "newtab: no supported terminal found" >&2
                return 1
            fi
            ;;
    esac
}

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
