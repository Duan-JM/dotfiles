# 专利技术交底书生成器

## 项目简介

本项目用于自动生成专利技术交底书。用户在 `input/invention_idea.md` 中填写发明思路，通过 Claude Code Skills 驱动调研、撰写、合并、转换的完整流程。

## 语言要求

- 所有交底书内容必须使用**中文**撰写
- 代码注释和脚本输出使用中文

## 项目结构

```
input/
  invention_idea.md          # 用户填写发明思路（必填，支持配置 Notion 页面链接）
  reference_patents/         # 参考专利文件（可选，放入 .md 文件）
output/
  research_report.md         # 调研报告（自动生成）
  sections/                  # 各章节文件（自动生成）
    01_technical_problem.md
    02_technical_background.md
    03_defects_and_purpose.md
    04_technical_solution.md
    05_key_points.md
  disclosure.md              # 合并后的完整交底书
  disclosure.docx            # Word 格式交底书
templates/
  disclosure_template.md     # 各章节的提示词模板
scripts/
  merge.py                   # 合并章节脚本
  convert.sh                 # Markdown → Word 转换脚本
```

## 可用 Skills

| 命令 | 作用 |
|------|------|
| `/patent-research` | 技术调研：读取发明思路，生成调研报告 |
| `/patent-generate` | 章节生成：按顺序生成 5 章交底书内容 |
| `/patent-all` | 全流程：调研 → 生成 → 合并 → 转换 |

## 工具命令

```bash
make merge   # 合并各章节为完整 markdown
make docx    # 转换为 Word 文档（需安装 pandoc）
make clean   # 清理所有生成文件
make help    # 显示帮助
```

## 使用流程

1. 编辑 `input/invention_idea.md`，填入发明思路
2. （可选）在 `invention_idea.md` 顶部的「Notion 页面链接」部分粘贴 Notion 页面 URL，系统会自动获取并合并 Notion 内容作为补充
3. （可选）在 `input/reference_patents/` 放入参考专利 .md 文件
4. 在 Claude Code 中运行 `/patent-all` 完成全流程
5. 或分步执行：先 `/patent-research`，再 `/patent-generate`，最后 `make merge && make docx`

## 公式格式约定

- 所有数学公式使用 **LaTeX 格式**
- 行内公式：`$...$`（例：$E = mc^2$）
- 独立公式块：`$$...$$`
- 禁止使用 Unicode 数学符号或加粗文字替代公式
