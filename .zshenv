export EDITOR='nvim'

export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"

export GEM_HOME="$HOME/.gem"
export ANDROID_HOME="$HOME/Android/Sdk"
export PNPM_HOME="$HOME/.local/share/pnpm"
export NVM_DIR="$HOME/.nvm"
export NOTES_HOME="$HOME/Documents/Obsidian/vault/"
export JOURNALS_HOME="$HOME/Documents/Obsidian/vault/"
export WORKLOG_PATH="$HOME/Documents/Obsidian/vault/worklog.md"
export MEMORY_FILE_PATH="$HOME/.llm_memory.txt"
export LOGGI_SCRIPTS="$HOME/.scripts/work/loggi"
export OLLAMA_API_BASE="http://127.0.0.1:11434"
export CUDA_VISIBLE_DEVICES=0

export PATH="$PNPM_HOME:$PATH"
export PATH=$PATH:"$HOME"/.local/bin
export PATH=$PATH:"$HOME"/.bin
export PATH=$PATH:"$HOME"/bin
export PATH=$PATH:"$HOME"/dotfiles-public/bin
export PATH=$PATH:"$HOME"/.emacs.d/bin
export PATH=$PATH:"$HOME"/.config/emacs/bin
export PATH=$PATH:"$HOME"/.gem/bin
export PATH=$PATH:"$LOGGI_SCRIPTS"
export PATH="/root/.local/bin:$PATH"

alias v="nvim"
alias vim="nvim"
alias jest="npx jest"
alias prisma="npx prisma"
alias rt="npm run test"
alias emacs="emacsclient -c -a 'emacs'"
alias em="emacs -nw"
alias wez="flatpak run org.wezfurlong.wezterm"
alias g="git"
alias trename="tmux rename-session"
alias ..="cd .."
alias ll="ls -lhF --color"
alias la="ls -lahF --color"
alias lsd="ls -lhF --color | grep --color=never '^d'"
alias gogh="bash -c  \"\$(wget -qO- https://git.io/vQgMr)\""
alias hm="home-manager"
alias nxe="nix-env"
alias ls="eza --icons -w 80"
alias lza="eza --icons -1 -a -l --total-size"
alias zj="zellij"
alias eee="sesh connect \$(sesh l -c -i | gum filter --limit 1 --placeholder 'Choose a session' --height 10 --prompt='⚡')"
alias GO="z \$(zoxide query --list | gum filter --limit 1 --placeholder 'Go to')"

if [ -e "$HOME/.cargo/env" ]; then . "$HOME/.cargo/env";  fi
if [ -e "$HOME/.deno/env" ]; then . "$HOME/.deno/env"; fi
if [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then . "$HOME/.nix-profile/etc/profile.d/nix.sh"; fi
if [ -e "$HOME/.sdkman/bin/sdkman-init.sh" ]; then source "$HOME/.sdkman/bin/sdkman-init.sh"; fi
if [ -e "$HOME/.local_envs" ]; then source "$HOME/.local_envs"; fi
if [ -s "$NVM_DIR/nvm.sh" ]; then source "$NVM_DIR/nvm.sh"; fi
if [ -s "$NVM_DIR/bash_completion" ]; then source "$NVM_DIR/bash_completion"; fi
