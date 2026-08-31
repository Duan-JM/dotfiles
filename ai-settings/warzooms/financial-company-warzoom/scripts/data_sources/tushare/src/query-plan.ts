import type { QueryTask, TushareScalar } from "./types.js";

export const SUPPORTED_DATASETS = [
  "stock_basic",
  "income",
  "balancesheet",
  "cashflow",
  "fina_indicator",
  "daily",
  "daily_basic",
  "dividend",
  "repurchase",
] as const;

export type DatasetName = (typeof SUPPORTED_DATASETS)[number];

const FINANCIAL_DATASETS = new Set<DatasetName>([
  "income",
  "balancesheet",
  "cashflow",
  "fina_indicator",
]);

const SOURCE_URL = "https://tushare.pro/document/2";

const FIELDS: Partial<Record<DatasetName, string>> = {
  stock_basic:
    "ts_code,symbol,name,area,industry,fullname,enname,market,exchange,curr_type,list_status,list_date,delist_date,is_hs,act_name,act_ent_type",
  daily: "ts_code,trade_date,open,high,low,close,pre_close,change,pct_chg,vol,amount",
  daily_basic:
    "ts_code,trade_date,close,turnover_rate,pe,pe_ttm,pb,ps,ps_ttm,dv_ratio,dv_ttm,total_share,float_share,free_share,total_mv,circ_mv",
};

export interface QueryPlanOptions {
  tsCode: string;
  periods: string[];
  asOf: string;
  datasets: DatasetName[];
}

const MAX_PERIODS = 20;
const MAX_TOTAL_ATTEMPTS = 200;

function parseDate(value: string): Date {
  const year = Number(value.slice(0, 4));
  const month = Number(value.slice(4, 6));
  const day = Number(value.slice(6, 8));
  return new Date(Date.UTC(year, month - 1, day));
}

function formatDate(value: Date): string {
  const year = value.getUTCFullYear();
  const month = String(value.getUTCMonth() + 1).padStart(2, "0");
  const day = String(value.getUTCDate()).padStart(2, "0");
  return `${year}${month}${day}`;
}

export function subtractDays(value: string, days: number): string {
  const date = parseDate(value);
  date.setUTCDate(date.getUTCDate() - days);
  return formatDate(date);
}

export function validateDate(value: string, label: string): void {
  if (!/^\d{8}$/.test(value) || formatDate(parseDate(value)) !== value) {
    throw new Error(`${label} 必须是有效的 YYYYMMDD 日期`);
  }
}

function createTask(
  apiName: DatasetName,
  idSuffix: string,
  params: Record<string, TushareScalar>,
  cardinality: "one" | "many",
): QueryTask {
  return {
    id: idSuffix ? `${apiName}-${idSuffix}` : apiName,
    apiName,
    params,
    fields: FIELDS[apiName] ?? "",
    sourceUrl: SOURCE_URL,
    cardinality,
  };
}

export function buildQueryPlan(options: QueryPlanOptions): QueryTask[] {
  if (!/^\d{6}\.(?:SH|SZ|BJ)$/.test(options.tsCode)) {
    throw new Error("ts_code 必须类似 600000.SH、000001.SZ 或 430047.BJ");
  }
  validateDate(options.asOf, "as_of");
  const periods = [...new Set(options.periods)];
  if (periods.length > MAX_PERIODS) {
    throw new Error(`报告期数量不能超过 ${MAX_PERIODS}`);
  }
  if (options.datasets.length === 0) {
    throw new Error("至少需要指定一个数据集");
  }
  for (const period of periods) {
    validateDate(period, "period");
  }

  const needsPeriods = options.datasets.some((dataset) => FINANCIAL_DATASETS.has(dataset));
  if (needsPeriods && periods.length === 0) {
    throw new Error("查询财务数据时必须通过 --periods 指定至少一个报告期");
  }

  const tasks: QueryTask[] = [];
  for (const dataset of options.datasets) {
    if (FINANCIAL_DATASETS.has(dataset)) {
      for (const period of periods) {
        tasks.push(
          createTask(dataset, period, { ts_code: options.tsCode, period }, "one"),
        );
      }
      continue;
    }

    if (dataset === "daily" || dataset === "daily_basic") {
      tasks.push(
        createTask(
          dataset,
          options.asOf,
          {
            ts_code: options.tsCode,
            start_date: subtractDays(options.asOf, 20),
            end_date: options.asOf,
          },
          "many",
        ),
      );
      continue;
    }

    tasks.push(
      createTask(
        dataset,
        "",
        { ts_code: options.tsCode },
        dataset === "stock_basic" ? "one" : "many",
      ),
    );
  }
  return tasks;
}

export function validateRequestBudget(taskCount: number, retries: number): void {
  const maximumAttempts = taskCount * (retries + 1);
  if (maximumAttempts > MAX_TOTAL_ATTEMPTS) {
    throw new Error(
      `查询计划最多可能发起 ${maximumAttempts} 次请求，超过单次运行上限 ${MAX_TOTAL_ATTEMPTS}；请减少报告期、数据集或重试次数`,
    );
  }
}
