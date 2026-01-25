# --- theme -------------------------------------------------------------------
source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme
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
  /opt/homebrew/bin
  /opt/homebrew/sbin
  /usr/local/bin
  /usr/bin
  /bin
  /usr/sbin
  /sbin
  "$HOME/Developer/extra/git-open"
)

export PATH

# --- zellij ------------------------------------------------------------------
repo-session() {
    zellij -n repo -s $(basename $PWD)
}

# --- tools -------------------------------------------------------------------
eval "$(zoxide init zsh)"
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
