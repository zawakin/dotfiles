# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Workflow

- **Trunk flow: commit on `main` and push, no PRs.** Declared as `gw.flow = trunk`
  (`git/.gitconfig` includes `~/.gitconfig.trunk` for `~/dotfiles/`), so `gw status`
  shows it.

## Development Commands

### Setup and Installation (New PC)
```bash
# 1. Install Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Install stow (required for dotfiles management)
brew install stow

# 3. Complete setup - installs all configurations
make
```

### Setup specific components
make help                # Show all available targets
make osx-config         # Apply macOS settings (writes only what differs)
make osx-check          # Show drift between osx-config.sh and this machine
make git                # Setup Git configuration
make ssh                # Setup SSH configuration  
make vim                # Setup Vim configuration
make fish               # Setup Fish shell configuration
make homebrew           # Install Homebrew packages and configure
```

### Package Management
```bash
make mise-install # install mise (via brew) and `mise install` (rust gives cargo)
make homebrew     # install everything in ~/.Brewfile (mise exec -- brew bundle --global)
make brew-dump    # machine -> repo: rewrite homebrew/.Brewfile from what is installed
make brew-check   # show drift in both directions without changing anything
```

Homebrew policy: `homebrew/.Brewfile` (stowed to `~/.Brewfile`) is the only
tracked file. There is no lock file; `brew bundle` on Homebrew >= 4.5 does not
write one and versions are not pinned. The machine is the source of truth:
install with `brew install` or `cargo install`, run `make brew-dump`, commit.
Do not hand-edit the Brewfile except to delete an entry before
`brew bundle cleanup --global --force`. Scope: formulae, casks, taps, cargo
(VS Code and npm excluded). `make all` order is osx-config -> stow-all ->
homebrew, because brew bundle's cargo entries need cargo from mise first.
Own crates with a name collision on crates.io are installed `--git` so the dump
records a `source:` (rep). `wf` is in a private repo and is filtered out of
the public Brewfile by `make brew-dump`; install it by hand on a new machine.

## Architecture and Structure

This is a personal dotfiles repository that manages development environment configuration across multiple tools and applications. The architecture follows a modular approach where each tool has its own setup target.

### Configuration Components

**Core System Configuration:**
- `osx-config.sh` - macOS settings as data (`SETTINGS` = host|domain|key|type|value, `DOCK_APPS`, `SPACE_HOTKEYS`); `apply` writes only what differs, `check` reports drift. Machine is the source of truth: run `make osx-check`, copy the `now` value in, commit. Spaces count/order are not scriptable and stay manual.
- `Makefile` - Main orchestration for all setup tasks

**Development Tools:**
- Git configuration with conditional includes for different organizations
- Vim configuration with custom settings and plugin management
- Fish shell with custom aliases and environment variables
- `tw` (fish function) - tmux workspaces with explicit verbs: `tw save` dumps the live session (windows, panes, `#{window_layout}`, pane commands) to `~/.config/tmux/workspaces/<session>.conf` and diffs before overwriting; `tw up <name>` validates then builds it with pane commands typed but not executed (`--run` executes); `tw attach` only attaches. Files are gitignored (private repo paths); `dotfiles.conf` is the committed example
- SSH configuration with host-specific settings

**Package Management:**
- `homebrew/.Brewfile` - Package list (formulae, casks, taps, cargo crates), regenerated from the machine via `make brew-dump` (VS Code and npm are intentionally excluded)
- Includes development tools (git, vim, jq, etc.) and applications (Docker, iTerm2, Zed, etc.)

### Key Features

**Git Configuration:**
- Conditional configuration for different repositories (knowledge-work organization)
- Custom aliases for common Git operations
- Commit template and global ignore file setup

**Fish Shell Setup:**
- Custom aliases for Git operations (gs, gco, gd, etc.)
- Docker and system utilities shortcuts
- GOPATH and PATH configuration

**Vim Configuration:**
- Custom encoding, display, and behavior settings
- Plugin management via vim-plug
- Optimized for development work

**SSH Configuration:**
- Modular configuration with separate files for different hosts
- GitHub-specific configuration

### File Structure
```
.
├── Makefile                    # Main setup orchestration
├── homebrew/
│   └── .Brewfile               # Package definitions (stowed to ~/.Brewfile; `brew bundle --global`)
├── claude/
│   └── .claude/
│       ├── CLAUDE.md           # Global instructions (→ ~/.claude/CLAUDE.md)
│       ├── agents/             # Subagent definitions: scout / worker / reviewer
│       ├── hooks/              # Hook scripts; registered in ~/.claude/settings.json (untracked)
│       └── skills/             # Symlinks into each skill's own repo (make claude-skills)
├── agents/
│   └── .agents/skills/         # Shared agent skills (symlinked to ~/.agents/skills)
├── osx-config.sh              # macOS system configuration
├── .gitconfig                 # Git configuration
├── .gitconfig.kw              # Knowledge-work specific Git config
├── .gitconfig.trunk           # gw.flow = trunk, included for trunk-flow repos
├── .vimrc                     # Vim configuration
├── tmux/
│   ├── .tmux.conf
│   └── .config/tmux/workspaces/ # tw workspaces (gitignored except dotfiles.conf)
├── .config/
│   ├── fish/
│   │   ├── config.fish        # Fish shell configuration
│   │   └── functions/         # Custom Fish functions
│   └── git/
│       ├── ignore             # Global gitignore
│       └── .commit_template   # Git commit template
└── .ssh/
    ├── config                 # SSH configuration
    └── conf.d/                # Host-specific SSH configs
```

## Usage Notes

- All configurations are symlinked to their appropriate locations in `$HOME`
- The setup is idempotent - running `make` multiple times is safe
- SSH and Git configurations support organization-specific settings
- Vim plugins are managed via vim-plug (auto-installed during setup)
- Fish shell includes extensive Git aliases for efficient workflow
