# Zsh 配置

这套配置基于 Oh My Zsh，启用了 Git、Poetry、命令自动建议和语法高亮，并加载 `~/.zsh-config/` 下的别名与工具配置。

## 安装

在仓库根目录执行：

```bash
make zsh_install
```

也可以进入当前目录直接运行：

```bash
bash ./install.sh
```

脚本支持 macOS 和使用 APT 的 Linux，会按需安装 Zsh、Git、fzf 和 Oh My Zsh，并复制以下配置：

```text
zshrc        -> ~/.zshrc
.zsh-config  -> ~/.zsh-config
```

脚本还会安装：

- `zsh-syntax-highlighting`
- `zsh-autosuggestions`
- `astro-zsh-theme`

## 注意事项

- 安装会覆盖现有的 `~/.zshrc` 和 `~/.zsh-config`，请先自行备份。
- 配置中包含本机路径和开发环境变量，换机器后需要按实际环境调整。
- 安装结束后，如果默认 Shell 仍不是 Zsh，可执行 `chsh -s "$(command -v zsh)"`。
- Oh My Zsh 的自动更新已关闭，需要时请手动执行 `omz update`。
