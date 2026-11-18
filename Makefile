SHELL := /usr/bin/env bash
SCRIPTS := scripts

.DEFAULT_GOAL := help
.PHONY: help install home local engineering bin config agents caps test test-bin test-skills

help: ## list targets
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-12s %s\n", $$1, $$2}'

install: home local engineering bin config agents caps ## everything setup.sh does

home: ## symlink dotfiles (.zshrc, .gitconfig, ...) into $HOME
	@$(SCRIPTS)/link-home-files.sh

local: ## create ~/.gitconfig.local, ~/.zshlocal, ~/.checks.yml, ~/.projects if missing
	@$(SCRIPTS)/create-local-files.sh

engineering: ## git init the ~/engineering vault
	@$(SCRIPTS)/init-engineering-repo.sh

bin: ## symlink bin/ into ~/.bin
	@$(SCRIPTS)/link-bin-files.sh

config: ## symlink config/* into ~/.config
	@$(SCRIPTS)/link-xdg-config.sh

agents: ## link skills into ~/.agents/skills and ~/.claude/skills, agents, mods; merge settings
	@$(SCRIPTS)/install-agents.sh

caps: ## Caps Lock as Ctrl (GNOME only)
	@$(SCRIPTS)/set-caps-lock-ctrl.sh

test: test-bin test-skills ## run all bats tests

test-bin: ## bats tests for bin/ scripts
	bats test_bin/

test-skills: ## bats tests beside skill scripts
	bats $$(find .agents/skills -name '*_test.bats' | sort)
