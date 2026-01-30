## -*- mode: makefile-gmake; -*-

# Variables
DOTFILES_DIR := $(shell pwd)
HOME_DIR := $(HOME)
STOW_TARGET := $(HOME_DIR)

.PHONY: all
all: osx-config stow-all homebrew

.PHONY: help
help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

.PHONY: osx-config
osx-config: ## Setup global system (OS) configurations
	@echo "Setting up macOS configuration..."
	@./osx-config.sh

.PHONY: stow-all
stow-all: ## Setup all configurations using stow
	@echo "Setting up all configurations with stow..."
	@stow -v -t $(STOW_TARGET) git
	@stow -v -t $(STOW_TARGET) ssh
	@stow -v -t $(STOW_TARGET) vim
	@stow -v -t $(STOW_TARGET) fish
	@stow -v -t $(STOW_TARGET) gh
	@stow -v -t $(STOW_TARGET) mise
	@stow -v -t $(STOW_TARGET) homebrew

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

.PHONY: stow-gh
stow-gh: ## Setup GitHub CLI configuration
	@echo "Setting up GitHub CLI configuration..."
	@stow -v -t $(STOW_TARGET) gh

.PHONY: stow-mise
stow-mise: ## Setup mise configuration
	@echo "Setting up mise configuration..."
	@stow -v -t $(STOW_TARGET) mise

.PHONY: stow-homebrew
stow-homebrew: ## Setup Homebrew configuration
	@echo "Setting up Homebrew configuration..."
	@stow -v -t $(STOW_TARGET) homebrew

.PHONY: unstow-all
unstow-all: ## Remove all stow configurations
	@echo "Removing all stow configurations..."
	@stow -v -t $(STOW_TARGET) -D git ssh vim fish gh mise homebrew 2>/dev/null || true

.PHONY: restow-all
restow-all: ## Restow all configurations (useful after updates)
	@echo "Restowing all configurations..."
	@stow -v -t $(STOW_TARGET) -R git ssh vim fish gh mise homebrew

.PHONY: homebrew
homebrew: stow-homebrew ## Install Homebrew packages
	@echo "Installing Homebrew packages..."
	@brew bundle --file=homebrew/Brewfile
	@brew autoupdate --start --upgrade --cleanup --enable-notification

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
.PHONY: git ssh vim fish gh mise
git: stow-git
ssh: stow-ssh
vim: stow-vim
fish: stow-fish
gh: stow-gh
mise: stow-mise
