# Kitty 配置

## 安装

先安装 Kitty 和配置使用的 Anonymice Nerd Font：

```bash
brew install --cask kitty font-anonymice-nerd-font
```

再复制配置：

```bash
mkdir -p ~/.config/kitty
cp kitty/kitty.conf ~/.config/kitty/kitty.conf
```

如果当前就在 `kitty/` 目录：

```bash
mkdir -p ~/.config/kitty
cp kitty.conf ~/.config/kitty/kitty.conf
```

## 常用快捷键

`kitty_mod` 默认是 `Ctrl+Shift`。

| 按键 | 操作 |
| --- | --- |
| `kitty_mod+Enter` | 在当前目录新建窗口 |
| `kitty_mod+N` | 新建系统窗口 |
| `kitty_mod+T` | 新建标签页 |
| `kitty_mod+Q` | 关闭标签页 |
| `kitty_mod+[` / `kitty_mod+]` | 切换窗口 |
| `kitty_mod+Left` / `kitty_mod+Right` | 切换标签页 |
| `kitty_mod+F2` | 编辑配置 |
| `kitty_mod+F11` | 切换全屏 |
| `Super+=` / `Super+-` | 调整字号 |

修改配置后，重启 Kitty 或重新加载配置即可生效。
