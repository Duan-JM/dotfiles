.PHONY: backup
backup:
	bash ./scripts/backup.sh

.PHONY: vim_install
vim_install:
	cd ./vim && bash install.sh

.PHONY: tmux_install
tmux_install:
	cd ./tmux && bash install.sh

.PHONY: zsh_install
zsh_install:
	cd ./zsh && bash install.sh
