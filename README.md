# dotfiles

个人开发环境配置，主要用于 macOS，也保留了 Neovim、Tmux 和 Zsh 的 Linux 安装脚本。

仓库包含终端、编辑器、Shell、macOS 软件清单、AI 工具配置，以及一套可独立构建的 `code-cli` 容器环境。建议按需安装，不要一次执行所有脚本。

## 快速开始

```bash
git clone https://github.com/Duan-JM/dotfiles.git
cd dotfiles
```

安装常用配置：

```bash
make vim_install
make tmux_install
make zsh_install
```

安装脚本可能通过 Homebrew 或 APT 安装依赖，并修改 Home 目录下的配置。执行前请先阅读对应目录的说明：

- [Neovim](vim/README.md)
- [Tmux](tmux/README.md)
- [Zsh](zsh/README.md)
- [Kitty](kitty/README.md)

## 目录

| 路径 | 内容 |
| --- | --- |
| [`vim/`](vim/) | 基于 Lua 和 lazy.nvim 的 Neovim 配置 |
| [`tmux/`](tmux/) | Tmux 配置、快捷键和插件 |
| [`zsh/`](zsh/) | Zsh、Oh My Zsh、插件和个人命令配置 |
| [`kitty/`](kitty/) | Kitty 终端配置 |
| [`macos/`](macos/) | Homebrew Bundle 与常用应用清单 |
| [`copilot/`](copilot/) | GitHub Copilot CLI 设置与 hooks |
| [`ai-settings/`](ai-settings/) | AI 工具使用的规则、技能和模板 |
| [`docker_files/code-cli/`](docker_files/code-cli/) | 集成 Zsh、Tmux 和 Neovim 的容器环境 |
| [`scripts/`](scripts/) | 本地配置备份脚本 |

## macOS 软件

使用 Homebrew Bundle 检查或安装 [`macos/brewAppFile`](macos/brewAppFile) 中的软件：

```bash
brew bundle check --file=macos/brewAppFile
brew bundle --file=macos/brewAppFile
```

不适合通过 Homebrew 管理的软件记录在 [`macos/`](macos/) 的应用清单中。

## 备份本地配置

```bash
make backup
```

脚本会把当前的 Neovim、Tmux、Zsh 和 Kitty 配置复制回仓库。遇到私钥、令牌文件、非占位 API Key 等疑似敏感内容时，会先给出警告并要求确认。

备份完成后，请在提交前检查改动：

```bash
git status --short
git diff
```

不要把真实密钥、Token 或公司内部地址提交到仓库。

## code-cli 容器

`docker_files/code-cli` 提供 `core`、`python`、`rust`、`go` 和 `ops` 五种镜像。`ops` 包含数据库客户端与网络排障工具；构建方式、平台支持和验证命令见 [code-cli 文档](docker_files/code-cli/README.md)。

## License

[MIT](LICENSE)
