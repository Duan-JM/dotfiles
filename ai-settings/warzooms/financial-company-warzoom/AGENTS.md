# 公司调研报告生成器

## 项目简介

本项目用于自动生成公司调研报告，默认服务于**粗读公司 / 初筛研究价值**。用户在
`input/company.md` 中填写目标公司信息与调研参数，由 CLI agent（推荐 Copilot CLI，
也兼容 Claude Code / Codex）驱动「全网搜索 → 公司画像推理 → 章节撰写 → 审计闭环 → 合并 → 转换」的完整流程。

粗读时遵循 price-first：先判断价格、估值锚、是否有“底”和硬伤，再决定是否继续深挖；
不要先写完整故事再倒找买入理由。

「分析与审计」是核心：每章写完后必须经过 `audit → confirm → repair` 闭环，
任何定量数字都必须可追溯到 `SRC-XXX` 编号的来源。

## 语言要求

- 所有调研报告内容必须使用**中文**撰写
- 代码注释和脚本输出使用中文

## 粗读纪律（company-research 默认用法）

- **先闸门、后深挖**：`rough` 模式先输出一页纸闸门，结论限定为「排除 / 观察池 / 进入深研 / 信息不足」。
- **价格先当闸门**：优先抓取价格、市值、EV、P/B、EV/EBITDA、EV/EBIT、FCF yield、净股东回报率、净现金 / 净负债。
- **先写否决条件**：老千 / 掏空 / 审计硬伤、存贷双高、合股供股循环、异常关联交易、资金占用、违规担保等命中明显信号时，不因“便宜”继续美化。
- **识别“底”的类型**：净流动资产底、净资产 / 重置价值底、正常化盈利底、现金回报底、或没有可识别的底。
- **不强行完整**：粗读报告只回答“值不值得继续花时间”，信息不足时写「暂未获取」并列下一步验证问题。

## 项目结构

```text
input/
  company.md                       # 公司识别、报告参数、研究重点、对比公司（必填）
  extra_sources/                   # 可选：自有年报 / 招股书 / 研报 .md（优先级高于 web）
output/
  web_search_log.md                # 全网检索证据库（SRC-XXX 编号）
  facts.md                         # 关键事实表
  company_facets.md                # 公司画像（infer 阶段产物，章节写作自适应裁剪依据）
  manifest.json                    # 流水线状态机：章节进度 / 审计结果 / 修复次数 / 证据库 hash
  audits/                          # 审计中间产物
    programmatic_check.json        # 程序化 evidence linter 结果
    01_company_profile.audit.json  # 单章 audit 输出
    01_company_profile.confirm.json # 单章 confirm 输出（仅在 E 类违规时）
    ...
    final_consistency.audit.json   # 最终一致性审计
  sections/                        # 各章节
    00_overview.md                 # rough 模式为一页纸闸门；--with-overview 为投资要点概览
    01_company_profile.md
    02_business_model.md
    03_financials.md
    04_industry_competition.md     # deep 模式
    05_management_governance.md    # deep 模式
    06_recent_news.md
    07_swot.md                     # deep 模式
    08_investment_thesis.md
    09_research_decision.md        # rough 默认；short/deep 可选：研究决策章（--with-decision）
  research_report.md
  research_report.docx
templates/
  report_template.md               # 章节级 prompt 模板（CHAPTER_00 / 01..08 / 09 + SEARCH）
roles/
  infer.md / audit.md / confirm.md / repair.md / regenerate.md / final_audit.md
                                   # 审计闭环各 role 的独立 prompt 文件
scripts/
  check_evidence.py                # 程序化 evidence linter
  pipeline_common.py               # 共享 hash / 章节拼接规则
  verify_pipeline.py               # 合并前 manifest / hash / 审计硬闸门
  render_role.py                   # 把 roles/<role>.md 渲染为可派发的完整 prompt
  audit_summary.py                 # 聚合 audits/*.json 写附录
  merge.py
  convert.sh
tests/
  test_check_evidence.py
  test_render_role.py
  test_verify_pipeline.py
```

## 可用 Skills 与命令

下表中标注"主代理"的命令在所有运行时都可用；标注"可选子代理派发"的角色，
若运行时支持子代理（Copilot CLI `task` 工具 / Claude Code Task / Codex subagent）
则可派发以隔离上下文，否则由主代理切换 system prompt 顺序执行——对外契约一致。

| 命令 | 作用 |
|------|------|
| `/company-search` | 全网搜索：登记证据到 `web_search_log.md`，沉淀关键事实到 `facts.md` |
| `/company-infer` | 公司画像推理：生成 `company_facets.md`，用于后续章节写作与审计裁剪 |
| `/company-generate` | 章节生成 + 审计闭环：按模式逐章写作、程序化预审、audit、confirm、repair |
| `/company-audit` | 仅跑审计闭环（用于已存在章节文件的二次审计） |
| `/company-all` | 全流程：search → infer → generate（含 audit）→ final audit → merge → 转换 |

`/company-generate` 与 `/company-all` 会按 `input/company.md` 的报告模式选择产出：
`rough`（粗读闸门）、`short`（简报）、`deep`（深度报告）。二者支持以下可选标记：

- `--fast` — 跳过 audit / confirm / repair（仍跑程序化预审作为最低红线）
- `--with-decision` — short / deep 模式额外生成第 09 章「研究决策章」；rough 模式默认生成
- `--with-overview` — short / deep 模式额外生成第 00 章「投资要点概览」（最后回填）；rough 模式第 00 章为一页纸闸门
- `--force` — 仅允许绕过已有合法 audit JSON、且明确标记为 `audit_status=failed` 的章节；
  缺审计产物、缺章节、过期 hash、`not_run/stale` 或程序化 error 仍禁止合并

## 子代理派发（Copilot CLI 主路径）

`roles/` 目录下每个 role 都是**独立的 prompt 文件**，配合 `scripts/render_role.py`
就可以直接派发给子代理。**典型 Copilot CLI 派发范式**：

```text
1) bash 工具：
     command: python3 scripts/render_role.py audit --chapter 03_financials
     → 拿到 stdout（已替换好所有占位符）

2) task 工具：
     agent_type: general-purpose       # Sonnet，带完整工具集
     name:       audit-03
     prompt:     <上一步 stdout 整段>
     → 子代理读取所需文件、执行审计、写出 output/audits/03_financials.audit.json

3) read_agent：取摘要、检查文件落地
```

主代理派发前应在 prompt 末尾追加访问边界提醒（roles/<role>.md 的「Subagent 必须遵守」
段已写明）：例如 audit 只准写 `output/audits/<chapter>.audit.json`，不准改章节正文。

### Role 与建议派发方式速查

| Role | render_role 调用 | 建议 agent_type | 派发收益 |
|------|------------------|-----------------|---------|
| `infer` | `--no-chapter` | general-purpose | 中（首次调用、可联网） |
| `audit` | `--chapter <id>` | general-purpose | **高**（只读，上下文隔离极有价值） |
| `confirm` | `--chapter <id>` | general-purpose | **高**（只读，仅在 E 类违规时触发） |
| `repair` | `--chapter <id>` | general-purpose | 中（要写章节文件，但 patch 小） |
| `regenerate` | `--chapter <id>` | general-purpose | 中（要整章重建，建议主代理执行更顺手） |
| `final_audit` | `--no-chapter` | general-purpose | **高**（只读，跨章节大上下文） |

### 非 Copilot 运行时

- **Claude Code**：可在 `.claude/agents/<role>.md` 建立子代理配置，body 引用 `roles/<role>.md` 的 Prompt 段；调用前同样跑 `render_role.py` 填占位符。
- **无子代理运行时**：主代理读 `roles/<role>.md` Prompt 段 → `render_role.py` 填占位符 → 作为 system prompt 调模型 → 自行处理文件落地。

## 审计闭环（核心）

参考 dayu-agent 设计，每章写完执行：

1. **程序化预审**（`scripts/check_evidence.py`）：句子级 / 表格行级 evidence linter，
   带白名单与 severity，结果作为 LLM 审计输入，**不**触发自动修复。
2. **`audit` role**：基于章节正文 + 证据库摘要，输出违规清单 JSON。
3. **`confirm` role**（仅在 E 类违规时）：在证据库范围内复核违规，必须返回
   `supporting_quote`；**严禁**自由搜索补证据。
4. **`repair` / `regenerate` role**：按规则 → 动作映射表选择 PATCH 或整章 REGENERATE。
   同一章重试上限 3 次。

全章节就绪后跑一次 `FINAL_AUDIT` 角色做跨章节一致性审计（同指标多章数字一致、
来源清单完整、`数据截至日期` 与最旧 fact 不冲突）。

详细规则、JSON schema、`manifest.json` 状态机请见根目录的 `SKILL.md`。

## 全流程硬停止条件

`/company-all` 与其它长流程命中任一条件后必须停止派发新任务，把
`manifest.run_status` 设为 `blocked` 并写入 `blocked_reason`：

1. 连续两个 checkpoint 的 SRC 数、facts 数、章节状态与审计状态均无进展。
2. 同一错误、堆栈或失败断言连续出现 3 次。
3. 超过 `input/company.md` 配置的时间 / Token / API 成本预算；默认时长为
   rough 45 分钟、short 90 分钟、deep 180 分钟。
4. 出现缺凭证、网络不可达、目标分支冲突、依赖锁无法解决等外部阻塞。

命中后向用户展示当前 manifest 与阻塞原因，不得自动重试或用 `--force` 绕过。

## 角色边界（必读）

| 角色 | 可写文件 | 可联网 | 输入 | 输出 |
|------|---:|---:|------|------|
| `search` | 是 | 是 | `input/` | `web_search_log.md` / `facts.md` |
| `infer` | 是 | 受限 | `web_search_log.md` / `facts.md` | `company_facets.md` |
| `write` | 是 | 否 | 上述全部 + 模板 | 章节 .md |
| `audit` | **否** | **否** | 章节 + 证据库摘要 | audit JSON |
| `confirm` | **否** | **否** | 违规 + 证据库 | confirm JSON |
| `repair` / `regenerate` | 是 | 否 | 原文 + audit + confirm | 修复后的章节 .md |
| `final_audit` | **否** | **否** | 合并草稿 | final audit JSON |

`audit` / `confirm` / `final_audit` 是只读角色，不得改正文、不得新增证据、不得自由搜索。
这是审计可信的基石。

## 工具命令

```bash
make verify                                           # 仓库级单元测试（无需生成报告）
make check                                            # 严格 evidence 检查；无章节或 error 时失败
make pipeline-check                                   # 校验 manifest / hash / 章节 / 审计闸门
make pipeline-check FORCE=1                           # 仅绕过 audit_status=failed
make render-role ROLE=audit CHAPTER=03_financials     # 渲染指定 role prompt 到 stdout
make audit-summary                                    # 聚合 audits/*.json 写 markdown 附录
make merge                                            # 先校验再合并各章节
make merge FORCE=1                                    # 仅绕过 audit_status=failed
make docx                                             # 转 Word
make clean                                            # 清理所有生成文件
make clean-audits                                     # 仅清理 audits/
make help                                             # 显示帮助
```

Copilot CLI 主代理可直接捕获 `python3 scripts/render_role.py <role> [--chapter <id>]`
的 stdout 作为 `task` 工具 prompt 参数。

## 使用流程

1. 编辑 `input/company.md`，填入公司识别与调研参数
2. （可选）在 `input/extra_sources/` 放入年报 / 招股书 .md 文件作为优先来源
3. 触发 workflow phase（命令名仅作标识，不同运行时映射方式不同）：
   - **Copilot CLI**：让主代理顺序执行 `search → infer → generate → audit → final_audit → merge → docx`；
     subagent 派发用 `task` 工具 + `scripts/render_role.py`
   - **Claude Code**：可注册同名 slash command，或直接让主代理执行
4. 一键完成：触发 `/company-all`；粗读公司建议在 `input/company.md` 选择 `rough`；short / deep 如需研究决策章与概览页，用 `/company-all --with-decision --with-overview`
5. 或分步执行：先 `/company-search`，再 `/company-infer`，再 `/company-generate`，最后
   `make pipeline-check && make merge && make docx`

## 数据规范

- 每一个定量数字必须正文内联引用 `SRC-XXX`
- 未在 `web_search_log.md` 登记的来源**不得**引用
- 不确定的数据写"未公开披露"或"暂未获取"，宁缺勿编
- 报告头部必须标注"数据截至 YYYY-MM-DD"
- 跨市场公司明确币种、单位、会计口径
- 粗读闸门中的估值与现金回报指标同样必须带来源；缺失时不得估算凑数，写明缺口与下一步取数方式

## 公式格式约定

- 行内公式：`$...$`
- 独立公式块：`$$...$$`

## 免责声明

本项目输出的所有报告基于公开信息整理，不构成投资建议。
