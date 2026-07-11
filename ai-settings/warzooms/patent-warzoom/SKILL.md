---
name: writing-patent-disclosures
description: Generates Chinese patent disclosure packages from invention notes, prior-art references, and optional Notion context. Use when researching patent background, drafting disclosure sections, or running an end-to-end patent disclosure workflow.
---

# Patent Disclosure Writer

## Core Rules

- 所有交底书内容必须使用**中文**撰写。
- 数学公式使用 LaTeX：行内 `$...$`，块级 `$$...$$`。
- 图示使用 Mermaid 代码块。
- 在开始生成前，先确认 `input/invention_idea.md` 不是未填写的占位内容。

## Workspace Layout

```text
input/
  invention_idea.md
  reference_patents/
output/
  research_report.md
  sections/
    01_technical_problem.md
    02_technical_background.md
    03_defects_and_purpose.md
    04_technical_solution.md
    05_key_points.md
  disclosure.md
  disclosure.docx
templates/
  disclosure_template.md
scripts/
  merge.py
  convert.sh
```

## Inputs

1. 读取 `input/invention_idea.md` 完整内容。
2. 检查其中是否包含 Notion 页面链接或 Page ID：
   - 若存在，获取 Notion 页面内容并追加到发明思路末尾。
   - 若获取失败，明确提示失败，但继续后续流程。
3. 读取 `input/reference_patents/` 下全部 `.md` 文件作为参考专利资料。
4. 从 `templates/disclosure_template.md` 中读取对应提示模板。

## Research Workflow

当用户要求做专利调研、现有技术分析、先做背景研究，或提到“调研报告”时：

1. 生成 `output/research_report.md`。
2. 报告至少覆盖：
   - 技术领域定位
   - 技术背景分析
   - 3-5 个最相近技术方案及优缺点
   - 10-15 个专利检索关键词组合
   - 本发明与现有技术的差异化与创新点

## Chapter Workflow

当用户要求生成交底书章节时，必须先确认 `output/research_report.md` 已存在。

按**严格顺序**生成以下 5 章，后文依赖前文：

1. `output/sections/01_technical_problem.md`
   - 一、本发明要解决的技术问题
   - 300-500 字
2. `output/sections/02_technical_background.md`
   - 二、技术背景与最相近技术方案
   - 800-1500 字
3. `output/sections/03_defects_and_purpose.md`
   - 三、现有技术缺点与发明目的
   - 500-1000 字
4. `output/sections/04_technical_solution.md`
   - 四、技术方案详细阐述
   - 1500-3000 字
   - 必须包含 Mermaid 流程图与系统架构/原理框图
   - 必须写清具体技术实现，不能只写原理或功能描述
5. `output/sections/05_key_points.md`
   - 五、关键点和欲保护点
   - 300-800 字
   - 提炼 3-5 个关键创新点，并按重要性排序

## Full Workflow

当用户要求一键完成全部交底书工作时：

1. 先执行调研流程，生成 `output/research_report.md`
2. 再执行章节流程，生成 `output/sections/01~05_*.md`
3. 运行 `python3 scripts/merge.py` 合并文档
4. 运行 `bash scripts/convert.sh` 转换 Word
5. 若缺少 pandoc，明确提示 `brew install pandoc`，但不要阻断前面已完成的产物

## Output Checklist

```text
- output/research_report.md
- output/sections/01_technical_problem.md
- output/sections/02_technical_background.md
- output/sections/03_defects_and_purpose.md
- output/sections/04_technical_solution.md
- output/sections/05_key_points.md
- output/disclosure.md
- output/disclosure.docx
```

## Useful Commands

```bash
make merge
make docx
make clean
make help
```
