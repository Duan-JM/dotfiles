# macOS 软件清单

这个目录记录新 Mac 的常用软件，分为 Homebrew Bundle 和手动安装清单。

## Homebrew Bundle

[`brewAppFile`](brewAppFile) 包含命令行工具、桌面应用、字体和 VS Code 扩展。

检查缺少的软件：

```bash
brew bundle check --file=macos/brewAppFile
```

安装清单中的软件：

```bash
brew bundle --file=macos/brewAppFile
```

如果当前就在 `macos/` 目录，可以省略路径中的 `macos/`。

## 手动安装

- [开发软件](dev-applications.md)
- [日常软件](life-applications.md)

这些清单只记录当前使用的软件，不保证全部适合其他机器。安装前请按需要取舍。
