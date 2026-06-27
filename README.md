# Duan-JM's dotfiles

This repo collected my basic develop tools configuration. Install methods are
described below each sub folders.

## Tool Lists

- tmux: Use to navigate windows and keep program run in background.
- vim: Main develop editor
- zsh: Use to replace bash.

## Backup Files

```bash
make backup
```

The backup script asks for confirmation when it finds secret-like files or
assignments, such as private keys, token files, or non-placeholder API keys.

## Install Vim

```
make vim_install
```

## Install TMUX

```
make tmux_install
```

## Install ZSH

```
make zsh_install
```
