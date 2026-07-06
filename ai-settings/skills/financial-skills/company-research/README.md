# company-research

公司调研 skill。给定一家公司（上市或非上市），通过**全网检索 → 事实归一化 → 8 章 / 5 章中文调研报告**的完整流程产出可追溯的研究报告。

## 一句话特性

每一个数字都带 `SRC-XXX` 内联引用，未登记到证据库的来源**不得**写进报告。所有章节产出后还会经过 **infer → audit → confirm → repair → final_audit** 五阶段闭环复核，把幻觉数据与口径冲突压到最低。

## 文件结构

- [`SKILL.md`](SKILL.md) — skill 主体（YAML frontmatter + Core Rules + 工作流 + 审计闭环 + manifest schema + Output Checklist）
- [`project-template/`](project-template/) — 可直接 cp 到工作目录使用的脚手架
  - [`roles/`](project-template/roles/) — 6 个独立 role prompt（infer / audit / confirm / repair / regenerate / final_audit）
  - [`scripts/render_role.py`](project-template/scripts/render_role.py) — 渲染 role 为可派发的完整 prompt
  - [`scripts/check_evidence.py`](project-template/scripts/check_evidence.py) — 程序化 evidence linter
- [`examples/byd/`](examples/byd/) — 完整示例案例（比亚迪 002594.SZ / 1211.HK，数据截至 2026-05-28）

## Workflow phase 列表

每个 phase 对应一个 prompt role；运行时若支持 slash command，可映射为同名命令；否则由主代理顺序执行不同 role。

| phase | 作用 |
|------|------|
| `/company-search` | 沿 7 个维度并行全网搜索，登记证据到 `web_search_log.md`，沉淀关键事实到 `facts.md` |
| `/company-infer` | 推理公司业务画像与「自适应裁剪」开关，写入 `output/company_facets.md` |
| `/company-generate` | 按 `report_mode` 顺序生成 5 章（short）或 8 章（deep）报告 |
| `/company-audit` | 章节审计闭环（含 confirm / repair / regenerate / final cross-section audit） |
| `/company-all` | 全流程：搜索 → infer → 生成 → 审计闭环 → merge → 转 Word |

可选标记：`--with-decision`（追加第 09 章研究决策）、`--with-overview`（追加第 00 章投资要点概览）、`--fast`（跳过审计闭环）。

## 数据源补强（A 股 · 可选）

A 股财务三表 / 财务指标 / 业绩预告等定量数据可通过姊妹 skill [`financial-skills/tushare/`](../tushare/) 自动抓取，免手工誊抄。tushare skill 的 `scripts/merge.py` 会自动识别既有 `web_search_log.md` 最大 SRC 编号、偏移新条目、追加到证据库 + 事实表、并重算 `manifest.json` 的 hash。

如需行情 / 资金流 / 板块 / 公告 / 宏观等 CLI 工具未覆盖的数据，仓库根 submodule `.agents/skills/tushare/`（tushare 官方自然语言驱动型 skill）是互补选择，可在 CHAPTER_04 / CHAPTER_06 写作时通过 `task` 工具加载其 SKILL.md 调用。

详见 [SKILL.md 的 Tushare 自动接入段](SKILL.md)。

## 审计闭环

- **程序化 evidence linter**：`make check` 跑 `scripts/check_evidence.py`，句子 / 表格行级粒度，识别数字无引用 / SRC 未登记 / 弱来源用语等问题，输出 `output/audits/programmatic_check.json`。
- **章节审计**：每章写完后由 audit role 产出 `output/audits/<chapter>.audit.json`；`E1/E2/E3` 类违规交 confirm role 二次复核（必须返回 `supporting_quote`）；按规则 → 动作映射表选择 PATCH 局部修复或 REGENERATE 整章重建（最多 3 轮）。
- **最终一致性审计**：全部章节就绪后跑 cross-section consistency audit，检查同指标在不同章节是否冲突、来源清单是否对齐。
- **状态真源**：`output/manifest.json` 记录各章节状态、审计结果、修复次数、证据库 hash，支持断点续跑。
- **附录 B**：`scripts/audit_summary.py` 把所有 audit JSON 聚合成 markdown 附录，由 `merge.py` 自动追加到 `research_report.md`。

## 子代理派发（Copilot CLI 主路径）

每个 audit role 都是 [`project-template/roles/<role>.md`](project-template/roles/) 下一个独立 prompt 文件。配合 `scripts/render_role.py` 一行命令就能派发给 Copilot CLI 的 `task` 工具（或 Claude Code Task / Codex subagent）：

```bash
# 主代理把 stdout 整段塞进 task 工具的 prompt 参数
python3 scripts/render_role.py audit --chapter 03_financials
```

不支持子代理的运行时：主代理读 `roles/<role>.md` 的 `## Prompt` 段，用 `render_role.py` 填占位符后作为 system prompt 调模型。**两条路径对外契约一致**。

## 快速开始

```bash
# 复制模板到工作目录
cp -r financial-skills/company-research/project-template ~/my-research/

# 编辑公司信息
$EDITOR ~/my-research/input/company.md

# 在 Claude Code / Codex 中触发
/company-all

# 完成后合并并转 Word
cd ~/my-research && make check && make merge && make docx
```

## 示例案例：比亚迪

[`examples/byd/`](examples/byd/) 是一份完整的 deep 模式产出，包含：

- `input/company.md` — 输入填写示范
- `output/web_search_log.md` — 20 条 SRC-XXX 证据条目（含巨潮、HKEXnews、SEC、新浪、CBC 等多类型）
- `output/facts.md` — 32 行 Fact-XXX 事实表（FY2022 – FY2024 + 2025 Q1）
- `output/sections/01-08_*.md` — 8 章正文
- `output/research_report.md` — `merge.py` 自动合并后的完整报告（约 4.2 万字符）

> ⚠️ 示例创建于审计闭环引入之前，因此 `output/audits/` 与 `company_facets.md` 暂未包含；在该示例上执行 `make check` 仅会暴露既有报告里的引用缺漏，不会改写正文。
>
> ⚠️ 数据快速过期，示例每个文件顶部均标注"仅作格式示例，不构成投资建议"。

## 免责声明

本 skill 输出的所有报告基于公开信息整理，不构成投资建议、评级意见或买卖证券建议。
