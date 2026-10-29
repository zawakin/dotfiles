## -*- mode: makefile-gmake; -*-
#
# Thin task runner for this dotfiles repo. Nothing here is a real build: every
# target is phony, make is used because it ships with the Xcode Command Line
# Tools and so works on a fresh machine before anything else is installed.

DOTFILES_DIR := $(CURDIR)
STOW_TARGET  := $(HOME)
BREWFILE     := $(DOTFILES_DIR)/homebrew/.Brewfile

# Every stow package: `stow-<name>` links it, `<name>` is a short alias.
PACKAGES     := git ssh vim fish gh mise homebrew tmux claude agents
STOW_TARGETS := $(addprefix stow-,$(PACKAGES))

.DEFAULT_GOAL := all

# ---------------------------------------------------------------------------
# Top level
# ---------------------------------------------------------------------------

# Order matters on a fresh machine: stow first (links ~/.Brewfile and the mise
# config), then homebrew, which installs mise, runs `mise install` (rust gives
# cargo) and only then `brew bundle`, whose cargo entries need cargo on PATH.
all: osx-config stow-all homebrew ## Complete setup (osx-config + stow-all + homebrew)

help: ## Show this help message
	@grep -E '^[a-zA-Z_%-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo
	@echo "One package: make stow-<pkg> (alias: make <pkg>), pkg in: $(PACKAGES)"

osx-config: ## Apply macOS settings (defaults, Dock apps, Mission Control hotkeys)
	@echo "Setting up macOS configuration..."
	@./osx-config.sh

osx-check: ## Show drift between osx-config.sh and this machine (no changes made)
	@./osx-config.sh check

# ---------------------------------------------------------------------------
# Stow
# ---------------------------------------------------------------------------

stow-all: $(STOW_TARGETS) vim-plug fish-shell iterm2 ## Link all packages and run their post-steps

# Static pattern rule (not `stow-%:`): phony targets skip implicit rule search,
# and this also rejects package names that are not in PACKAGES.
$(STOW_TARGETS): stow-%:
	@echo "Stowing $*..."
	@stow -v -t $(STOW_TARGET) $*

unstow-all: ## Unlink all packages
	@echo "Removing all stow configurations..."
	@stow -v -t $(STOW_TARGET) -D $(PACKAGES) 2>/dev/null || true

restow-all: ## Relink all packages (useful after updates)
	@echo "Restowing all configurations..."
	@stow -v -t $(STOW_TARGET) -R $(PACKAGES)

# Packages with extra requirements or post-steps.
stow-claude stow-agents: claude-skills
stow-claude: claude-settings

claude-skills: ## Symlink Claude skills from their ghq-managed repos
	@echo "Linking Claude skills from ghq repositories..."
	@./scripts/link-claude-skills.sh

claude-settings: ## Merge claude-settings.json into ~/.claude/settings.json (writes only what differs)
	@./scripts/claude-settings.sh

claude-settings-check: ## Show drift between claude-settings.json and ~/.claude/settings.json (no changes made)
	@./scripts/claude-settings.sh check

vim-plug: stow-vim ## Install vim-plug (skipped when vim is missing)
	@if command -v vim >/dev/null 2>&1; then \
		curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim; \
	else \
		echo "Vim not found, skipping vim-plug installation"; \
	fi

fish-shell: stow-fish ## Register fish in /etc/shells and make it the login shell
	@FISH_PATH=$$(command -v fish 2>/dev/null); \
	if [ -n "$$FISH_PATH" ]; then \
		if ! grep -q "$$FISH_PATH" /etc/shells; then \
			echo "Adding $$FISH_PATH to /etc/shells..."; \
			echo "$$FISH_PATH" | sudo tee -a /etc/shells; \
		fi; \
		if [ "$$SHELL" != "$$FISH_PATH" ]; then \
			echo "Setting fish as default shell..."; \
			chsh -s "$$FISH_PATH"; \
		fi; \
	else \
		echo "Fish not installed yet, skipping default shell setup. Run 'make fish' after 'make homebrew'."; \
	fi

iterm2: ## Setup iTerm2 to load preferences from dotfiles
	@echo "Setting up iTerm2 preferences..."
	@defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
	@defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$(DOTFILES_DIR)/iterm2"

# Short aliases: `make git` == `make stow-git`; vim and fish also run their post-step.
$(PACKAGES): %: stow-%
vim: vim-plug
fish: fish-shell

# ---------------------------------------------------------------------------
# Homebrew
# ---------------------------------------------------------------------------
#
# ~/.Brewfile (stowed from homebrew/.Brewfile) is the single source of truth;
# no lock file is tracked (brew bundle no longer writes one). The machine is
# authoritative: install with `brew install` / `cargo install`, then
# `make brew-dump` to record.
# Scope is formulae/casks/taps/cargo. VS Code is no longer used; npm globals are
# not brew's job here (mise-managed node would not reinstall). Own crates whose
# name is taken on crates.io must be installed with `cargo install --git <url>`
# so the dump records a `source:`; a bare name would install the wrong crate.
# `wf` lives in a private repo, so it is dropped from the public Brewfile and
# installed by hand (see README).

mise-install: stow-mise ## Install mise (via brew) and the tools in ~/.config/mise/config.toml
	@command -v mise >/dev/null 2>&1 || brew install mise
	@echo "Installing mise-managed tools..."
	@mise install

homebrew: stow-homebrew mise-install ## Install Homebrew packages (and cargo crates) from ~/.Brewfile
	@echo "Installing Homebrew packages..."
	@mise exec -- brew bundle --global

brew-dump: stow-homebrew ## Rewrite ~/.Brewfile from what is installed on this machine
	@echo "Dumping installed Homebrew packages to ~/.Brewfile..."
	@mise exec -- brew bundle dump --global --force --no-describe --formula --cask --tap --cargo
	@sed -i '' '/^cargo "wf"\(,.*\)\{0,1\}$$/d' $(BREWFILE)
	@git -C $(DOTFILES_DIR) --no-pager diff --stat -- homebrew/.Brewfile

brew-check: stow-homebrew ## Show drift between ~/.Brewfile and this machine (no changes made)
	@echo "Missing on this machine (listed in Brewfile):"
	@mise exec -- brew bundle check --global --verbose || true
	@echo
	@echo "Installed but not in Brewfile (brew bundle cleanup --global --force would remove):"
	@mise exec -- brew bundle cleanup --global

# ---------------------------------------------------------------------------
# Maintenance
# ---------------------------------------------------------------------------

clean: ## Clean up broken symlinks under $HOME
	@echo "Cleaning up broken symlinks..."
	@find $(HOME) -type l -exec test ! -e {} \; -delete 2>/dev/null || true

claude-workspace-cleanup: ## Clean up Claude workspace temporary files
	@echo "Cleaning up Claude workspace temporary files..."
	@find $(HOME) -name ".claude_workspace*" -type f -delete 2>/dev/null || true
	@find $(HOME) -name "claude_workspace*" -type f -delete 2>/dev/null || true

.PHONY: all help osx-config osx-check stow-all unstow-all restow-all claude-skills claude-settings \
        claude-settings-check vim-plug fish-shell iterm2 \
        $(PACKAGES) $(STOW_TARGETS) \
        mise-install homebrew brew-dump brew-check clean claude-workspace-cleanup
