# Tushare 数据源连接器

通过 Tushare Pro 官方 HTTP API 获取 A 股结构化数据。连接器使用 TypeScript 实现，不依赖
Tushare Python SDK。

Tushare 属于聚合型 Secondary source。若接口数据与交易所公告、上市公司定期报告等
Primary source 冲突，必须保留差异并以 Primary source 为准。

## 覆盖数据

默认查询以下数据集：

- `stock_basic`：公司名称、上市状态、行业、交易所和实际控制人。
- `income`、`balancesheet`、`cashflow`：指定报告期的三张财务报表。
- `fina_indicator`：ROE、ROA、ROIC、利润率、现金转化和债务指标。
- `daily`、`daily_basic`：截止日前约 20 个自然日的价格、成交、估值、市值和股息率。
- `dividend`、`repurchase`：分红和股份回购记录。

财务接口按报告期逐次查询，避免混合不同报告类型后静默取错记录。
若一个预期单条记录的查询返回多条记录，结果标记为 `ambiguous_data`，要求人工确认报告
类型、公司类型或修订版本。

## 安装

```bash
cd scripts/data_sources/tushare
npm ci --ignore-scripts
```

在 Tushare Pro 获取 token，并只在当前 shell 设置：

```bash
export TUSHARE_TOKEN="<your-token>"
```

## 使用

先检查查询计划，不访问网络：

```bash
npm run query -- \
  --ts-code 600000.SH \
  --periods 20251231,20241231,20231231 \
  --as-of 20260831 \
  --dry-run
```

执行查询：

```bash
npm run query -- \
  --ts-code 600000.SH \
  --periods 20251231,20241231,20231231 \
  --as-of 20260831
```

只查询部分数据集：

```bash
npm run query -- \
  --ts-code 600000.SH \
  --as-of 20260831 \
  --datasets stock_basic,daily,daily_basic
```

输出写入：

```text
output/raw/tushare/<ts-code>/<api>/
  *.raw.json
  *.normalized.json
output/raw/tushare/<ts-code>/runs/
  *.json
```

文件名同时包含请求 hash 和响应 hash。相同请求与相同响应不会重复覆盖；相同请求返回新数据时
会保留新旧两个版本。

单次响应限制为 20 MiB、最多 100,000 条记录；报告期最多 20 个且自动去重；重试次数限制
为 0–5 次。单次运行按“任务数 × 最大尝试次数”限制为最多 200 次请求；响应体采用流式
计数，超过上限立即终止读取；持续限流会停止后续查询，避免放大 API 请求。`make clean`
不删除 `output/raw/`，原始数据的保留与删除由使用者显式管理。

也可通过 Make 调用，参数使用独立变量传递：

```bash
make tushare-query \
  TS_CODE=600000.SH \
  PERIODS=20251231,20241231,20231231 \
  AS_OF=20260831
```

## 退出码

| 退出码 | 含义 |
|-------:|------|
| 0 | 至少一个查询成功，且没有硬错误 |
| 2 | 参数或请求错误 |
| 3 | Token 缺失或认证失败 |
| 4 | 接口权限或积分不足 |
| 5 | 超过访问频率 |
| 6 | 网络或 HTTP 错误 |
| 7 | 响应 JSON 或字段结构无法解析 |
| 8 | 所有查询均无数据 |
| 9 | 预期单条记录但返回多条，数据口径存在歧义 |
| 10 | 原始数据或运行摘要写入失败 |

单个查询无数据不会覆盖其它成功结果。出现权限、网络、解析等硬错误时，连接器仍会保存已经
完成的查询和运行摘要，并以非零状态退出。单项落盘失败会在运行摘要中使用
`storage_error`，但不会伪装成已生成标准化结果。

## 验证

```bash
npm run typecheck
npm test
```

测试全部使用本地模拟响应，不访问真实 Tushare API，也不会消耗接口额度。
