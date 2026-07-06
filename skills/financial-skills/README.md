# financial-skills

一组面向金融、投资、公司分析场景的 agent skills。每个子目录是一个独立 skill，带 `SKILL.md` 与 YAML frontmatter，可被 Claude Code / Codex / Cursor / Gemini 等工具按需触发。

## Skills

| Skill | 何时使用 |
|-------|---------|
| **[company-research](company-research/)** | 调研一家上市 / 非上市公司：全网检索 → 事实归一化 → 8 章中文调研报告（含 SWOT、估值参考、可比公司）。强制证据链：每一个数字都必须可追溯到登记的来源。 |

## 设计原则

1. **证据链强制**：所有定量数据通过 `SRC-XXX` 内联引用证据库，未登记的来源不得引用。
2. **不杜撰**：宁缺勿编，缺失数据写"未公开披露"。
3. **跨市场支持**：A 股 / 港股 / 美股的 primary source 优先级在 SKILL.md 中明确列出（巨潮、HKEXnews、SEC EDGAR）。
4. **可复现**：每个 skill 提供 `project-template/`（可直接 cp 出来用）+ `examples/`（含真实公司案例）。

## 使用方式

1. 把 `<skill>/project-template/` 复制到你的工作目录
2. 填写 `input/` 下的输入文件
3. 在 Claude Code 中触发对应斜杠命令（详见每个 skill 的 SKILL.md）

## 风格沿用

整体目录结构、SKILL.md frontmatter 与 project-template 模式参考自 [docs-skills/patent-writer](../docs-skills/patent-writer/) 与 [python-skills](../python-skills/)。
