# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

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
# Install all packages and extensions
brew bundle --file=homebrew/Brewfile
```

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
- `Brewfile` - Comprehensive package list including CLI tools, applications, and VS Code extensions
- Includes development tools (git, vim, jq, etc.), applications (Docker, VS Code, etc.), and VS Code extensions

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
│   └── Brewfile                # Package definitions (Homebrew, casks, VS Code extensions)
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