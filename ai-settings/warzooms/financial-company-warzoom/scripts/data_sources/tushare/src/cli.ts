#!/usr/bin/env node

import { realpathSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

import { TushareClient } from "./client.js";
import {
  buildQueryPlan,
  SUPPORTED_DATASETS,
  type DatasetName,
  validateRequestBudget,
} from "./query-plan.js";
import { storeExecution, storeRunSummary } from "./storage.js";
import type { QueryStatus } from "./types.js";

interface CliOptions {
  tsCode: string;
  periods: string[];
  asOf: string;
  datasets: DatasetName[];
  outputDir: string;
  timeoutMs: number;
  retries: number;
  dryRun: boolean;
}

const DEFAULT_DATASETS = [...SUPPORTED_DATASETS];

const EXIT_CODES: Record<QueryStatus, number> = {
  ok: 0,
  no_data: 8,
  authentication_failed: 3,
  permission_denied: 4,
  rate_limited: 5,
  network_error: 6,
  invalid_request: 2,
  parse_error: 7,
  ambiguous_data: 9,
};
const STORAGE_ERROR_EXIT_CODE = 10;

function usage(): string {
  return `用法：
  npm run query -- --ts-code 600000.SH --periods 20251231,20241231,20231231 --as-of 20260831

参数：
  --ts-code <代码>       必填，Tushare 股票代码
  --periods <日期列表>   查询财务接口时必填，逗号分隔 YYYYMMDD
  --as-of <日期>         必填，行情查询截止日 YYYYMMDD
  --datasets <列表>      可选，默认查询全部核心数据集
  --output-dir <目录>    可选，默认 output/raw/tushare
  --timeout-ms <毫秒>    可选，默认 15000
  --retries <次数>       可选，默认 2
  --dry-run              只显示查询计划，不访问 API
  --help                 显示帮助

支持的数据集：
  ${SUPPORTED_DATASETS.join(", ")}

凭证：
  通过环境变量 TUSHARE_TOKEN 提供。`;
}

function readValue(args: string[], index: number, option: string): string {
  const value = args[index + 1];
  if (value === undefined || value.startsWith("--")) {
    throw new Error(`${option} 缺少参数值`);
  }
  return value;
}

function parsePositiveInteger(value: string, option: string): number {
  const parsed = Number(value);
  if (!Number.isInteger(parsed) || parsed < 0) {
    throw new Error(`${option} 必须是非负整数`);
  }
  return parsed;
}

function parseBoundedInteger(
  value: string,
  option: string,
  minimum: number,
  maximum: number,
): number {
  const parsed = parsePositiveInteger(value, option);
  if (parsed < minimum || parsed > maximum) {
    throw new Error(`${option} 必须在 ${minimum}..${maximum} 之间`);
  }
  return parsed;
}

function parseDatasets(value: string): DatasetName[] {
  const names = value.split(",").map((item) => item.trim()).filter(Boolean);
  const unsupported = names.filter(
    (name) => !SUPPORTED_DATASETS.includes(name as DatasetName),
  );
  if (unsupported.length > 0) {
    throw new Error(`不支持的数据集：${unsupported.join(", ")}`);
  }
  const datasets = [...new Set(names as DatasetName[])];
  if (datasets.length === 0) {
    throw new Error("--datasets 至少需要一个数据集");
  }
  return datasets;
}

export function parseArgs(args: string[]): CliOptions {
  const projectRoot = path.resolve(
    path.dirname(fileURLToPath(import.meta.url)),
    "../../../..",
  );
  const options: CliOptions = {
    tsCode: "",
    periods: [],
    asOf: "",
    datasets: DEFAULT_DATASETS,
    outputDir: path.join(projectRoot, "output", "raw", "tushare"),
    timeoutMs: 15_000,
    retries: 2,
    dryRun: false,
  };

  for (let index = 0; index < args.length; index += 1) {
    const argument = args[index];
    switch (argument) {
      case "--ts-code":
        options.tsCode = readValue(args, index, argument);
        index += 1;
        break;
      case "--periods":
        options.periods = readValue(args, index, argument)
          .split(",")
          .map((item) => item.trim())
          .filter(Boolean);
        index += 1;
        break;
      case "--as-of":
        options.asOf = readValue(args, index, argument);
        index += 1;
        break;
      case "--datasets":
        options.datasets = parseDatasets(readValue(args, index, argument));
        index += 1;
        break;
      case "--output-dir":
        options.outputDir = path.resolve(readValue(args, index, argument));
        index += 1;
        break;
      case "--timeout-ms":
        options.timeoutMs = parseBoundedInteger(
          readValue(args, index, argument),
          argument,
          1_000,
          120_000,
        );
        index += 1;
        break;
      case "--retries":
        options.retries = parseBoundedInteger(
          readValue(args, index, argument),
          argument,
          0,
          5,
        );
        index += 1;
        break;
      case "--dry-run":
        options.dryRun = true;
        break;
      case "--help":
        console.log(usage());
        process.exit(0);
      default:
        throw new Error(`未知参数：${argument}`);
    }
  }

  if (!options.tsCode) {
    throw new Error("缺少 --ts-code");
  }
  if (!options.asOf) {
    throw new Error("缺少 --as-of");
  }
  return options;
}

async function main(): Promise<void> {
  let options: CliOptions;
  try {
    options = parseArgs(process.argv.slice(2));
  } catch (error) {
    console.error(`参数错误：${error instanceof Error ? error.message : String(error)}`);
    console.error(usage());
    process.exitCode = 2;
    return;
  }

  let plan;
  try {
    plan = buildQueryPlan(options);
    validateRequestBudget(plan.length, options.retries);
  } catch (error) {
    console.error(`查询计划无效：${error instanceof Error ? error.message : String(error)}`);
    process.exitCode = 2;
    return;
  }

  if (options.dryRun) {
    console.log(JSON.stringify(plan, null, 2));
    return;
  }

  const token = process.env.TUSHARE_TOKEN;
  if (!token?.trim()) {
    console.error("缺少环境变量 TUSHARE_TOKEN");
    process.exitCode = 3;
    return;
  }

  const retrievedAt = new Date().toISOString();
  const client = new TushareClient({
    token,
    timeoutMs: options.timeoutMs,
    maxRetries: options.retries,
  });
  const summaryResults: Array<{
    id: string;
    status: string;
    message: string | null;
    normalized_path: string | null;
    raw_path: string | null;
  }> = [];
  let exitCode = 0;
  let successCount = 0;

  for (const task of plan) {
    const execution = await client.query(task);
    try {
      const stored = await storeExecution(
        options.outputDir,
        options.tsCode,
        execution,
        retrievedAt,
      );
      summaryResults.push({
        id: task.id,
        status: execution.status,
        message: execution.message,
        normalized_path: stored.normalizedPath,
        raw_path: stored.rawPath,
      });
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      summaryResults.push({
        id: task.id,
        status: "storage_error",
        message,
        normalized_path: null,
        raw_path: null,
      });
      console.error(`[storage_error] ${task.id}：${message}`);
      exitCode ||= STORAGE_ERROR_EXIT_CODE;
      continue;
    }
    if (execution.status === "ok") {
      successCount += 1;
    } else if (execution.status !== "no_data" && exitCode === 0) {
      exitCode = EXIT_CODES[execution.status];
    }
    console.log(
      `[${execution.status}] ${task.id}：${execution.records.length} 条记录，尝试 ${execution.attempts} 次`,
    );
    if (execution.status === "rate_limited") {
      console.error("持续触发访问频率限制，停止后续查询以避免放大请求");
      break;
    }
  }

  try {
    const summaryPath = await storeRunSummary(
      options.outputDir,
      options.tsCode,
      retrievedAt,
      summaryResults,
    );
    console.log(`查询摘要：${summaryPath}`);
  } catch (error) {
    console.error(
      `运行摘要写入失败：${error instanceof Error ? error.message : String(error)}`,
    );
    exitCode ||= STORAGE_ERROR_EXIT_CODE;
  }

  if (successCount === 0 && exitCode === 0) {
    exitCode = EXIT_CODES.no_data;
  }
  process.exitCode = exitCode;
}

if (
  process.argv[1] !== undefined &&
  realpathSync(fileURLToPath(import.meta.url)) ===
    realpathSync(path.resolve(process.argv[1]))
) {
  await main();
}
