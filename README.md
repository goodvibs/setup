# Setup

Quickly reproduce my dev setup on a Mac.

## Prerequisites

- macOS
- Homebrew
- Git

## Quick Start

```bash
git clone <repo-url> setup && cd setup
git submodule update --init --recursive
./scripts/symlink-dotfiles.sh -f   # or -b for backup
./scripts/install-plugins.sh      # optional, requires zvm and git-open
```

## Repository Structure

| Path                | Purpose                                                                 |
| ------------------- | ----------------------------------------------------------------------- |
| `dotfiles/`         | Dotfiles and configs symlinked into `$HOME`                             |
| `dotfiles/.config/` | App configs (nvim as git submodule, karabiner, aerospace, zellij, etc.) |
| `scripts/`          | Setup scripts                                                           |
| `plugins/`          | Custom tools and install scripts                                        |

## Scripts

**symlink-dotfiles.sh** — Symlinks dotfiles into `$HOME`:

- `.zshrc`, `.zshenv`, `.p10k.zsh`, `.config` → `$HOME`
- `plugins/bin` → `$HOME/Developer/plugins/bin`
- Options: `-n` dry-run, `-f` force, `-b` backup, `-i` interactive, `-v` verbose

**install-plugins.sh** — Runs each script in `plugins/install-scripts/`:

- `zvm.sh` — Builds zvm from sibling `../zvm`, outputs to `plugins/bin/`
- `git-open.sh` — Copies git-open from sibling `../git-open` to `plugins/bin/`

Requires zvm and git-open as sibling directories of the setup repo.

## Local Overrides

- `~/.zshrc.local` — Sourced by `.zshrc` for machine-specific overrides
