# zawakin/dotfiles

Modern dotfiles management using GNU stow for better organization and maintainability.

## Prerequisites

- [Homebrew](https://brew.sh/)
- GNU stow (`brew install stow`)
- Git
- Make

## Quick Start

```console
# 1. Install Xcode from App Store, then install Command Line Tools
xcode-select --install

# 2. Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 3. Install stow (required before make)
brew install stow

# 4. Clone and setup
git clone git@github.com:zawakin/dotfiles.git
cd dotfiles
make
```

This will:
1. Configure macOS system settings
2. Install and configure all development tools using stow
3. Install Homebrew packages

## Usage

### Setup Commands

```console
make help          # Show all available commands
make               # Complete setup (osx-config + stow-all + homebrew)
make stow-all      # Setup all configurations using stow
make homebrew      # Install Homebrew packages
```

### Individual Package Management

```console
make stow-git      # Setup Git configuration only
make stow-vim      # Setup Vim configuration only
make stow-ssh      # Setup SSH configuration only  
make stow-fish     # Setup Fish shell configuration only
make stow-homebrew # Setup Homebrew configuration only
```

### Maintenance Commands

```console
make unstow-all    # Remove all stow configurations
make restow-all    # Restow all configurations (useful after updates)
make clean         # Clean up broken symlinks
```

## Architecture

This dotfiles repository uses **GNU stow** for package management, providing:

- **Modular organization**: Each tool has its own package directory
- **Easy maintenance**: Individual packages can be managed separately
- **Portable**: Moving the entire dotfiles directory is simple
- **Safe**: Conflicts are detected before changes are made

### Directory Structure

```
dotfiles/
├── git/           # Git configuration package
│   ├── .gitconfig
│   ├── .gitconfig.kw
│   └── .config/git/
├── vim/           # Vim configuration package
│   └── .vimrc
├── ssh/           # SSH configuration package
│   └── .ssh/
├── fish/          # Fish shell configuration package
│   └── .config/fish/
├── homebrew/      # Homebrew configuration package
│   └── Brewfile
└── Makefile       # Main setup orchestration
```

## Moving Dotfiles Directory

Thanks to stow-based management, moving the dotfiles directory is straightforward:

```console
mv /current/path/dotfiles /new/path/
cd /new/path/dotfiles  
make stow-all
```

## Legacy Support

For backward compatibility, legacy commands are still available:

```console
make git    # Same as make stow-git
make vim    # Same as make stow-vim
make ssh    # Same as make stow-ssh
make fish   # Same as make stow-fish
```
