# VDeamoV-dotfiles
Collection for my dotfiles

<!-- vim-markdown-toc GitLab -->

* [Requirements](#requirements)
* [VIM](#vim)
  * [Installation](#installation)
* [Tmux](#tmux)
  * [Installation](#installation-1)
* [Zsh](#zsh)
  * [Installation](#installation-2)
    * [Auto Installation](#auto-installation)
    * [Manually Install](#manually-install)

<!-- vim-markdown-toc -->
## Requirements 

Check the requirements in `requirements-list` folder and install all apps and
packages.

## VIM
### Installation
```bash
bash ./vim/install.sh
```

## Tmux
### Installation

You can install tmux and config it automatically on ubuntu / Mac OS with
following command.

```bash
bash ./tmux/install.sh
```

## Zsh
### Installation
#### Auto Installation

```bash
bash ./zsh/install.sh
```

#### Manually Install
1. Basic Install Steps

```bash
sudo apt-get install zsh # linux
brew install zsh # mac

# ===> install oh_my_zsh
git clone git://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc

# 设置 zsh 默认启动
chsh -s /bin/zsh

# 从个人的 dotfile 备份恢复设置
git clone https://github.com/VDeamoV/vdeamov-dotfiles.git
cp vdeamov-dotfiles/zsh/zshrc ~/.zshrc
cp -rf vdeamov-dotfiles/zsh/.zsh-config ~/.zsh-config

# 恢复主题
https://github.com/iplaces/astro-zsh-theme.git
cp astro.zsh-theme ~/.oh-my-zsh/themes/

# set ZSH_THEME="astro" in the ~/.zshrc
```

2. Plugin Install Steps

- [Plugin] Zsh-syntax-highlighting

  ```bash
  git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting

  # set zsh-syntax-highlighting in the plugin configure int ~/.zshrc
  # default this configure have completed with my vimrc
  ```

- [Plugin] Zsh-autosuggestions

  ```bash
  git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions

  # set zsh-syntax-highlighting in the plugin configure int ~/.zshrc
  # default this configure have completed with my vimrc
  ```

  test
