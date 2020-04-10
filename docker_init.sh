#!/bin/bash
SUDO_FLAG=$1

# install ssh
${SUDO_FLAG} apt install openssh_client
${SUDO_FLAG} apt install openssh_server

${SUDO_FLAG} echo "PORT 8989" >> /etc/ssh/sshd_config
${SUDO_FLAG} /etc/init.d/ssh restart

${SUDO_FLAG} install htop

# install zsh, tmux, neovim
bash ./oh_my_zsh_auto_install.sh  ${SUDO_FLAG}
bash ./tmux_auto_install.sh  ${SUDO_FLAG}
bash ./vim_auto_install.sh  ${SUDO_FLAG}

echo "Need to manual install plugins in tmux and vim"

# install anaconda
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
${SUDO_FLAG} bash ./Miniconda3-latest-Linux-x86_64.sh

# packages
conda install gpustat tqdm loguru
conda install torch torchvision

