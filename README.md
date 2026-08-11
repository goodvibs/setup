# Setup

Quickly reproduce my dev setup on a Mac.

## Prerequisites

- macOS
- Homebrew
- Git
- Python 3.11+ (for the dotfiles CLI)

## Quick Start

```bash
git clone git@github.com:goodvibs/dotfiles.git && cd setup
./bin/dotfiles bootstrap          # submodule sync + symlink apply
brew bundle                       # optional: install packages from Brewfile
./scripts/install-plugins         # optional: build custom tools (zvm, git-open, …)
```

## How It Works

Configs live in `configs/`. `manifest.toml` maps each file or directory to one symlink target — the path each tool actually reads. `dotfiles apply` creates those links.

```
configs/          manifest.toml          $HOME
─────────         ─────────────          ─────
configs/git/  ──► ~/.config/git      ──► ~/.config/git -> configs/git
configs/zshrc ──► ~/.zshrc           ──► ~/.zshrc -> configs/zshrc
configs/nvim/ ──► ~/.config/nvim     ──► ~/.config/nvim -> configs/nvim
```

## Repository Structure

| Path            | Purpose                                              |
| --------------- | ---------------------------------------------------- |
| `configs/`      | Config files (inline + git submodules)                |
| `manifest.toml` | Symlink target map                                   |
| `bin/dotfiles`  | CLI: apply, audit, sync, bootstrap, add (default: summary) |
| `lib/dotfiles.py` | Implementation                                   |
| `plugins/`      | Custom tools and install scripts                     |
| `Brewfile`      | Homebrew packages (run `brew bundle` manually)       |

## CLI

```bash
dotfiles                    # summary (default)
dotfiles bootstrap          # new machine: sync submodules + apply links
dotfiles apply [-n] [-f] [-b] [-i] [-v]
dotfiles audit              # manifest vs filesystem drift
dotfiles sync               # git submodule update --init --recursive
dotfiles add <name> --target <path>   # scaffold configs/<name> + manifest entry
```

**apply options:** `-n` dry-run, `-f` force, `-b` backup, `-i` interactive, `-v` verbose

## Adding a Config

Look up where the tool reads its config, then add one manifest entry for that path:

```bash
dotfiles add myapp --target ~/.config/myapp
dotfiles add myapp --target ~/.myapprc
```

## External Repos (Submodules)

| Config | Repository |
| ------ | ---------- |
| nvim   | `goodvibs/nvim-config` |
| helix  | `goodvibs/hx-config` |

Edit inside `configs/nvim` or `configs/helix`, push to the upstream repo, then commit the updated submodule pointer in this repo.

To add a new external config later, add a `[[entry]]` with `[entry.repo]` in `manifest.toml` and run `dotfiles sync`.

## Shell Layout

| Source | Target |
| ------ | ------ |
| `configs/zshenv` | `~/.zshenv` (early `PATH`) |
| `configs/zshrc` | `~/.zshrc` |
| `configs/p10k.zsh` | `~/.p10k.zsh` |
| `configs/zshrc.local` | machine-specific overrides (gitignored; sourced by `.zshrc`) |

Setup repo root is detected from the `~/.zshrc` symlink path (no hardcoded clone location).

## Global Agent Instructions

One file deployed to each tool's global path:

| Source | Target | Tool |
| ------ | ------ | ---- |
| `configs/AGENTS.md` | `~/.config/agents/AGENTS.md` | Shared |
| `configs/AGENTS.md` | `~/.claude/CLAUDE.md` | Claude Code |

Edit `configs/AGENTS.md` only.

Cursor does not read a global `AGENTS.md` from `$HOME`; use **Customize → Rules → User Rules** or mirror this file there.

## Local Overrides

- `configs/zshrc.local` — sourced by `.zshrc` for machine-specific shell config
- Optional manifest entries (`plugins-bin`) are skipped until sources exist
