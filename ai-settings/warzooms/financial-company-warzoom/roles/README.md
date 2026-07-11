# `roles/` — 审计闭环角色 Prompt 库

每个文件是一份**独立的、可派发给子代理的 system prompt**。配合 `scripts/render_role.py` 自动填占位符，stdout 即可直接作为 Copilot CLI `task` 工具的 prompt 参数。

## 文件清单

| 文件 | 用途 | render_role 调用 | 输出位置 |
|------|------|------------------|----------|
| [`infer.md`](infer.md) | 公司画像与关键约束推理 | `infer` | `output/company_facets.md` |
| [`audit.md`](audit.md) | 单章审计（只读） | `audit --chapter <id>` | `output/audits/<id>.audit.json` |
| [`confirm.md`](confirm.md) | 证据复核（只读） | `confirm --chapter <id>` | `output/audits/<id>.confirm.json` |
| [`repair.md`](repair.md) | 局部修复 | `repair --chapter <id>` | 覆盖 `output/sections/<id>.md` |
| [`regenerate.md`](regenerate.md) | 整章重建 | `regenerate --chapter <id>` | 覆盖 `output/sections/<id>.md` |
| [`final_audit.md`](final_audit.md) | 跨章节一致性审计（只读） | `final_audit` | `output/audits/final_consistency.audit.json` |

## 文件结构约定

每个 role 文件包含：

1. **顶层说明**：用途、`Dispatch` 推荐范式、`Placeholders` 占位符 → 数据源映射表、`Subagent 必须遵守` 的写权限边界
2. **`## Prompt` 段**：实际的 system prompt 正文，含 `{placeholder}` 占位符

`render_role.py` 只读取 `## Prompt` 段并做占位符替换；上方的元信息仅供阅读。

## 派发范式（Copilot CLI 主代理）

```text
bash:    python3 scripts/render_role.py audit --chapter 03_financials
         → stdout = 渲染好的完整 prompt
task:    agent_type=general-purpose, prompt=<上一步 stdout>
         → 子代理读 / 写指定文件并返回摘要
```

派发时必须告知子代理「只可写 X 路径，不可写 Y/Z 路径」——该边界由本文件的
「Subagent 必须遵守」段定义。

## 修改约定

- **修改后请只改 `## Prompt` 段**——元信息（Dispatch / Placeholders / Subagent 边界）变更要同步更新 `scripts/render_role.py` 的占位符 mapping
- 新增占位符须同时：
  1. 在 role 文件「Placeholders」表中登记
  2. 在 `render_role.py` 对应 `_build_*_mapping()` 中补 key
  3. 在 role 文件「Prompt」段内使用 `{key}` 引用
- 新增 role 文件须：
  1. 在 `scripts/render_role.py` 的 `ROLE_BUILDERS` 字典中注册
  2. 在本 README 文件清单中登记
  3. 在 `SKILL.md` 与 `AGENTS.md` 相关位置同步
