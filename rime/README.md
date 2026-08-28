# Rime / Squirrel Configuration

macOS 鼠须管配置，默认使用 [雾凇拼音](https://github.com/iDvel/rime-ice) 的简体中文全拼方案，并保留常见双拼方案作为可选项。

## Install

```bash
bash ./install.sh
```

也可以从仓库根目录执行：

```bash
make rime_install
```

安装脚本会：

1. 检查并按需安装 Squirrel。
2. 移走 Squirrel.app 内误生成的运行时文件，避免破坏 app 签名导致 macOS 反复弹输入法隐私提示。
3. 备份当前 `~/Library/Rime` 到带时间戳的目录。
4. 下载并复制雾凇拼音配置。
5. 覆盖本目录里的三个定制文件。
6. 重新部署 Rime，并确保简体中文输入源写入 macOS enabled 列表。

脚本不会删除 `*.userdb` 用户词库。已有配置会先整体备份。

如果只想同步本目录里的定制文件，不重新下载雾凇拼音：

```bash
SKIP_RIME_ICE_DOWNLOAD=1 bash ./install.sh
```

## Layout

```
default.custom.yaml   方案列表、候选数量、切换快捷键
rime_ice.custom.yaml  雾凇拼音默认开关：简体、中文标点、Emoji
squirrel.custom.yaml  鼠须管候选窗外观：Catppuccin Latte/Macchiato
install.sh            macOS 安装与部署脚本
```

## Defaults

- 默认方案：`rime_ice`，雾凇拼音全拼。
- 可选双拼：自然码、小鹤、微软、搜狗、智能 ABC、紫光、拼音加加。
- 默认输出：简体中文。
- 候选数量：5 个。
- 标点：中文标点。
- Emoji：开启。
- 皮肤：明亮模式 Catppuccin Latte，深色模式 Catppuccin Macchiato。

## Useful Keys

| Keys | Action |
| --- | --- |
| `F4` | 打开方案和开关菜单 |
| `Control+\`` | 打开方案和开关菜单 |
| `Control+Shift+4` | 切换简体/繁体 |
| `Control+Shift+3` | 切换中英文标点 |
| `Shift_L` | 提交当前编码并切换英文 |
| `-` / `=` | 候选翻页 |
| `[` / `]` | 以词定字，取当前候选词首字/末字 |

## Update

重新执行安装脚本即可更新雾凇拼音并重新应用本目录的定制配置。更新前脚本会备份当前 `~/Library/Rime`。
