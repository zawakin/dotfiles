## -*- mode: makefile-gmake; -*-

# Variables
DOTFILES_DIR := $(shell pwd)
HOME_DIR := $(HOME)
STOW_TARGET := $(HOME_DIR)

.PHONY: all
all: osx-config homebrew stow-all

.PHONY: help
help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

.PHONY: osx-config
osx-config: ## Setup global system (OS) configurations
	@echo "Setting up macOS configuration..."
	@./osx-config.sh

.PHONY: stow-all
stow-all: stow-git stow-ssh stow-vim stow-fish stow-gh stow-mise stow-homebrew stow-tmux stow-claude iterm2 ## Setup all configurations using stow

.PHONY: iterm2
iterm2: ## Setup iTerm2 to load preferences from dotfiles
	@echo "Setting up iTerm2 preferences..."
	@defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
	@defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$(DOTFILES_DIR)/iterm2"

.PHONY: stow-git
stow-git: ## Setup Git configuration
	@echo "Setting up Git configuration..."
	@stow -v -t $(STOW_TARGET) git

.PHONY: stow-ssh
stow-ssh: ## Setup SSH configuration
	@echo "Setting up SSH configuration..."
	@stow -v -t $(STOW_TARGET) ssh

.PHONY: stow-vim
stow-vim: ## Setup Vim configuration
	@echo "Setting up Vim configuration..."
	@stow -v -t $(STOW_TARGET) vim
ifeq ($(shell command -v vim 2>/dev/null),)
	@echo "Vim not found, skipping vim-plug installation"
else
	@curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
endif

.PHONY: stow-fish
stow-fish: ## Setup Fish configuration
	@echo "Setting up Fish configuration..."
	@stow -v -t $(STOW_TARGET) fish
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

.PHONY: stow-gh
stow-gh: ## Setup GitHub CLI configuration
	@echo "Setting up GitHub CLI configuration..."
	@stow -v -t $(STOW_TARGET) gh

.PHONY: stow-mise
stow-mise: ## Setup mise configuration
	@echo "Setting up mise configuration..."
	@stow -v -t $(STOW_TARGET) mise

.PHONY: stow-tmux
stow-tmux: ## Setup tmux configuration
	@echo "Setting up tmux configuration..."
	@stow -v -t $(STOW_TARGET) tmux

.PHONY: stow-homebrew
stow-homebrew: ## Setup Homebrew configuration
	@echo "Setting up Homebrew configuration..."
	@stow -v -t $(STOW_TARGET) homebrew

.PHONY: stow-claude
stow-claude: ## Setup Claude Code skills configuration
	@echo "Setting up Claude Code skills configuration..."
	@stow -v -t $(STOW_TARGET) claude

.PHONY: unstow-all
unstow-all: ## Remove all stow configurations
	@echo "Removing all stow configurations..."
	@stow -v -t $(STOW_TARGET) -D git ssh vim fish gh mise homebrew tmux claude 2>/dev/null || true

.PHONY: restow-all
restow-all: ## Restow all configurations (useful after updates)
	@echo "Restowing all configurations..."
	@stow -v -t $(STOW_TARGET) -R git ssh vim fish gh mise homebrew tmux claude

.PHONY: homebrew
homebrew: stow-homebrew ## Install Homebrew packages
	@echo "Installing Homebrew packages..."
	@brew bundle --file=homebrew/Brewfile

.PHONY: clean
clean: ## Clean up broken symlinks
	@echo "Cleaning up broken symlinks..."
	@find $(HOME_DIR) -type l -exec test ! -e {} \; -delete 2>/dev/null || true

.PHONY: claude-workspace-cleanup
claude-workspace-cleanup: ## Clean up Claude workspace temporary files
	@echo "Cleaning up Claude workspace temporary files..."
	@find $(HOME_DIR) -name ".claude_workspace*" -type f -delete 2>/dev/null || true
	@find $(HOME_DIR) -name "claude_workspace*" -type f -delete 2>/dev/null || true

# Legacy targets for backward compatibility
.PHONY: git ssh vim fish gh mise tmux claude
git: stow-git
ssh: stow-ssh
vim: stow-vim
fish: stow-fish
gh: stow-gh
mise: stow-mise
tmux: stow-tmux
claude: stow-claude
