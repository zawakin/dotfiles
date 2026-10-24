# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Workflow

- **Commit directly to `main` and push.** This repo does NOT use pull requests.
  Skip `gw new` / feature branches / `gh pr create` — just stage, commit, and
  `git push` to `origin/main`. This overrides the global git-workflow skill's
  PR-based flow.

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
make osx-config         # Configure macOS system settings
make git                # Setup Git configuration
make ssh                # Setup SSH configuration  
make vim                # Setup Vim configuration
make fish               # Setup Fish shell configuration
make homebrew           # Install Homebrew packages and configure
```

### Package Management
```bash
make homebrew     # install everything in ~/.Brewfile (brew bundle --global)
make brew-dump    # machine -> repo: rewrite homebrew/.Brewfile from what is installed
make brew-check   # show drift in both directions without changing anything
```

Homebrew policy: `homebrew/.Brewfile` (stowed to `~/.Brewfile`) is the only
tracked file. There is no lock file; `brew bundle` on Homebrew >= 4.5 does not
write one and versions are not pinned. The machine is the source of truth:
install with `brew install`, run `make brew-dump`, commit. Do not hand-edit
the Brewfile except to delete an entry before `brew bundle cleanup --global --force`.

## Architecture and Structure

This is a personal dotfiles repository that manages development environment configuration across multiple tools and applications. The architecture follows a modular approach where each tool has its own setup target.

### Configuration Components

**Core System Configuration:**
- `osx-config.sh` - macOS system preferences and UI settings
- `Makefile` - Main orchestration for all setup tasks

**Development Tools:**
- Git configuration with conditional includes for different organizations
- Vim configuration with custom settings and plugin management
- Fish shell with custom aliases and environment variables
- SSH configuration with host-specific settings

**Package Management:**
- `homebrew/.Brewfile` - Package list (formulae, casks, taps), regenerated from the machine via `make brew-dump` (VS Code extensions are intentionally excluded)
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
│   └── .claude/skills/         # Claude Code skills (symlinked to ~/.claude/skills)
├── agents/
│   └── .agents/skills/         # Shared agent skills (symlinked to ~/.agents/skills)
├── osx-config.sh              # macOS system configuration
├── .gitconfig                 # Git configuration
├── .gitconfig.kw              # Knowledge-work specific Git config
├── .vimrc                     # Vim configuration
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
