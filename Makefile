.PHONY: backup
backup:
	bash ./scripts/backup.sh

.PHONY: vim_install
vim_install:
	cd ./vim && bash install.sh

.PHONY: sudo_vim_install
vim_install:
	cd ./vim && bash install.sh sudo

.PHONY: tmux_install
tmux_install:
	cd ./tmux && bash install.sh

.PHONY: sudo_tmux_install
tmux_install:
	cd ./tmux && bash install.sh sudo

.PHONY: zsh_install
zsh_install:
	cd ./zsh && bash install.sh

.PHONY: sudo_zsh_install
zsh_install:
	cd ./zsh && bash install.sh sudo
