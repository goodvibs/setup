#!/usr/bin/env bash
set -euo pipefail

# link.sh — symlink dotfiles into $HOME
#
# Options:
#   -n, --dry-run        Show what would happen
#   -f, --force          Remove existing targets before linking
#   -b, --backup         Backup existing targets before linking
#   -i, --interactive    Ask before replacing each target
#   -v, --verbose        Extra output

DRY_RUN=0
FORCE=0
BACKUP=0
INTERACTIVE=0
VERBOSE=0

log()  { printf '%s\n' "$*"; }
vlog() { [[ "$VERBOSE" -eq 1 ]] && printf '%s\n' "$*"; }
warn() { printf 'WARN: %s\n' "$*" >&2; }
die()  { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

run() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY: $*"
  else
    vlog "RUN: $*"
    eval "$@"
  fi
}

confirm() {
  read -r -p "$1 [y/N] " ans
  [[ "${ans:-}" =~ ^[Yy]$ ]]
}

is_same_symlink() {
  [[ -L "$2" && "$(readlink "$2")" == "$1" ]]
}

backup_target() {
  local target="$1"
  local ts
  ts="$(date +%Y%m%d-%H%M%S)"
  run "mv \"$target\" \"$target.bak.$ts\""
}

remove_target() {
  run "rm -rf \"$1\""
}

link_one() {
  local src="$1"
  local dst="$2"

  if is_same_symlink "$src" "$dst"; then
    vlog "OK: $dst already linked"
    return
  fi

  if [[ -e "$dst" || -L "$dst" ]]; then
    if [[ "$INTERACTIVE" -eq 1 ]] && ! confirm "Replace $dst?"; then
      warn "Skipped: $dst"
      return
    fi

    if [[ "$BACKUP" -eq 1 ]]; then
      backup_target "$dst"
    elif [[ "$FORCE" -eq 1 ]]; then
      remove_target "$dst"
    else
      warn "Conflict: $dst exists (use --backup or --force)"
      return 1
    fi
  fi

  run "ln -s \"$src\" \"$dst\""
  log "Linked: $dst -> $src"
}

usage() {
  sed -n '1,60p' "$0" | sed 's/^# \{0,1\}//'
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -n|--dry-run) DRY_RUN=1 ;;
      -f|--force) FORCE=1 ;;
      -b|--backup) BACKUP=1 ;;
      -i|--interactive) INTERACTIVE=1 ;;
      -v|--verbose) VERBOSE=1 ;;
      -h|--help) usage; exit 0 ;;
      *) die "Unknown option: $1" ;;
    esac
    shift
  done
}

main() {
  parse_args "$@"

  local script_dir dotfiles_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  dotfiles_dir="$script_dir/../dotfiles"

  [[ -d "$dotfiles_dir" ]] || die "Expected dotfiles directory at: $dotfiles_dir"

  vlog "Dotfiles: $dotfiles_dir"
  vlog "Home: $HOME"

  link_one "$dotfiles_dir/.zshrc"    "$HOME/.zshrc"
  link_one "$dotfiles_dir/.zshenv"   "$HOME/.zshenv"
  link_one "$dotfiles_dir/.p10k.zsh" "$HOME/.p10k.zsh"
  link_one "$dotfiles_dir/.config"   "$HOME/.config"

  log "Done."
}

main "$@"
