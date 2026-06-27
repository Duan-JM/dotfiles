ROOT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
SUDO ?= sudo
INSTALL_ENV := NONINTERACTIVE=1 HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_CLEANUP=1

.PHONY: backup
backup:
	bash "$(ROOT_DIR)/scripts/backup.sh"

.PHONY: common_tools_install
common_tools_install:
	$(SUDO) -v
	cd "$(ROOT_DIR)/common_tools" && env $(INSTALL_ENV) bash install.sh "$(SUDO)"

.PHONY: vim_install
vim_install:
	$(SUDO) -v
	cd "$(ROOT_DIR)/vim" && env $(INSTALL_ENV) bash install.sh "$(SUDO)"

.PHONY: sudo_vim_install
sudo_vim_install:
	@echo "WARNING: sudo_vim_install is deprecated; use vim_install instead."
	$(MAKE) --no-print-directory vim_install

.PHONY: tmux_install
tmux_install:
	$(SUDO) -v
	cd "$(ROOT_DIR)/tmux" && env $(INSTALL_ENV) bash install.sh "$(SUDO)"

.PHONY: sudo_tmux_install
sudo_tmux_install:
	@echo "WARNING: sudo_tmux_install is deprecated; use tmux_install instead."
	$(MAKE) --no-print-directory tmux_install

.PHONY: zsh_install
zsh_install:
	$(SUDO) -v
	cd "$(ROOT_DIR)/zsh" && env $(INSTALL_ENV) bash install.sh "$(SUDO)"

.PHONY: sudo_zsh_install
sudo_zsh_install:
	@echo "WARNING: sudo_zsh_install is deprecated; use zsh_install instead."
	$(MAKE) --no-print-directory zsh_install
