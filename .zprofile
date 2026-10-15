export HISTFILE=$HOME/.zsh_history
export HISTTIMEFORMAT="[%F %T] "
export SAVEHIST=10000
export HISTSIZE=100000
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_ENV_HINTS=1

if command -v "/opt/homebrew/bin/brew" &> /dev/null; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

if command -v "/home/linuxbrew/.linuxbrew/bin/brew" &> /dev/null; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv zsh)"
fi


if [ -e "$HOME/.cargo/env" ]; then . "$HOME/.cargo/env";  fi
