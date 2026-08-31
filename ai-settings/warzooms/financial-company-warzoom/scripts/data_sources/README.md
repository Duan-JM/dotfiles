# TypeScript 数据查询脚本

此目录用于可信数据源连接器。当前已实现：

- `tushare/`：通过 Tushare Pro HTTP API 查询 A 股结构化数据。

不同连接器保持独立 package；在第二个连接器证明存在稳定共性前，不提取通用框架，避免
根据单一接口固化错误抽象。

## 文件组织

每个数据源使用独立目录：

```text
scripts/data_sources/<source>/
  README.md
  package.json
  tsconfig.json
  src/
  tests/
```

不同数据源不得共享凭证文件。只有在第二个连接器证明存在稳定共性后，才允许提取
`scripts/data_sources/shared/`。

## 稳定命令契约

每个连接器必须提供以下 npm scripts：

| 命令 | 作用 |
|------|------|
| `npm run query -- <args>` | 执行一次非交互查询 |
| `npm run typecheck` | TypeScript 类型检查 |
| `npm test` | 运行不访问真实付费接口的单元测试 |

`query` 必须支持：

- 明确指定公司标识、查询类型和日期范围。
- 通过环境变量读取凭证，并在启动时检查缺失凭证。
- 设置请求超时、有限重试和限流退避。
- 将原始响应和标准化结果写入 `output/raw/<source>/`。
- 重复执行同一请求时保持幂等，禁止静默覆盖内容不同的历史响应。
- 用非零退出码区分认证失败、限流、无数据、参数错误、网络错误和解析错误。

## 输出格式

每次查询至少生成一个 JSON object：

```json
{
  "schema_version": 1,
  "source": "example",
  "request": {
    "query_type": "financials",
    "company_id": "EXAMPLE",
    "period_start": "2025-01-01",
    "period_end": "2025-12-31"
  },
  "retrieved_at": "2026-08-31T00:00:00Z",
  "source_url": "https://example.invalid/resource",
  "source_tier": "primary",
  "response_sha256": "sha256:...",
  "status": "ok",
  "records": []
}
```

`status` 仅允许：

- `ok`
- `no_data`
- `authentication_failed`
- `permission_denied`
- `rate_limited`
- `network_error`
- `invalid_request`
- `parse_error`
- `ambiguous_data`

失败结果也必须保留请求元数据，但不得伪造空的成功响应。原始数据进入 `facts.md` 前仍需由
主代理登记为 `SRC-XXX`，并遵守项目现有证据与审计规则。

## 安全和测试

- 测试使用 fixture 或本地 mock，不得消耗真实付费 API 配额。
- 日志和异常必须对凭证、cookie、Authorization header 做脱敏。
- 不提交 `.env`、响应中的个人敏感信息、供应商许可禁止再分发的数据。
- 连接器必须测试正常返回、无数据、超时、限流、非法响应和字段缺失。
- 外部服务不可用时明确失败；不得自动切换到来源不明的网站补数。
