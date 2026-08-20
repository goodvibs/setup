#!/usr/bin/env zsh
# Line-editor bundle: helix mode + autosuggestions + syntax-highlighting.
# Source once from zshrc (after fzf). Requires fzf shell integration when using Tab completion.
[[ -n ${ZSH_HELIX_MODE_LOADED:-} ]] && return 0

HOMEBREW_PREFIX="${HOMEBREW_PREFIX:-/opt/homebrew}"
ZSH_HELIX_MODE="${ZSH_HELIX_MODE_DIR:-$HOME/Developer/Personal/zsh-helix-mode}/zsh-helix-mode.zsh"

if [[ ! -f "$ZSH_HELIX_MODE" ]]; then
  print -u2 "zsh-helix-mode: missing $ZSH_HELIX_MODE (run install-plugins)"
  return 1
fi

# https://github.com/Multirious/zsh-helix-mode#compatibility
ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(
  zhm_history_prev
  zhm_history_next
  zhm_prompt_accept
  zhm_accept
  zhm_accept_or_insert_newline
)
ZSH_AUTOSUGGEST_ACCEPT_WIDGETS+=(
  zhm_move_right
  zhm_clear_selection_move_right
)
ZSH_AUTOSUGGEST_PARTIAL_ACCEPT_WIDGETS+=(
  zhm_move_next_word_start
  zhm_move_next_word_end
)

source "$ZSH_HELIX_MODE"

# vicmd's vi-history-search-* breaks with hxins (typing beeps; stuck until Ctrl-C)
bindkey -M hxnor -r '/'
bindkey -M hxnor -r '?'

source "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

if (( $+functions[zhm-add-update-region-highlight-hook] )); then
  zhm-add-update-region-highlight-hook
  (( $+functions[fzf-completion] )) \
    && zhm_wrap_widget fzf-completion zhm_fzf_completion \
    && bindkey '^I' zhm_fzf_completion
fi

function _zhm_accept_or_submit() {
  if (( $+widgets[zhm_accept] )); then
    zle zhm_accept
  else
    zle accept-line
  fi
}
zle -N _zhm_accept_or_submit

export ZSH_HELIX_MODE_LOADED=1
