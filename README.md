# zawakin/dotfiles

Modern dotfiles management using GNU stow for better organization and maintainability.

## Prerequisites

- [Homebrew](https://brew.sh/)
- GNU stow (`brew install stow`)
- Git
- Make

## Quick Start

```console
# 1. Install Xcode from App Store

# 2. Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 3. Install stow (required before make)
brew install stow

# 4. Clone and setup
git clone git@github.com:zawakin/dotfiles.git
cd dotfiles
make
```

This will, in order:
1. Configure macOS system settings
2. Link all configurations with stow (including `~/.Brewfile` and the mise config)
3. Install mise and run `mise install` (rust provides `cargo`)
4. Run `brew bundle --global`: formulae, casks, taps and cargo crates

No GitHub login is needed for any of this: the dotfiles repo is public and every
Brewfile entry comes from Homebrew, crates.io or a public git repo.

## Usage

### Setup Commands

```console
make help          # Show all available commands
make               # Complete setup (osx-config + stow-all + homebrew)
make stow-all      # Setup all configurations using stow
make osx-check     # Show drift between osx-config.sh and this machine
make mise-install  # Install mise and its tools (node, rust, uv, ...)
make homebrew      # Install Homebrew packages and cargo crates from ~/.Brewfile
make brew-dump     # Record what is installed on this machine into the Brewfile
make brew-check    # Show drift between the Brewfile and this machine
```

### Individual Package Management

```console
make stow-git      # Setup Git configuration only
make stow-vim      # Setup Vim configuration only
make stow-ssh      # Setup SSH configuration only  
make stow-fish     # Setup Fish shell configuration only
make stow-homebrew # Setup Homebrew configuration only
```

### Homebrew Packages

`homebrew/.Brewfile` is stowed to `~/.Brewfile`, so every `brew bundle` command
works with `--global` and no `--file` flag. No lock file is tracked: Homebrew
no longer writes one, and versions are intentionally not pinned. The machine is
the source of truth.

```console
brew install <formula>   # install as usual (or cargo install <crate>)
make brew-dump           # rewrite the Brewfile from the installed state
git commit -am "chore(brew): add <formula>"

make brew-check          # see what is missing here / what is extra here
brew bundle cleanup --global --force   # remove extras, after deleting lines you no longer want
```

The dump covers formulae, casks, taps and cargo crates. VS Code extensions and
npm globals are excluded on purpose. Two cargo rules:

- A crate whose name is taken by someone else on crates.io must be installed
  from git so the dump records a `source:`; a bare name would install the wrong
  crate on a new machine. `rep` is installed this way:
  `cargo install --git https://github.com/lanegrid/rep`.
- `wf` lives in a private repo, so `make brew-dump` drops it from this public
  Brewfile. On a new machine, after `gh auth login`, install it by hand with
  `cargo install --git <private repo url>`. Because it is not listed,
  `make brew-check` always reports `wf` as extra and
  `brew bundle cleanup --global --force` would uninstall it; reinstall it
  afterwards if you run that.

### macOS Settings

`osx-config.sh` is a list of `defaults` keys plus the Dock apps and the
control+1..8 "switch to desktop" hotkeys. `make osx-config` writes only what
differs and restarts Dock/Finder as needed; `make osx-check` reports drift
without changing anything. The machine is the source of truth: change a
setting in System Settings, run `make osx-check`, copy the `now` value into
the script, commit.

Not recorded, because macOS does not expose them as plain defaults: the
number and order of Mission Control spaces, per-space wallpapers, and input
sources. Create the spaces by hand after a fresh install; the hotkeys then work.

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
│   └── .Brewfile  # stowed to ~/.Brewfile, used by `brew bundle --global`
├── claude/        # Claude Code skills package
│   └── .claude/skills/
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
