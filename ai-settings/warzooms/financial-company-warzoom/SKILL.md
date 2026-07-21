---
name: researching-companies
description: Searches public and structured sources for a target company (A-share, HK, US, or private) and produces a Chinese rough-read gate or structured research report. Optimized for price-first company screening: valuation gate, bottom type, red flags, business snapshot, financial quality, and whether the company deserves deeper research. Every quantitative claim must be traceable to a logged source. Use when researching a listed company, supplier, customer, competitor, or acquisition target.
---

# Company Research

## Core Rules

- 所有调研报告内容必须使用**中文**撰写。
- 数学公式使用 LaTeX：行内 `$...$`，块级 `$$...$$`。
- **强制证据链**：报告中出现的每一个定量数字（营收、利润、市占率、估值、销量、出货量、员工数等）都必须正文内联引用 `SRC-XXX` 源 ID；任何未先登记到 `output/web_search_log.md` 的来源**禁止**直接引用。
- **禁止杜撰**：不确定的数据写"未公开披露"或"暂未获取"；宁缺勿编。
- **数据时效**：报告头部必须写"数据截至 YYYY-MM-DD"；超过 6 个月的财务数据需额外标注。
- 不构成投资建议：每份报告末尾固定附免责声明。
- 在开始生成前，先确认 `input/company.md` 不是未填写的占位内容。
- **审计闭环优先**：每章写完必须经过 `audit` 角色复核；E 类违规必须再走 `confirm` 角色复核证据再决定 PATCH / REGENERATE / 删除断言；不要直接信任写作角色的自我审查。
- **角色边界**：`write`、`audit`、`confirm`、`repair` 是不同 role。写作角色可改文件；`audit`、`confirm` 是**只读**角色，不得改正文、不得新增证据、不得自由搜索新来源。
- **裁剪自适应**：所有章节写作均以 `output/company_facets.md` 为先验。同一行业不同公司应当走出不同的判断重点；同一章节不同行业应当走出明显不同的判断路径。
- **粗读优先**：若用户只是想"看看这家公司"、"粗读公司"、"判断值不值得深挖"，默认使用 `rough` 模式，不直接生成完整深度报告。
- **价格先当闸门**：投资初筛场景先看价格、市值、EV、P/B、EV/EBITDA、EV/EBIT、FCF yield、净股东回报率、净现金 / 净负债与硬伤快筛；没有可识别的"底"时，应输出观察或排除，而不是补故事。
- **否决条件先行**：老千 / 掏空 / 审计硬伤、存贷双高、合股供股循环、异常关联交易、资金占用、违规担保等明显信号是一票否决项，不能因估值便宜而忽略。

## Workspace Layout

```text
input/
  company.md                       # 用户填写：公司识别、报告参数、研究重点、对比公司
  extra_sources/                   # 可选：年报 / 招股书 / 研报 .md（优先级高于 web）
output/
  web_search_log.md                # 全网检索证据库，按 SRC-001、SRC-002... 编号
  facts.md                         # 关键事实表（指标 / 数值 / 期间 / 币种 / 来源）
  company_facets.md                # 公司业务类型与关键约束（infer 阶段产物）
  manifest.json                    # 流水线状态：章节进度 / 审计结果 / 修复次数 / 证据库 hash
  audits/                          # 每章 audit / confirm / programmatic 检查 JSON
    programmatic_check.json
    01_company_profile.audit.json
    01_company_profile.confirm.json
    ...
    final_consistency.audit.json
  sections/                        # 各章节文件
    00_overview.md                 # rough 模式为一页纸闸门；--with-overview 为投资要点概览
    01_company_profile.md
    02_business_model.md
    03_financials.md
    04_industry_competition.md     # short 模式可省略
    05_management_governance.md    # short 模式可省略
    06_recent_news.md
    07_swot.md                     # short 模式可省略
    08_investment_thesis.md
    09_research_decision.md        # rough 默认；short/deep 可选：研究决策章（--with-decision）
  research_report.md               # 合并后的完整调研报告
  research_report.docx             # Word 版本
templates/
  report_template.md               # 章节级 prompt 模板（CHAPTER_00 / 01..08 / 09 + SEARCH）
roles/
  infer.md                         # 公司画像推理 role prompt
  audit.md                         # 单章审计 role prompt
  confirm.md                       # 证据复核 role prompt
  repair.md                        # 局部修复 role prompt
  regenerate.md                    # 整章重建 role prompt
  final_audit.md                   # 跨章节一致性审计 role prompt
scripts/
  check_evidence.py                # 程序化证据 linter（句子级 / 表格行级）
  pipeline_common.py               # 流水线共享 hash / 章节拼接规则
  verify_pipeline.py               # 合并前 manifest / hash / 审计硬闸门
  render_role.py                   # 把 roles/<role>.md 渲染为可派发的完整 prompt
  audit_summary.py                 # 把 audits/*.json 聚合成 markdown 附录
  merge.py                         # 合并章节
  convert.sh                       # Markdown → Word
tests/
  test_check_evidence.py
  test_render_role.py
  test_verify_pipeline.py
```

## Inputs

1. 读取 `input/company.md` 完整内容，提取：
   - 公司中英文名、证券代码、交易所、官网
   - 报告参数：`report_mode`（`rough` / `short` / `deep`）、数据截至日期、币种与单位、会计口径
   - 粗读 / 价值闸门参数：研究流派、是否价格先行、关注的底、默认否决条件、期望输出
   - 研究重点与关键问题
   - 用户指定的可比公司
2. 读取 `input/extra_sources/` 下全部 `.md` 文件作为**优先来源**（高于 web 搜索结果）。
3. 从 `templates/report_template.md` 中读取对应章节提示模板。

## Source Priority（跨市场数据源）

财务数字、股权结构、董监高、关联交易等关键事实必须走可追溯来源。对 A 股及 Tushare
覆盖的事实性数据，**默认先走 Tushare 官方 skill**；只有 Tushare 不覆盖、权限不足、
结果为空或需要原始公告交叉验证时，才补充 web / extra sources。

### A 股
- **Tushare 官方 skill（事实数据默认入口）**：安装自
  `https://github.com/waditu-tushare/skills`，在运行时以 `tushare` 或 `tushare-data`
  skill 加载。公司识别、财报三表、财务指标、业绩预告 / 快报、估值、行情、资金流、
  公告新闻、板块与宏观等结构化事实，先由该 skill 取数并整理，再登记到
  `output/web_search_log.md` 与 `output/facts.md`。
- 巨潮资讯网 cninfo.com.cn、上交所 / 深交所 / 北交所公告、公司投资者关系页面：
  作为 Primary source，用于 Tushare 不覆盖、权限不足、字段冲突或需要原文复核的场景。
  不要把 Tushare 已能稳定获取的三表数字改为手工网页摘录。

### 港股
- HKEXnews 披露易 hkexnews.hk
- 公司公告 / 年报 / 中报
- 公司 IR 页面

### 美股 / ADR
- SEC EDGAR sec.gov/edgar
- 10-K / 10-Q / 8-K / 20-F / 6-K / DEF 14A
- 公司 IR 页面

### 通用辅助来源
- 公司官网与新闻稿
- 监管机构（证监会、市场监管总局、央行、银保监、欧美对应机构）
- 行业协会与统计局
- 主流财经媒体（仅用于背景与新闻事件，**不得作为财务报表原始数字的唯一来源**）
- 第三方数据库（Wind / 同花顺 / Bloomberg / S&P / FactSet 等，仅作辅助）

私营公司、未上市供应商按"工商登记 → 公司官网 → 行业报告 → 媒体报道"的顺序降级。

## Search Workflow（/company-search）

当用户要求"先做全网搜索"、"做调研"、"先查资料"时执行：

0. **先判断 Tushare 覆盖范围**：若目标是 A 股上市公司，或任务涉及 Tushare 可覆盖的行情、
   财报、估值、资金流、公告新闻、板块、宏观数据，必须先加载 `tushare` / `tushare-data`
   skill 取数并沉淀事实；web 搜索只补充 Tushare 不能覆盖的业务背景、管理层、行业解释、
   原文公告复核和新闻语境。

0.5. **粗读闸门事实优先**：若 `report_mode=rough` 或用户目标是投资初筛，先沉淀一页纸闸门所需事实：
   - 价格 / 市值 / EV（含净负债口径）
   - P/B 及大致资产构成（现金、应收、存货、固定资产、商誉 / 无形）
   - EV/EBITDA、EV/EBIT；重资产 / 高 capex 公司以 EV/EBIT、owner earnings、FCF 为主
   - FCF yield、净股东回报率 = (现金分红 + 净回购 - 股权激励 / 增发摊薄) / 市值
   - 净现金 / 净负债、短债与在手现金、利息覆盖
   - 近 5-10 年派息 / 回购连续性与股本摊薄趋势
   - 硬伤快筛：合股 + 折价供股循环、核数师辞任 / 保留意见、监管处分、资金占用、违规担保、存贷双高、异常关联交易、低价私有化劣迹
   缺失项写"暂未获取"，不得用不明来源估算。

1. **并行**沿以下维度搜集（可以同时发起多个 web_search 调用）：
   - 公司识别与股权（年报封面、招股书、工商信息）
   - 业务与产品（官网、年报 MD&A、产品页面）
   - 财务（最近 3 年年报 + 最新季报 / 中报；A 股三表和财务指标必须先走 Tushare skill）
   - 估值与现金回报（市值、EV、P/B、EV/EBITDA、EV/EBIT、FCF yield、分红、回购、股本趋势）
   - 行业与竞争（行业研报、监管统计、可比公司公告）
   - 管理层与治理（年报董监高章节、监管处罚、诉讼）
   - 近期新闻与监管事件（最近 6-12 个月）
   - ESG / 重大风险事件（如有）

2. **登记证据**到 `output/web_search_log.md`，每条来源使用固定模板（见下方"web_search_log 模板"）。

3. **事实归一化**：搜集完成后，把关键定量数据沉淀到 `output/facts.md`（指标、数值、期间、币种、口径、来源 ID）。多来源数字冲突时，标注差异并以 primary source 为准。

4. 在搜索 log 末尾给出"数据完整度评估"：哪些维度信息充分、哪些缺口需要补充。
   rough 模式需额外列出"阶段 0 闸门缺口"：缺哪个估值 / 股东回报 / 硬伤检查项，会如何影响结论。

### Tushare Skill 接入（事实数据默认路径）

本项目不再把 A 股三表、财务指标、行情估值等结构化事实依赖人工网页摘录。凡是 Tushare
覆盖的数据，先通过官方 Tushare skill 获取；主代理再把结果转换成本项目统一的
`SRC-XXX` / `Fact ID` 证据格式。

#### 安装要求

项目运行前必须安装 Tushare 官方 skills，来源：
`https://github.com/waditu-tushare/skills`。

```bash
# 安装 Python SDK
python3 -m pip install tushare

# 任选其一安装 skill（需要本地支持 npx skills）
npx skills add https://github.com/waditu-tushare/skills.git --skill tushare-data
npx skills add https://gitee.com/lwdt/skills.git --skill tushare-data

# 配置 token
export TUSHARE_TOKEN="your_token_here"
```

若运行时使用项目内 skills 目录，也可把官方仓库里的 `tushare` / `tushare-data`
目录复制到 `.agents/skills/`。Copilot CLI 中优先加载 `tushare`，若仅安装了
`tushare-data`，则加载 `tushare-data`。

#### 必须优先走 Tushare 的事实范围

| 事实类型 | 首选 Tushare 接口 / 工作流 | 写入位置 |
|----------|----------------------------|----------|
| 公司识别、上市状态、行业、注册地址 | `stock_basic`, `stock_company`, `stock_st` | `web_search_log.md`, `facts.md` |
| 财报三表 | `income`, `balancesheet`, `cashflow` | `facts.md` 为主，必要时在 `web_search_log.md` 摘要 |
| 财务质量与核心比率 | `fina_indicator` | `facts.md` |
| 业绩预告 / 快报 / 披露日期 | `forecast`, `express`, `disclosure_date` | `web_search_log.md`, `facts.md` |
| 估值与行情事实 | `daily_basic`, `daily`, `pro_bar` | `facts.md` |
| 资金流与市场行为 | `moneyflow`, `moneyflow_hsgt`, `hsgt_top10`, `top_list` | `web_search_log.md`, `facts.md` |
| 公告、新闻、研报 | `anns_d`, `news`, `major_news`, `research_report` | `web_search_log.md` |
| 板块、指数、概念与宏观 | `index_*`, `sw_daily`, `ths_*`, `dc_*`, `cn_*` | `web_search_log.md`, `facts.md` |

如果 Tushare 返回空表，要区分"非交易日 / 区间无数据 / 未上市 / 权限不足 / 参数错误"，
不能直接改用网页数字绕过。只有确认 Tushare 不覆盖或权限不足，才允许补充其他来源，
并在 `web_search_log.md` 记录原因。

#### 派发与登记规则（单写者模型）

为避免 `SRC-XXX` 编号竞争，Tushare 子流程只负责取数与输出结构化结果；**主代理**
统一写入 `output/web_search_log.md`、`output/facts.md` 和 `output/manifest.json`。
推荐顺序：

1. 加载 `tushare` / `tushare-data` skill，完成 Python、`tushare` 包、`TUSHARE_TOKEN`
   与权限检查。
2. 对 A 股公司先拉公司基础信息、最近 3 年年报 + 最新季报 / 中报的三表与
   `fina_indicator`；再按研究重点补行情、估值、资金流、公告新闻、板块或宏观。
3. 将每次 Tushare 查询按"接口 + 参数 + 字段 + 抓取时间 + 行数 + `ann_date` /
   `end_date` / `report_type` / `comp_type`（如有）"登记为 `SRC-XXX`。
4. 把可直接用于正文的数字写入 `facts.md`，每行指向对应 `SRC-XXX`。
5. 再做 web 搜索，只补 Tushare 不覆盖的业务解释、行业背景、管理层治理、监管事件和原文复核。

Tushare source 条目模板：

```markdown
## SRC-001
- 标题：Tushare Pro income / balancesheet / cashflow 查询：002594.SZ 最近三年及最新一期
- 发布机构：Tushare Pro
- URL：https://tushare.pro/wctapi/documents/...
- 发布时间：按 ann_date / end_date 标注；无单一发布日期时写"数据接口返回"
- 抓取时间：YYYY-MM-DD
- 来源类型：Tushare Pro · 官方 skill
- 可信等级：Secondary
- 关键摘录：
  > 接口：income, balancesheet, cashflow；参数：ts_code=002594.SZ, periods=...
  > 字段：revenue, n_income_attr_p, total_assets, total_liab, n_cashflow_act...
  > 返回行数：income=4, balancesheet=4, cashflow=4；保留 ann_date/report_type/comp_type。
- 拟用于章节：03_financials, 08_investment_thesis
```

Tushare 是 Secondary 来源；若与交易所公告、公司年报等 Primary source 冲突，必须记录差异，
以 Primary source 为准并说明冲突原因。没有原文复核需求时，不要为了"更像 primary"
而重复手工摘录三表数字。

#### Manifest stale 警告

Tushare 事实写入会改变 `source_log_hash` / `facts_hash`。如果在**章节已生成 + 审计已通过**
之后补拉或修正 Tushare 数据，则所有引用受影响 facts 的章节 audit 都应标记为 `stale`
并重跑审计闭环。建议把 Tushare 取数一次性做在 Search Workflow 阶段、章节写作之前。

## Infer Workflow（公司画像推理 · 必选前置）

当用户已具备 `output/web_search_log.md` 与 `output/facts.md`，但尚未进入章节写作时执行。
也可在 `/company-all` 中作为 Search Workflow 之后的第一步自动触发。

**实现**：派发 `roles/infer.md`，渲染命令 `python3 scripts/render_role.py infer`。

目标：

- 判断"这家公司主要是什么生意"
- 判断"哪些关键约束会显著改变后续章节写作的判断路径"
- 判断"粗读阶段的价值研究镜头"：价格闸门、底的类型、硬伤快筛、edge 自检与建议研究深度
- 这一步只服务后续章节写作裁剪与审计裁剪，**不直接生成任何章节正文**

输出 `output/company_facets.md`，结构：

```markdown
# 公司画像与关键约束

## business_model_tags
- 必选 1-3 个，从下列候选中挑：
  `软件订阅 / 平台双边 / 硬件制造 / 半导体 / 重资产生产 / 资源开采 / 银行 / 保险 /
   非银金融 / 房地产开发 / 物业管理 / 物流仓储 / 零售连锁 / 互联网广告 / 游戏 /
   生物医药 / 创新药 / CXO / 医疗器械 / 公用事业 / 新能源运营 / 新能源制造 /
   汽车整车 / 汽车零部件 / 餐饮连锁 / 农业 / 文化娱乐 / 教育培训 / 其它（请注明）`

## constraint_tags
- 必选 2-5 个，覆盖最能改变本公司分析重点的特殊变量：
  `跨市场上市 / 强监管行业 / 出海占比高 / 单一大客户依赖 / 周期股 / 季节性强 /
   外汇敞口大 / 商品价格敏感 / 政策驱动 / 国资背景 / 创始人 / 控股 / 高研发占比 /
   产能扩张期 / 整合并购 / 巨额商誉 / 业绩对赌 / 关联交易复杂 / 同业竞争 /
   会计准则切换 / 其它（请注明）`

## value_research_lens
- 粗读结论倾向：`排除 / 观察池 / 进入深研 / 信息不足`
- 价格闸门：`便宜 / 边缘 / 不便宜 / 暂未判断` + 一句话理由
- 底的类型：`净流动资产底 / 净资产或重置价值底 / 正常化盈利底 / 现金回报底 / 概率型未来现金流 / 无可识别底 / 信息不足`
- 硬伤快筛：`通过 / 存疑 / 命中 / 信息不足` + 最关键证据缺口
- edge 自检：决定价值的 3-5 个变量，以及"有 / 无 / 部分 / 信息不足"
- 建议研究深度：`阶段0停止 / 阶段1生意与底 / 阶段2排雷 / 阶段3估值情景`

## preferred_lens_per_chapter
- 02_business_model：本公司应优先从哪个角度切入（如"渠道结构"、"产品矩阵"、"网络效应"）
- 03_financials：本公司应优先看哪几个指标（如"现金循环天数"、"应收账款周转"、"研发资本化"）
- 04_industry_competition：行业切片角度（如"按下游应用"、"按地区"、"按渠道"）
- 05_management_governance：是否需要重点写"实控人变动"、"股权激励"、"关联交易"
- 06_recent_news：近期事件应聚焦哪类（如"产能投放"、"客户拓展"、"监管变化"）
- 07_swot：本公司天然的非对称视角（哪一象限更值得展开）
- 08_investment_thesis：本公司的关键观察指标（5-10 个 KPI）

## item_rules（条件项）
- 仅在 constraint_tags 命中下列条件时，额外写入：
  - 跨市场上市 → 必须给出 A/H 价差或 ADR 折溢价
  - 周期股 → 必须给出当前所处周期阶段判断
  - 出海占比高 → 必须拆分海外收入占比及主要市场
  - 高研发占比 → 必须给出研发资本化率
  - …
```

要求：

- 只从候选中选择，不自由创造新标签。
- 不确定时宁可少选；标签不为凑数。
- 必要时可调用最小检索补判定，但**不得**展开二轮宽泛研究。

## Section Workflow（/company-generate）

当用户要求生成章节时，必须先确认 `output/web_search_log.md` 与 `output/facts.md` 已存在且非空；
若 `output/company_facets.md` 不存在，先跑一次 Infer Workflow 再继续。

**每章写作 prompt 必须接收 4 类上下文**：
1. `{company_meta}` — `input/company.md`
2. `{web_search_log}` — 证据库
3. `{facts}` — 事实表
4. `{company_facets}` — **公司画像**（含 `preferred_lens` 与 `item_rules`），用于自适应裁剪

**每章写完后必须进入 Audit Loop**（见下节）；通过审计的章节才能合并入最终报告。

按 `input/company.md` 的 `report_mode` 选择产出：

### rough 模式（粗读闸门，1500-3000 字）

目标不是"写完整报告"，而是回答：**这家公司值不值得继续花时间？**

生成顺序：

1. `00_overview.md` — 一页纸粗读闸门
   - 价格 / 估值 / 底的类型 / 硬伤快筛 / edge 自检 / 初步结论
   - 结论限定为：`排除 / 观察池 / 进入深研 / 信息不足`
   - 500-900 字
2. `01_company_profile.md` — 公司识别与股权快照
   - 只写影响粗读结论的公司身份、实控人、上市地、核心子公司
   - 200-400 字
3. `02_business_model.md` — 一句话生意与盈利驱动
   - 公司卖什么、卖给谁、靠什么赚钱、利润来自销量 / 价格 / 成本 / 周转 / 杠杆中的哪几个
   - 300-500 字
4. `03_financials.md` — 阶段 0 财务与估值闸门
   - P/B、EV/EBITDA、EV/EBIT、FCF yield、净股东回报率、净现金 / 净负债、股本趋势
   - 周期股必须用正常化利润或低谷利润提示，不用景气高点倍数
   - 500-800 字
5. `06_recent_news.md` — 近况与硬伤快筛
   - 最近 6-12 个月重大公告 / 新闻；重点检查审计、监管、诉讼、关联交易、融资摊薄、分红回购
   - 300-600 字
6. `09_research_decision.md` — 是否进入深研
   - rough 模式默认生成，不需要额外 `--with-decision`
   - 必须列"否决项 / 观察池触发价或事件 / 下一步验证问题"
   - 400-800 字

rough 模式默认跳过 `04`、`05`、`07`、`08`；若硬伤集中在治理或行业周期，可在 `06` 或 `09`
中短段覆盖，不为完整性单独展开深章。

### deep 模式（8 章，1.5-2.5 万字深度报告）

按**严格顺序**生成（后文可引用前文，但每章数据必须独立引用 `SRC-XXX`）：

1. `01_company_profile.md` — 公司概况
   - 公司沿革、股权结构、组织架构、子公司清单
   - 600-1000 字
2. `02_business_model.md` — 业务与商业模式
   - 业务条线、收入构成、客户与渠道、上游供应链
   - 必须包含 Mermaid 业务结构图或价值链图
   - 800-1500 字
3. `03_financials.md` — 财务表现
   - 最近 3 年损益、资产负债、现金流核心指标
   - 趋势 + 同行横向对比
   - 必须用 markdown 表格列出数据，每个数字带 `SRC-XXX`
   - 1000-2000 字
4. `04_industry_competition.md` — 行业与竞争
   - 行业规模与增长、市场份额、可比公司对比表
   - 800-1500 字
5. `05_management_governance.md` — 管理层与治理
   - 核心高管简历、董事会构成、激励机制
   - 监管处罚 / 诉讼 / 关联交易（如有）
   - 600-1000 字
6. `06_recent_news.md` — 近期事件
   - 最近 6-12 个月公告与新闻按时间倒序
   - 600-1200 字
7. `07_swot.md` — SWOT 分析
   - 优势 / 劣势 / 机会 / 威胁，每项 2-4 条，配证据
   - 500-900 字
8. `08_investment_thesis.md` — 投资逻辑与风险
   - 核心多空逻辑、估值参考区间、关键监测指标
   - 700-1200 字

### short 模式（5 章，3000-5000 字简报）

只生成 `01`, `02`, `03`, `06`, `08` 五章，长度各砍半，跳过 `04`、`05`、`07`（行业 / 竞争内容可并入 `02`）。
若报告用途是投资初筛但用户未选择 `rough`，第 `08` 章仍必须包含"底的类型 + 硬伤快筛 + edge 自检"。

### 可选增强章节（默认关闭）

- **第 09 章 `09_research_decision.md` — 是否值得继续深研与待验证问题**
  - 触发条件：rough 模式默认生成；short / deep 模式用 `/company-all --with-decision` 或 `/company-generate --with-decision`
  - 写作时机：rough 模式在 `00/01/02/03/06` 就绪后生成；short / deep 模式在已选主体章节全部 audit 通过后生成
  - 内容定位：**研究决策章**，不是普通分析章——回答"现在值不值得继续投入研究资源"与"接下来最该验证什么"
  - 强制结论：`排除 / 观察池 / 进入深研 / 信息不足` 四选一 + 排序的待验证问题
  - 600-1200 字
- **第 00 章 `00_overview.md` — 一页纸粗读闸门 / 投资要点概览**
  - 触发条件：rough 模式默认生成一页纸粗读闸门；short / deep 模式用 `/company-all --with-overview` 或 `/company-generate --with-overview`
  - 写作时机：rough 模式在 Search + Infer 后优先生成；short / deep 模式为**最后回填**——所有其它章节（包括第 09 章，如启用）全部就绪后才写
  - 写作约束：rough 模式只使用 Search + Infer 已有证据形成闸门；short / deep 模式只压缩已成型判断链与卡点，**不补新事实、不补新来源、不补新证据锚点**
  - short / deep overview 默认 1 条主判断链 + 1 个主卡点 + 1 个最关键验证问题 + 2 个阈值事件
  - 400-800 字

## Audit Loop（审计闭环 · 必选）

借鉴 dayu-agent 的 `audit → confirm → repair` 三段式，每章在写完后必须经过下面四步，
直到通过或达到重试上限。

### Step 1：程序化预审（确定性，无 LLM）

每章写完先跑 `python3 scripts/check_evidence.py --section <chapter>`，输出
`output/audits/programmatic_check.json`。该脚本只做确定性的、低假阳率的检查：

- **E2**：正文出现的所有 `SRC-XXX` 必须在 `output/web_search_log.md` 中已登记。
- **E1 (粗筛)**：正文段落 / 表格行中出现数字 + 单位（亿元 / 万人 / 倍 / `%` / 元）的句子，
  必须在同一句或同一行内包含 `SRC-XXX`。结果分 `error / warning / ignore` 三级，**仅作为
  LLM 审计输入，不直接触发修复**。
- **C1 (禁词)**：扫描"据称 / 传闻 / 或将 / 据悉 / 应该会 / 业内人士"等弱来源用语。
- 白名单：年份（`2024 年`）、章节编号（`第 3 章`）、源 ID（`SRC-001`）、股票代码、
  页码、电话号码、ISO 日期。
- 输出同时记录 `source_log_hash` 与每章 `content_hash`；章节修复或证据库变更后必须重跑，
  否则合并前检查会判定为 stale。
- `make check` 使用 `--require-sections --fail-on-error` 严格模式；无章节或存在 error
  都返回非零。Audit Loop 内直接调用脚本时仍可使用默认诊断模式。

### Step 2：LLM 审计（`audit` role）

派发 `roles/audit.md`，输入：章节正文 + `web_search_log` 摘要 + `facts.md` + `programmatic_check.json`。
推荐通过 `python3 scripts/render_role.py audit --chapter <id>` 渲染。
输出 JSON：

```json
{
  "chapter": "03_financials",
  "category": "ok | evidence_insufficient | content_violation | style_violation",
  "violations": [
    {
      "rule": "E1 | E2 | E3 | C1 | C2 | S1 | S2 | S3 | S4",
      "severity": "blocking | warning",
      "claim_quote": "<正文原句>",
      "evidence_anchor": "SRC-007 或 null",
      "reason": "<违规原因>",
      "suggested_action": "patch | regenerate | drop_claim"
    }
  ]
}
```

规则集（裁剪后，适合中文调研报告）：

| 规则码 | 类别 | 含义 | 默认动作 |
|--------|------|------|----------|
| `E1` | evidence | 定量断言缺 `SRC-XXX` | patch（补引用或删数字） |
| `E2` | evidence | 引用的 `SRC-XXX` 未登记 | patch（删除/替换引用） |
| `E3` | evidence | 来源不足以支持该结论 | confirm → patch / drop_claim |
| `C1` | content | 事实 / 判断 / 假设混淆 | patch |
| `C2` | content | 出现投资建议 / 目标价 / 评级 | drop_claim |
| `S1` | style | 数字缺期间 / 单位 / 币种 / 口径 | patch |
| `S2` | style | 主观夸饰用语（"显著领先"、"护城河深厚"无证据） | patch |
| `S3` | style | 必备结构缺失（如 03 章无 markdown 表格、deep/short 的 02 章无 mermaid 图） | regenerate |
| `S4` | style | rough / 决策章缺价格闸门、底的类型、硬伤快筛、edge 自检或 stop/go 结论 | patch / regenerate |

**角色硬约束**：`audit` role 只读，不得调用 web 检索、不得改正文、不得新增证据。
若文本明确写的是"继续研究触发价 / 观察池触发价"，且上下文说明这只是时间管理阈值、
不是目标价、评级或买卖建议，不按 `C2` 处理；否则仍按投资建议处理。

### Step 3：证据复核（`confirm` role）

仅当存在 `E1 / E2 / E3` 类违规时触发，派发 `roles/confirm.md`
（`python3 scripts/render_role.py confirm --chapter <id>`）。
输入：违规条目 + `web_search_log` 全文 + `facts.md`。输出：

```json
{
  "results": [
    {
      "violation_index": 0,
      "status": "confirmed_missing | supported | supported_but_anchor_too_coarse | supported_elsewhere_in_same_filing",
      "src_id": "SRC-007",
      "supporting_quote": "<来源原文 1-3 句，必填>",
      "reason": "<复核结论>"
    }
  ]
}
```

**角色硬约束**：`confirm` 只在 `web_search_log` 与 `facts` 范围内复核；**严禁**自由搜索补证据；
`supporting_quote` 必填——若无原文可引则必须输出 `confirmed_missing`。

### Step 4：修复（`repair` / `regenerate` role）

按下表决策：

| confirm 结论 / audit 动作 | 实际动作 |
|---|---|
| `supported` / `supported_elsewhere_in_same_filing` | 在违规位置补正确 `SRC-XXX`，不改语义 |
| `supported_but_anchor_too_coarse` | 替换为更精确的 `SRC-XXX` |
| `confirmed_missing` + `suggested_action=drop_claim` | 删除该断言 |
| `confirmed_missing` + `suggested_action=patch` | 改写为"未公开披露"或可证版本 |
| `S3` 结构性失败 | 派发 `roles/regenerate.md` 整章重写 |
| `S4` rough / 决策章缺闸门结构 | 可局部补齐则 `repair`；缺整块结构则 `regenerate` |
| 其它 `patch` | 派发 `roles/repair.md` 做最小局部修复 |

修复完成后**回到 Step 1**重新审计；同一章重试上限 **3 次**，超限在 `manifest.json` 标记
`audit_status = "failed"`，由用户决定是否人工介入或 `--force` 跳过。

### Step 5：最终一致性审计（所有章节就绪后跑一次）

派发 `roles/final_audit.md`（`python3 scripts/render_role.py final_audit`），
检查跨章节问题：

- 同一指标在不同章节是否数字一致（如总营收在 03 与 08 章）
- 引用的 `SRC-XXX` 在最终合并文档中是否全部登记
- "数据截至 YYYY-MM-DD" 是否与 facts 里最旧数据冲突
- 第 09 章决策是否与第 08 章投资逻辑一致（若启用 09）
- 第 00 章概览是否引入了正文未出现过的新事实（若启用 00）
- rough 模式第 00 / 09 章是否坚持"排除 / 观察池 / 进入深研 / 信息不足"的研究决策，不输出买卖评级或目标价

输出 `output/audits/final_consistency.audit.json`，结构同 Step 2 但作用域为全文。
审计通过后，把当前按文件名排序、以 `\n\n---\n\n` 拼接的章节正文 SHA-256 写入
`manifest.final_audit.sections_hash`。

## Subagent Dispatch（子代理派发）

每个 role 的完整 prompt 都抽离到 `project-template/roles/<role>.md`，单一来源；
派发时用 `scripts/render_role.py` 填充占位符，stdout 即为完整 prompt。

### Copilot CLI（推荐 · 主要支持运行时）

Copilot CLI 用 `task` 工具派发到内置 agent type；最常用 `general-purpose`（Sonnet，
带完整工具集，可读写文件）。范式：

```text
1) bash:     python3 scripts/render_role.py audit --chapter 03_financials
             → 把 stdout 捕获为变量 prompt
2) task:
     agent_type: general-purpose
     name:       audit-03
     prompt:     <上一步 stdout 整段>
             → 子代理读取所需文件、执行审计、写出 output/audits/03_financials.audit.json、
               返回简短摘要
3) read_agent: 取摘要、检查文件落地
```

每个 role 文件的「Subagent 必须遵守」段定义了**该 role 的写权限边界**——主代理在派发
前应明确告知子代理"只可写指定路径"（例如 audit 只写 `audits/<chapter>.audit.json`，
不可改章节正文）。

### Claude Code

可在 `.claude/agents/<role>.md` 中按需建立子代理配置文件，其 system prompt 引用
`roles/<role>.md` 的 Prompt 段（同样配合 `render_role.py` 填充占位符）。也可直接调
Task 工具，与 Copilot CLI 范式一致。

### 无子代理运行时（如直接 LLM 调用）

主代理读 `roles/<role>.md` 的 Prompt 段 → `render_role.py` 填占位符 → 作为 system
prompt 调模型 → 自行处理输出文件落地。**契约与派发模式完全一致**。

### 派发拓扑建议

```text
main agent
  ├ search   role  → web_search_log.md / facts.md
  ├ infer    role  → company_facets.md            （可派发：write 类，general-purpose）
  └ for each chapter:
       ├ write role           → sections/<chapter>.md    （主代理执行更顺手）
       ├ check_evidence.py    → audits/programmatic_check.json
       ├ audit role           → audits/<chapter>.audit.json    （建议派发：上下文隔离）
       ├ confirm role         → audits/<chapter>.confirm.json  （建议派发：上下文隔离）
       └ repair / regenerate  → sections/<chapter>.md          （主代理执行更顺手）
  └ final_audit role          → audits/final_consistency.audit.json  （建议派发）
```

`audit` / `confirm` / `final_audit` 是**审计可信的基石**——它们必须只读、禁联网、
不接触正文写权限。派发给独立子代理是隔离最强的实现方式；不派发也能跑，但主代理必须
自律切换 system prompt 与文件写边界。

**派发与否对外契约一致**：无论用不用子代理，所有审计中间产物都落到 `output/audits/`，
manifest 状态机相同，最终合并产物相同。本 skill **不**依赖子代理可用。

## Full Workflow（/company-all）

当用户要求"一键完成"时：

1. 先执行 Search Workflow，生成 `web_search_log.md` + `facts.md`
2. 执行 Infer Workflow，生成 `company_facets.md`
3. 执行 Section Workflow + Audit Loop，逐章写作 → 程序化预审 → audit → confirm → repair
4. rough 模式默认写第 00 章与第 09 章；short / deep 模式仅在开启 `--with-decision` 时写第 09 章
5. short / deep 模式若开启 `--with-overview`，最后回填第 00 章 + 走一次 Audit Loop
6. 执行 Step 5 最终一致性审计
7. 运行 `make merge`；它会先验证流水线、刷新审计附录，再合并文档
8. 运行 `bash scripts/convert.sh` 转 Word
9. 若缺少 pandoc，明确提示 `brew install pandoc`，但不要阻断前面已完成的产物

`/company-all --fast` 模式：跳过 Audit Loop 与最终一致性审计；仍跑程序化预审作为最低红线。
适合"先看草稿、后续再补审"的场景。

## Long-running Stop Policy

长流程每完成一个 phase 或一次修复后记录 checkpoint。命中任一条件时必须停止派发新任务，
把 `manifest.run_status` 设为 `blocked`，写入 `blocked_reason` 并向用户展示当前状态：

1. **连续两个 checkpoint 无进展**：SRC 数、facts 数、章节状态、审计状态均未变化。
2. **重复同一失败**：相同错误、堆栈或失败断言连续出现 3 次。
3. **预算耗尽**：超过 `input/company.md` 配置的时间 / Token / API 成本预算；未填写时，
   rough / short / deep 的默认时长分别为 45 / 90 / 180 分钟。
4. **外部阻塞**：缺凭证、网络不可达、目标分支冲突、依赖锁无法解决。

停止后不得自动重试，也不得用 `--force` 绕过；`--force` 只处理已有章节的失败审计。

## web_search_log 模板

每条来源使用统一格式，便于后续 `SRC-XXX` 引用：

```markdown
## SRC-001
- 标题：xxx
- 发布机构：xxx
- URL：https://...
- 发布时间：YYYY-MM-DD
- 抓取时间：YYYY-MM-DD
- 来源类型：年报 / 交易所公告 / 监管文件 / 公司官网 / 新闻 / 第三方数据库
- 可信等级：Primary / Secondary / Tertiary
- 关键摘录：
  > 引用原文 1-3 句
- 拟用于章节：03_financials, 04_industry_competition
```

## facts.md 模板

```markdown
| Fact ID | 指标 | 数值 | 期间 | 币种 / 单位 | 口径 | 来源 ID | 备注 |
|---------|------|------|------|-------------|------|---------|------|
| F001 | 营业收入 | 6023.15 | FY2023 | 人民币亿元 | 合并 | SRC-001 | — |
| F002 | 归母净利润 | 300.41 | FY2023 | 人民币亿元 | 合并 | SRC-001 | — |
```

## manifest.json schema

`output/manifest.json` 是流水线的状态真源。每次写作、审计、修复都必须更新它。
没有 manifest 等同于"未走过任何流程"，重新跑就是新建一次。

```json
{
  "report_mode": "rough | short | deep",
  "workflow_mode": "full | fast",
  "run_status": "running | completed | blocked",
  "blocked_reason": null,
  "budget": {
    "wall_clock_minutes": 90,
    "token_or_cost_limit": null
  },
  "with_decision": false,
  "with_overview": false,
  "data_as_of": "2026-05-28",
  "source_log_hash": "sha256:...",
  "facts_hash": "sha256:...",
  "company_facets_hash": "sha256:...",
  "sections": {
    "01_company_profile": {
      "status": "generated | skipped | failed",
      "content_hash": "sha256:...",
      "audit_status": "passed | failed | stale | not_run",
      "audited_content_hash": "sha256:...",
      "repair_attempts": 1,
      "audit_files": [
        "output/audits/01_company_profile.audit.json",
        "output/audits/01_company_profile.confirm.json"
      ],
      "last_updated": "2026-05-28T10:32:11Z"
    }
  },
  "final_audit": {
    "status": "passed | failed | not_run",
    "sections_hash": "sha256:...",
    "audit_file": "output/audits/final_consistency.audit.json",
    "last_updated": "2026-05-28T11:05:42Z"
  }
}
```

含义：

- `run_status` 只有在全部必需章节与对应检查完成后才能写 `completed`；命中停止条件写
  `blocked`，并在 `blocked_reason` 记录可操作原因。
- `status` = `generated` 表示章节正文存在；`failed` 表示生成失败；`skipped` 仅用于当前
  报告模式不要求的章节，不能替代必需章节。
- `content_hash` 是章节文件原始字节的 SHA-256；每次写作、repair、regenerate 后更新。
- `audited_content_hash` 只在该版本正文 audit 通过后写入，必须与当前 `content_hash` 一致。
- `audit_status` = `stale` 当 `source_log_hash` 或 `facts_hash` 与上次审计时不一致——
  此时合并前必须重审。
- `repair_attempts` 达到 3 后**禁止**继续自动修复，必须把违规清单展示给用户由用户决定。
- `final_audit.sections_hash` 使用 `scripts/pipeline_common.py` 的章节拼接规则计算；任何章节
  变化都会使最终审计失效。
- `workflow_mode=fast` 可跳过单章与最终 LLM 审计，但程序化检查必须覆盖全部必需章节且
  不得存在 error。

合并前运行 `python3 scripts/verify_pipeline.py`。它会强制检查输入模式与日期、必需文件、
三类来源 hash、严格章节集合、程序化检查新鲜度、单章审计与最终审计。`--force` 仅绕过
已有合法 audit JSON 的 `audit_status=failed`；缺审计产物、缺章节、hash 不一致、
`not_run/stale`、程序化 error 或最终审计失败均不可绕过。

## Output Checklist

```text
- output/web_search_log.md             # rough 覆盖闸门必需来源；short/deep 建议至少 15 条 SRC，覆盖 8 个维度
- output/facts.md                      # rough 覆盖价格/估值/财务/硬伤事实；short/deep 建议关键事实 ≥ 20 行
- output/company_facets.md             # 公司画像
- output/manifest.json                 # 流水线状态
- output/audits/programmatic_check.json
- output/audits/01_company_profile.audit.json
- output/audits/01_company_profile.confirm.json    # 仅当 audit 命中 E 类违规
- output/audits/...（其它章节同上）
- output/audits/final_consistency.audit.json
- output/sections/00_overview.md                    # rough 默认；short/deep 仅当 --with-overview
- output/sections/01_company_profile.md
- output/sections/02_business_model.md
- output/sections/03_financials.md
- output/sections/04_industry_competition.md        # deep
- output/sections/05_management_governance.md       # deep
- output/sections/06_recent_news.md
- output/sections/07_swot.md                        # deep
- output/sections/08_investment_thesis.md
- output/sections/09_research_decision.md           # rough 默认；short/deep 仅当 --with-decision
- output/research_report.md
- output/research_report.docx
```

## Useful Commands

```bash
make verify                                         # 跑仓库级单元测试（无需生成报告）
make check                                          # 严格 evidence 检查；无章节或 error 时失败
make pipeline-check                                 # 校验 manifest / hash / 章节 / 审计闸门
make pipeline-check FORCE=1                         # 仅绕过 audit_status=failed
make render-role ROLE=audit CHAPTER=03_financials   # 渲染指定 role 的完整 prompt 到 stdout
make audit-summary                                  # 把 audits/*.json 聚合成 markdown 附录
make merge                                          # 先校验再合并各章节（含审计附录）
make merge FORCE=1                                  # 仅绕过 audit_status=failed
make docx                                           # 转 Word
make clean                                          # 清理所有生成文件
make clean-audits                                   # 仅清理 audits/ 目录
make help                                           # 显示帮助
```

直接调用脚本：

```bash
python3 scripts/render_role.py infer
python3 scripts/render_role.py audit --chapter 03_financials
python3 scripts/render_role.py confirm --chapter 03_financials
python3 scripts/render_role.py repair --chapter 03_financials
python3 scripts/render_role.py regenerate --chapter 03_financials
python3 scripts/render_role.py final_audit
```

## Disclaimer

本 skill 输出的所有报告基于公开信息整理，不构成投资建议、评级意见或买卖证券建议。公开信息可能存在滞后、遗漏或错误，使用者应自行核验关键数据。
