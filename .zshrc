export HISTFILE=$HOME/.zsh_history
export HISTTIMEFORMAT="[%F %T] "
export SAVEHIST=1000
export HISTSIZE=999


fpath=("$HOME/completions/" $fpath)


# Cursor alias
function cursor() {
    "$HOME/Apps/cursor/cursor.appimage" --no-sandox "${@}" > /dev/null 2>&1 & disown
}

## functions
function note () {
  nvim $NOTES_HOME/$(date +%Y%m%d%H%M%S).md
}
function journal () {
  nvim $JOURNALS_HOME/$(date +%Y-%m-%d).md
}
function drmid-fn {
  imgs=$(docker images -q -f dangling=true)
  [ ! -z "$imgs" ] && docker rmi "$imgs" || echo "no dangling images."
}

eval "$(sheldon source)"
eval "$(zoxide init zsh)"
eval "$(starship init zsh)"
eval "$(mise activate zsh)"

if [ -e "$HOME/.zshlocal" ]; then source "$HOME/.zshlocal"; fi
eval "$(pyenv virtualenv-init -)"
