export EDITOR='nvim'

export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"

export PERSONAL_SESSIONS_DIR="$HOME/engineering/.ai-sessions"
export GEM_HOME="$HOME/.gem"
export ANDROID_HOME="$HOME/Android/Sdk"
export PNPM_HOME="$HOME/.local/share/pnpm"
export NVM_DIR="$HOME/.nvm"
export NOTES_HOME="$HOME/Notes"
export JOURNALS_HOME="$HOME/Documents/Obsidian/vault/"
export WORKLOG_PATH="$HOME/Documents/Obsidian/vault/worklog.md"
export MEMORY_FILE_PATH="$HOME/.llm_memory.txt"
export TURSO_HOME="$HOME/.turso"
export OLLAMA_API_BASE="http://127.0.0.1:11434"
export DENO_INSTALL="$HOME/.deno"
# export AMP_TOOLBOX="$HOME/.bin"
export HORSES_PATH="$HOME/Horses"
export KNOWLEDGE_KB_PATH="$HORSES_PATH"
export PATH="$DENO_INSTALL/bin:$PATH"
export PATH="$HOME/.poetry/bin:$PATH"

export PATH="$PNPM_HOME:$PATH"
export PATH=$PATH:"$HOME"/.local/bin
export PATH=$PATH:"$HOME"/.cargo/bin
export PATH=$PATH:"$HOME"/.bin
export PATH=$PATH:"$HOME"/bin
export PATH=$PATH:"$HOME"/.gem/bin
export PATH=$PATH:"$TURSO_HOME"

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
alias dka="docker stop \$(docker ps -q)"
alias ll="ls -lhF --color"
alias la="ls -lahF --color"
alias lsd="ls -lhF --color | grep --color=never '^d'"
alias gogh="bash -c  \"\$(wget -qO- https://git.io/vQgMr)\""
alias hm="home-manager"
alias nxe="nix-env"
alias ls="eza --icons -w 80"
alias lza="eza --icons -1 -a -l --total-size"
alias zj="zellij"
alias eee="tmux-sessionizer"
alias GO="z \$(zoxide query --list | fzf)"
