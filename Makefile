## -*- mode: makefile-gmake; -*-

.PHONY: all
all: osx-config git ssh vim zsh fish homebrew

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

.PHONY: osx-config
osx-config: ## Setup global system (OS) configurations
	./osx-config.sh

.PHONY: git
git: ## Setup Git configuration
	ln -vsf ${PWD}/.gitconfig ${HOME}
	mkdir -p ${HOME}/.config/git
	ln -vsf ${PWD}/.config/git/ignore ${HOME}/.config/git/ignore

.PHONY: ssh
ssh: ## Setup ssh configuration
	ln -vsf ${PWD}/.ssh/conf.d ${HOME}/.ssh/
	ln -vsf ${PWD}/.ssh/config ${HOME}/.ssh/

.PHONY: vim
vim: ## Setup Vim configuration
	ln -vsf ${PWD}/.vimrc ${HOME}
	curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

.PHONY: zsh
zsh: ## Setup Zsh configuration
	ln -vsf ${PWD}/.zshrc ${HOME}

.PHONY: fish
fish: ## Setup Fish configuration
	mkdir -p ${HOME}/.config/fish
	mkdir -p ${HOME}/.config/fish/functions
	ln -vsf ${PWD}/.config/fish/config.fish ${HOME}/.config/fish/config.fish
	ln -vsf ${PWD}/.config/fish/fish_variables ${HOME}/.config/fish/fish_variables
	ln -vsf ${PWD}/.config/fish/functions/fish_prompt.fish ${HOME}/.config/fish/functions/fish_prompt.fish

.PHONY: homebrew
homebrew: ## Setup Homebrew configuration
	ln -vsf ${PWD}/Brewfile ${HOME}
	brew bundle
	brew autoupdate --start --upgrade --cleanup --enable-notification
