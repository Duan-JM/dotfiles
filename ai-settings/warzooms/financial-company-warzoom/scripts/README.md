# 脚本目录

本目录只存放确定性、可重复执行的程序。Agent 提示词与角色约束放在 `roles/` 和
`templates/`，不得混入脚本实现。

## 当前分类

| 分类 | 文件 | 使用方式 |
|------|------|----------|
| 流水线入口 | `check_evidence.py`、`verify_pipeline.py`、`merge.py`、`render_role.py`、`audit_summary.py` | 由 Makefile、主代理或其它脚本显式调用 |
| 流水线内部库 | `pipeline_common.py`、`industry_rules.py` | 只供其它 Python 脚本导入，不作为稳定命令入口 |
| 可选分析工具 | `financial_quality_check.py`、`valuation_calculator.py` | 仅在用户提供结构化输入并明确需要时运行 |
| 输出转换 | `convert.sh` | 将合并后的 Markdown 转为 Word |
| 数据查询 | `data_sources/` | TypeScript 数据源连接器；当前包含 Tushare Pro |

所有脚本均为按需调用，不存在常驻服务或自动后台任务。

## 新增脚本规则

1. 先判断脚本属于流水线、分析、转换还是数据查询；数据查询统一放入
   `scripts/data_sources/`。
2. 一个稳定命令只承担一个职责。共享实现可以拆为内部模块，但不得复制 hash、证据格式或
   manifest 校验逻辑。
3. 输入和输出必须可被非交互环境使用；成功信息写 stdout，错误信息写 stderr，并使用非零
   退出码表示失败。
4. 不在代码、参数默认值或输出文件中保存 token、cookie、账号信息。
5. 新增或修改稳定入口时，同步更新 Makefile、`SKILL.md`、`AGENTS.md` 和对应测试。
6. 生成文件写入 `output/`，不得修改 `input/`、`roles/`、`templates/` 或历史原始数据。

## 数据查询脚本边界

数据查询脚本负责获取和标准化数据，不负责撰写研究结论。它们不得直接生成章节正文，也不得
自行宣称来源已通过审计。

推荐数据流：

```text
外部数据源
  → data_sources 查询脚本
  → output/raw/<source>/<request-id>.json
  → 主代理登记 SRC-XXX 和 facts.md
  → check_evidence / audit / confirm
```

原始响应和标准化结果应保留来源、查询参数、抓取时间、数据期间、币种、单位、会计口径、
响应 hash 与明确错误状态，确保后续可以追溯和重放。
