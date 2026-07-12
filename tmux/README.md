# Tmux 配置

配置使用 `C-b` 作为前缀键，包含窗口与面板管理、Vi 风格复制、会话恢复和状态栏插件。

## 安装

在仓库根目录执行：

```bash
make tmux_install
```

也可以进入当前目录直接运行：

```bash
bash ./install.sh
```

脚本支持 macOS 和使用 APT 的 Linux，会安装 Tmux、复制配置、安装 TPM，并同步插件。现有的 `~/.tmux` 会备份为 `~/.tmux_bak`，`~/.tmux.conf` 会被覆盖。

## 常用命令

```bash
tmux new -s <session-name>
tmux attach -t <session-name>
tmux ls
tmux kill-session -t <session-name>
```

## 快捷键

以下按键都需要先按前缀键 `C-b`。

| 按键 | 操作 |
| --- | --- |
| `n` | 新建窗口 |
| `q` | 关闭当前窗口 |
| `[` / `]` | 上一个或下一个窗口 |
| `Tab` | 切换到上一个活跃窗口 |
| `=` / `-` | 水平或垂直拆分面板 |
| `h` / `j` / `k` / `l` | 切换面板 |
| `C-h` / `C-j` / `C-k` / `C-l` | 调整面板大小 |
| `v` | 进入复制模式 |
| `p` | 粘贴缓冲区 |
| `b` | 开关面板同步输入 |
| `r` | 重新加载配置 |
| `R` | 重新加载配置并刷新客户端 |
| `I` | 安装 TPM 插件 |
| `U` | 更新 TPM 插件 |
| `C-s` | 保存会话 |
| `C-r` | 恢复会话 |

复制模式使用 Vi 键位，按 `y` 或 `c` 会通过 `tmux-cp` 复制选区。
