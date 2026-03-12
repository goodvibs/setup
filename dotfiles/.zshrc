# --- theme -------------------------------------------------------------------
HOMEBREW_PREFIX=/opt/homebrew
source "$HOMEBREW_PREFIX/share/powerlevel10k/powerlevel10k.zsh-theme"
source ~/.p10k.zsh

# --- aliases -----------------------------------------------------------------
alias e='eza'
alias lg='lazygit'

# --- PATH --------------------------------------------------------------------
typeset -U path PATH

path=(
  "$HOME/.local/bin"
  "$HOME/.cargo/bin"
  "$HOME/.lmstudio/bin"
  /Applications/Ghostty.app/Contents/MacOS
  "$HOMEBREW_PREFIX/bin"
  "$HOMEBREW_PREFIX/sbin"
  /usr/local/bin
  /usr/bin
  /bin
  /usr/sbin
  /sbin
  "$HOME/Developer/Personal/setup/plugins/bin"
)

[[ -d "$HOME/Developer/plugins/git-open" ]] && path+=("$HOME/Developer/plugins/git-open")
[[ -d "$HOME/Developer/plugins/zvm" ]] && path+=("$HOME/Developer/plugins/zvm")

export PATH

# --- zellij ------------------------------------------------------------------
repo-session() {
    zellij -n repo -s "$(basename "$PWD")"
}

# --- tools -------------------------------------------------------------------
eval "$(zoxide init zsh)"
source "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# local overrides
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
