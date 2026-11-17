# Resolve setup repo root from the ~/.zshrc symlink target (configs/zshrc).
if [[ -L "$HOME/.zshrc" ]]; then
  SETUP_DIR="$(cd "$(dirname "$(readlink "$HOME/.zshrc")")/.." && pwd)"
else
  SETUP_DIR="${SETUP_DIR:-$HOME/Developer/Personal/setup}"
fi

### THEME
HOMEBREW_PREFIX=/opt/homebrew
source "$HOMEBREW_PREFIX/share/powerlevel10k/powerlevel10k.zsh-theme"
source "$HOME/.p10k.zsh"

### ALIASES
alias e='eza -a'
alias lg='lazygit'

### PATH
typeset -U path PATH

path=(
  "$REX_BIN_DIR"
  "$HOME/.local/bin"
  "$HOME/.local/share/setup/plugins/bin"
  "$HOMEBREW_PREFIX/opt/rustup/bin"
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
  "$SETUP_DIR/bin"
  "$SETUP_DIR/scripts"
  "$SETUP_DIR/plugins/bin"
)

export PATH
export EDITOR="hx"
export JAVA_HOME="$HOMEBREW_PREFIX/opt/openjdk/libexec/openjdk.jdk/Contents/Home"

### NODE
if (( $+commands[fnm] )); then
  eval "$(fnm env --use-on-cd --shell zsh)"
fi

### TOOLS
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# 1. Default command for running 'fzf' standalone without input
export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'

# 2. Command for the Ctrl+T shortcut (finds both files and directories)
export FZF_CTRL_T_COMMAND='fd --strip-cwd-prefix --hidden --follow --exclude .git'

# 3. Command for the Alt+C shortcut (finds directories only)
export FZF_ALT_C_COMMAND='fd --type d --strip-cwd-prefix --hidden --follow --exclude .git'

eval "$(zoxide init zsh)"

if [[ -n ${commands[zsh-helix-mode]:-} ]]; then
  source "${commands[zsh-helix-mode]}"

  # Integer, in hundredths of a second (1 = 10ms). Default is 40 (400ms).
  # Shortens the wait before a bare Escape is recognized as Escape rather than
  # the start of an Escape-prefixed key sequence.
  KEYTIMEOUT=1

  # p10k caches prompt_* output and only re-evaluates `-c` conditions on
  # `zle reset-prompt`, so the mode is selected via `-c`. Colors are set per
  # state in the p10k config.
  prompt_helix_mode() {
    p10k segment -s insert -c '${(M)ZHM_MODE:#insert}' -t 'INSERT'
    p10k segment -s normal -c '${(M)ZHM_MODE:#normal}' -t 'NORMAL'
    p10k segment -s select -c '${(M)ZHM_MODE:#select}' -t 'SELECT'
  }

  instant_prompt_helix_mode() {
    p10k segment -s insert -t 'INS'
  }
else
  source "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  source "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M hxins '^X^E' edit-command-line
bindkey -M hxnor '^X^E' edit-command-line

### CUSTOM COMMANDS
source-zshrc() {
  source "$HOME/.zshrc"
}

zshrc-open() {
  hx "$HOME/.zshrc"
}

project-widget() {
  local project
  project=$("$HOME/.config/rex/scripts/project-picker")

  if [[ -n "$project" ]]; then
    BUFFER="cd ${(q)project}"
    if (( $+widgets[_zhm_accept_or_submit] )); then
      zle _zhm_accept_or_submit
    else
      zle accept-line
    fi
  fi
}

zle -N project-widget
bindkey '^ ' project-widget

### LOCAL OVERRIDES
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
