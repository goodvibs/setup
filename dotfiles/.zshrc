SETUP_DIR="$HOME/Developer/Personal/setup"

### THEME
HOMEBREW_PREFIX=/opt/homebrew
source "$HOMEBREW_PREFIX/share/powerlevel10k/powerlevel10k.zsh-theme"
source ~/.p10k.zsh

### ALIASES
alias e='eza'
alias lg='lazygit'

### PATH
typeset -U path PATH

path=(
  "$HOME/.local/bin"
  "$HOME/.cargo/bin"
  "$HOME/.lmstudio/bin"
  /Applications/Ghostty.app/Contents/MacOS
  "$HOMEBREW_PREFIX/bin"
  "$HOMEBREW_PREFIX/sbin"
  "$HOMEBREW_PREFIX/opt/openjdk/bin"
  "$HOMEBREW_PREFIX/opt/llvm"
  /usr/local/bin
  /usr/bin
  /bin
  /usr/sbin
  /sbin
  "$SETUP_DIR/scripts"
  "$SETUP_DIR/plugins/bin"
)

export PATH
export JAVA_HOME="$HOMEBREW_PREFIX/opt/openjdk/libexec/openjdk.jdk/Contents/Home"

### TOOLS
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# 1. Default command for running 'fzf' standalone without input
export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'

# 2. Command for the Ctrl+T shortcut (finds both files and directories)
export FZF_CTRL_T_COMMAND='fd --strip-cwd-prefix --hidden --follow --exclude .git'

# 3. Command for the Alt+C shortcut (finds directories only)
export FZF_ALT_C_COMMAND='fd --type d --strip-cwd-prefix --hidden --follow --exclude .git'

eval "$(zoxide init zsh)"

source "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

### CUSTOM COMMANDS
source-zshrc() {
  source ~/.zshrc
}

zshrc-open() {
  hx ~/.zshrc
}

project-widget() {
  local project

  project=$(
    fd --hidden --type d --max-depth 2 '^\.git$' \
      "$HOME/Developer/Work" \
      "$HOME/Developer/Personal" \
      2>/dev/null |
    sed 's|/\.git/$||' |
    fzf --height=60% --layout=reverse --border --prompt='Project> '
  )

  if [[ -n "$project" ]]; then
    BUFFER="cd ${(q)project}"
    zle accept-line
  fi
}

zle -N project-widget
bindkey '^ ' project-widget

### LOCAL OVERRIDES
[[ -f "$SETUP_DIR/dotfiles/.zshrc.local" ]] && source "$SETUP_DIR/dotfiles/.zshrc.local"
