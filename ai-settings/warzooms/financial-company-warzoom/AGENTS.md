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
- **闸门后才写预期差**：只有粗读结论为「观察池 / 进入深研」时启用预期差验证框架；
  「排除 / 信息不足」不得被强制扩写。
- **预期差可证伪**：市场隐含预期、我方预期、证据锚点、差异方向、验证日期、先行指标、
  上 / 下行失效条件必须写清；同时分离内在价值判断、1-3 个月路径判断与研究动作。

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
    10_earnings_snapshot.md        # earnings 模式：结论快照
    11_earnings_expectation_quality.md # earnings 模式：预期差 / 质量
    12_earnings_segment_kpi.md     # earnings 模式：分部 KPI
    13_earnings_profit_expense.md  # earnings 模式：利润与费用
    14_earnings_cash_capital_allocation.md # earnings 模式：现金流与资本配置
    15_earnings_guidance_call.md   # earnings 模式：指引 / 电话会
    16_earnings_competition_market_reaction.md # earnings 模式：竞争和市场反应
    17_earnings_model_valuation_bridge.md # earnings 模式：模型估值变化桥
    18_earnings_thesis_action.md   # earnings 模式：论点更新与行动清单
  research_report.md
  research_report.docx
templates/
  report_template.md               # 章节级 prompt 模板（CHAPTER_00 / 01..08 / 09 + SEARCH）
data/
  industry_rules.json               # 机器可检查行业规则包（KPI / 估值方法 / 风险 / 必写结论）
roles/
  infer.md / audit.md / confirm.md / repair.md / regenerate.md / final_audit.md
                                   # 审计闭环各 role 的独立 prompt 文件
scripts/
  industry_rules.py                 # 行业规则包加载、schema 校验与 tag 匹配
  check_evidence.py                # 程序化 evidence linter
  financial_quality_check.py       # 标准库 JSON 财报质量核查：应计 / 现金转化 / DSO 背离 / A-D 分级
  valuation_calculator.py          # JSON 输入 / 输出的粗读估值计算器（标准库）
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
`rough`（粗读闸门）、`short`（简报）、`deep`（深度报告）、`earnings`（观察池 / 持续跟踪财报点评）。二者支持以下可选标记；`earnings` 使用独立 10-18 九段式章节，不改变 rough 默认：

- `--fast` — 跳过 audit / confirm / repair（仍跑程序化预审作为最低红线）
- `--with-decision` — short / deep 模式额外生成第 09 章「研究决策章」；rough 模式默认生成
- `--with-overview` — short / deep 模式额外生成第 00 章「投资要点概览」（最后回填）；rough 模式第 00 章为一页纸闸门；earnings 模式忽略该标记
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

## earnings 财报模式（观察池 / 持续跟踪）

`report_mode=earnings` 专门用于已在观察池或需要持续跟踪的公司财报复盘，不生成 deep 式完整公司故事，
也不改变 rough 的默认粗读闸门。章节固定为 9 段：

1. `10_earnings_snapshot` — 结论快照
2. `11_earnings_expectation_quality` — 预期差 / 财报质量
3. `12_earnings_segment_kpi` — 分部与 KPI
4. `13_earnings_profit_expense` — 利润与费用
5. `14_earnings_cash_capital_allocation` — 现金流与资本配置
6. `15_earnings_guidance_call` — 指引与电话会
7. `16_earnings_competition_market_reaction` — 竞争、同业与市场反应
8. `17_earnings_model_valuation_bridge` — 模型与估值变化桥
9. `18_earnings_thesis_action` — 论点更新与行动清单

基线纪律：无历史预测时必须明确「首次覆盖基线」；有旧预测时必须保留原预测文本，不得事后改写，
验证状态只允许 `命中 / 部分命中 / 未命中 / 无法验证`。`manifest.report_mode` 支持 `earnings`；
`manifest.earnings_baseline.type` 必须为 `first_coverage` 或 `prior_forecast`，后者的
`prior_forecasts[]` 必须包含 `original_forecast` 与上述合法状态。

## 审计闭环（核心）

参考 dayu-agent 设计，每章写完执行：

1. **程序化预审**（`scripts/check_evidence.py`）：句子级 / 表格行级 evidence linter，
   带白名单与 severity，结果作为 LLM 审计输入，**不**触发自动修复；若
   `company_facets.md` 显式选择了 `data/industry_rules.json` 中的行业规则，还会检查
   必备 KPI 语义组覆盖，缺失只给 warning，证据不足写"暂未获取"。
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
   rough 45 分钟、earnings 60 分钟、short 90 分钟、deep 180 分钟。
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
make financial-quality-check INPUT=financials.json    # JSON 输入 / 输出的财报质量核查（可选辅助）
make valuation INPUT=input/valuation.json             # 运行粗读估值计算器（可选 OUTPUT=...）
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
4. 一键完成：触发 `/company-all`；粗读公司建议在 `input/company.md` 选择 `rough`；观察池财报复盘选择 `earnings`；short / deep 如需研究决策章与概览页，用 `/company-all --with-decision --with-overview`
5. 或分步执行：先 `/company-search`，再 `/company-infer`，再 `/company-generate`，最后
   `make pipeline-check && make merge && make docx`

## 数据规范

- 每一个定量数字必须正文内联引用 `SRC-XXX`
- 未在 `web_search_log.md` 登记的来源**不得**引用
- 不确定的数据写"未公开披露"或"暂未获取"，宁缺勿编
- 报告头部必须标注"数据截至 YYYY-MM-DD"
- 跨市场公司明确币种、单位、会计口径
- 粗读闸门中的估值与现金回报指标同样必须带来源；缺失时不得估算凑数，写明缺口与下一步取数方式
- `scripts/valuation_calculator.py` 仅用于 rough 模式估值简算辅助：JSON 输入 / 输出、只用标准库、
  不联网、不补数。输入金额必须统一币种、单位、会计口径；字段缺失返回 `unavailable` 与
  `missing`，非法输入（如 WACC <= terminal_g、非正股本）必须停止使用该组结果。
- short / deep 投资论点必须包含可证伪预期差；若没有独立观点，研究动作降为「观察 / 继续验证」，
  不给买入 / 卖出 / 持有建议。

## 公式格式约定

- 行内公式：`$...$`
- 独立公式块：`$$...$$`

## 免责声明

本项目输出的所有报告基于公开信息整理，不构成投资建议。
