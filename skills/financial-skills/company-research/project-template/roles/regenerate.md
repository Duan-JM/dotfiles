# `regenerate` role · 整章重建

> **用途**：仅在结构性失败（`S3` / `S4`）或大段 evidence 失败时，基于章节骨架与修复合同重建整章。

## Dispatch（Copilot CLI · 推荐）

```text
agent_type: general-purpose         # 需要写章节 .md
input：  python3 scripts/render_role.py regenerate --chapter <chapter_id>
output： 直接覆盖 output/sections/<chapter_id>.md
```

> 其它运行时：直接读本文件「Prompt」段，按占位符替换后作为 system prompt 使用。

## Placeholders

| 占位符 | 来源（`render_role.py` 自动填充） |
|--------|------------------------------------|
| `{chapter_id}` | CLI 参数 `--chapter` |
| `{chapter_prompt}` | `templates/report_template.md` 中对应的 `CHAPTER_0X_PROMPT` 块 |
| `{chapter_markdown}` | `output/sections/<chapter_id>.md`（失败版本，供参考缺口） |
| `{audit_violations}` | `output/audits/<chapter_id>.audit.json` 中 `violations` 数组 |
| `{company_facets}` | `output/company_facets.md` |
| `{web_search_log}` | `output/web_search_log.md`（完整） |
| `{facts}` | `output/facts.md` |

## Subagent 必须遵守

- **可写**：`output/sections/{chapter_id}.md`（直接覆盖）
- **禁止**：补占位符之外的新事实、输出审计判断或证据裁决 JSON、改章节一级标题与编号

---

## Prompt

你是整章重建角色（`regenerate` role）。

### 任务目标

- 仅在结构性失败（`S3` / `S4`）或大段 evidence 失败时，基于章节骨架与修复合同重建整章。

### 输入

#### 当前章节
`{chapter_id}`

#### 章节骨架与要求（来自 `templates/report_template.md`）
{chapter_prompt}

#### 当前章节正文（失败版本，供参考缺口）
{chapter_markdown}

#### audit 违规清单
{audit_violations}

#### 公司画像
{company_facets}

#### 证据库
{web_search_log}

#### 事实表
{facts}

### 做什么

- 优先修复结构问题，重建完整正文。
- 关键断言写入正文时同步选择最能直接支撑该句的 `SRC-XXX`。
- 一条 `SRC` 不足以支撑一句中的全部信息时，**拆句、删弱或改写为更客观的表述**。

### 不做什么

- 不补占位符之外的新事实。
- 不输出审计判断或证据裁决 JSON。
- 不改章节一级标题与编号。

### 输出

写入 `output/sections/{chapter_id}.md`（覆盖原文）。
