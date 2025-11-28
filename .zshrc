export HISTFILE=$HOME/.zsh_history
export HISTTIMEFORMAT="[%F %T] "
export SAVEHIST=1000
export HISTSIZE=999


fpath=("$HOME/completions/" $fpath)

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

eval "$(zoxide init zsh)"
eval "$(starship init zsh)"

if command -v "sheldon" &> /dev/null; then
  eval "$(sheldon source)"
fi

if command -v "pyenv" &> /dev/null; then
  eval "$(pyenv virtualenv-init -)"
fi

if command -v "mise" &> /dev/null; then
  eval "$(mise activate zsh)"
fi

if command -v "brew" &> /dev/null; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

if command -v "fnm" &> /dev/null; then
  eval "$(fnm env --use-on-cd --shell zsh)"
fi

if [ -e "$HOME/.zshlocal" ]; then source "$HOME/.zshlocal"; fi
if [ -e "$HOME/.local_envs" ]; then source "$HOME/.local_envs"; fi
if [ -e "$HOME/.cargo/env" ]; then . "$HOME/.cargo/env";  fi
if [ -e "$HOME/.deno/env" ]; then . "$HOME/.deno/env"; fi
if [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then . "$HOME/.nix-profile/etc/profile.d/nix.sh"; fi
if [ -e "$HOME/.sdkman/bin/sdkman-init.sh" ]; then source "$HOME/.sdkman/bin/sdkman-init.sh"; fi
if [ -s "$NVM_DIR/nvm.sh" ]; then source "$NVM_DIR/nvm.sh"; fi
if [ -s "$NVM_DIR/bash_completion" ]; then source "$NVM_DIR/bash_completion"; fi
