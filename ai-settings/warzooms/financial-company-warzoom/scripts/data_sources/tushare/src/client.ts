import type {
  QueryExecution,
  QueryStatus,
  QueryTask,
  TushareRawResponse,
  TushareScalar,
} from "./types.js";

type FetchLike = (
  input: string | URL | globalThis.Request,
  init?: RequestInit,
) => Promise<Response>;

export interface TushareClientOptions {
  token: string;
  apiUrl?: string;
  timeoutMs?: number;
  maxRetries?: number;
  maxResponseBytes?: number;
  fetchFn?: FetchLike;
  sleepFn?: (milliseconds: number) => Promise<void>;
  randomFn?: () => number;
}

const DEFAULT_API_URL = "https://api.tushare.pro";
const DEFAULT_MAX_RESPONSE_BYTES = 20 * 1024 * 1024;
const MAX_RECORDS = 100_000;

class ResponseTooLargeError extends Error {}

function sleep(milliseconds: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, milliseconds));
}

async function readResponseText(
  response: Response,
  maxBytes: number,
  controller: AbortController,
): Promise<string> {
  if (response.body === null) {
    return "";
  }

  const reader = response.body.getReader();
  const decoder = new TextDecoder();
  let bytesRead = 0;
  let text = "";
  try {
    while (true) {
      const { done, value } = await reader.read();
      if (done) {
        return text + decoder.decode();
      }
      bytesRead += value.byteLength;
      if (bytesRead > maxBytes) {
        controller.abort();
        throw new ResponseTooLargeError(`响应大小超过上限 ${maxBytes} 字节`);
      }
      text += decoder.decode(value, { stream: true });
    }
  } finally {
    reader.releaseLock();
  }
}

function classifyApiError(code: number, message: string): QueryStatus {
  const normalized = message.toLowerCase();
  if (normalized.includes("token") || normalized.includes("认证")) {
    return "authentication_failed";
  }
  if (
    normalized.includes("频率") ||
    normalized.includes("频次") ||
    normalized.includes("最多访问") ||
    normalized.includes("rate limit") ||
    normalized.includes("too many")
  ) {
    return "rate_limited";
  }
  if (code === 2002 || normalized.includes("权限") || normalized.includes("积分")) {
    return "permission_denied";
  }
  return "invalid_request";
}

function parseRecords(
  response: TushareRawResponse,
): Array<Record<string, TushareScalar>> {
  const fields = response.data?.fields;
  const items = response.data?.items;
  if (!Array.isArray(fields) || !fields.every((field) => typeof field === "string")) {
    throw new Error("响应 data.fields 不是字符串数组");
  }
  if (!Array.isArray(items)) {
    throw new Error("响应 data.items 不是数组");
  }
  if (items.length > MAX_RECORDS) {
    throw new Error(`响应记录数超过上限 ${MAX_RECORDS}`);
  }
  if (new Set(fields).size !== fields.length || fields.some((field) => field.length === 0)) {
    throw new Error("响应 fields 包含空字段名或重复字段名");
  }

  return items.map((item, rowIndex) => {
    if (!Array.isArray(item) || item.length !== fields.length) {
      throw new Error(`第 ${rowIndex + 1} 行字段数量与 fields 不一致`);
    }
    return Object.fromEntries(
      fields.map((field, index) => {
        const value = item[index];
        if (
          value !== null &&
          typeof value !== "string" &&
          typeof value !== "number" &&
          typeof value !== "boolean"
        ) {
          throw new Error(`第 ${rowIndex + 1} 行字段 ${field} 不是标量值`);
        }
        return [field, value];
      }),
    );
  });
}

export class TushareClient {
  readonly apiUrl: string;
  readonly timeoutMs: number;
  readonly maxRetries: number;
  readonly maxResponseBytes: number;

  private readonly token: string;
  private readonly fetchFn: FetchLike;
  private readonly sleepFn: (milliseconds: number) => Promise<void>;
  private readonly randomFn: () => number;

  constructor(options: TushareClientOptions) {
    if (!options.token.trim()) {
      throw new Error("TUSHARE_TOKEN 不能为空");
    }
    this.token = options.token;
    this.apiUrl = options.apiUrl ?? DEFAULT_API_URL;
    this.timeoutMs = options.timeoutMs ?? 15_000;
    this.maxRetries = options.maxRetries ?? 2;
    this.maxResponseBytes = options.maxResponseBytes ?? DEFAULT_MAX_RESPONSE_BYTES;
    if (!Number.isInteger(this.maxRetries) || this.maxRetries < 0 || this.maxRetries > 5) {
      throw new Error("maxRetries 必须是 0..5 的整数");
    }
    if (
      !Number.isInteger(this.timeoutMs) ||
      this.timeoutMs < 1_000 ||
      this.timeoutMs > 120_000
    ) {
      throw new Error("timeoutMs 必须在 1000..120000 之间");
    }
    if (
      !Number.isInteger(this.maxResponseBytes) ||
      this.maxResponseBytes <= 0 ||
      this.maxResponseBytes > 100 * 1024 * 1024
    ) {
      throw new Error("maxResponseBytes 必须在 1..104857600 之间");
    }
    this.fetchFn = options.fetchFn ?? fetch;
    this.sleepFn = options.sleepFn ?? sleep;
    this.randomFn = options.randomFn ?? Math.random;
  }

  private retryDelay(attempt: number, response?: Response): number {
    const retryAfter = response?.headers.get("retry-after");
    if (retryAfter && /^\d+$/.test(retryAfter)) {
      return Math.min(Number(retryAfter) * 1_000, 30_000);
    }
    const base = Math.min(500 * 2 ** (attempt - 1), 10_000);
    return base + Math.floor(this.randomFn() * 250);
  }

  async query(task: QueryTask): Promise<QueryExecution> {
    let attempts = 0;
    let lastNetworkMessage = "请求未执行";

    while (attempts <= this.maxRetries) {
      attempts += 1;
      const controller = new AbortController();
      const timer = setTimeout(() => controller.abort(), this.timeoutMs);

      try {
        const response = await this.fetchFn(this.apiUrl, {
          method: "POST",
          headers: { "content-type": "application/json" },
          body: JSON.stringify({
            api_name: task.apiName,
            token: this.token,
            params: task.params,
            fields: task.fields,
          }),
          signal: controller.signal,
          redirect: "error",
        });

        if (!response.ok) {
          if ((response.status === 429 || response.status >= 500) && attempts <= this.maxRetries) {
            await this.sleepFn(this.retryDelay(attempts, response));
            continue;
          }
          const status: QueryStatus =
            response.status === 400
              ? "invalid_request"
              : response.status === 401
                ? "authentication_failed"
                : response.status === 403
                  ? "permission_denied"
                  : response.status === 429
                    ? "rate_limited"
                    : "network_error";
          return {
            task,
            status,
            message: `HTTP ${response.status} ${response.statusText}`.trim(),
            records: [],
            rawResponse: null,
            attempts,
          };
        }

        const contentLength = Number(response.headers.get("content-length") ?? "0");
        if (Number.isFinite(contentLength) && contentLength > this.maxResponseBytes) {
          return {
            task,
            status: "parse_error",
            message: `响应大小超过上限 ${this.maxResponseBytes} 字节`,
            records: [],
            rawResponse: null,
            attempts,
          };
        }

        let responseText: string;
        try {
          responseText = await readResponseText(
            response,
            this.maxResponseBytes,
            controller,
          );
        } catch (error) {
          if (error instanceof ResponseTooLargeError) {
            return {
              task,
              status: "parse_error",
              message: error.message,
              records: [],
              rawResponse: null,
              attempts,
            };
          }
          throw error;
        }

        let payload: TushareRawResponse;
        try {
          const parsed: unknown = JSON.parse(responseText);
          if (parsed === null || typeof parsed !== "object" || Array.isArray(parsed)) {
            return {
              task,
              status: "parse_error",
              message: "响应顶层必须是 JSON object",
              records: [],
              rawResponse: null,
              attempts,
            };
          }
          payload = parsed as TushareRawResponse;
        } catch (error) {
          return {
            task,
            status: "parse_error",
            message: error instanceof Error ? error.message : "响应不是合法 JSON",
            records: [],
            rawResponse: null,
            attempts,
          };
        }

        if (
          typeof payload.code !== "number" ||
          (payload.msg !== null && payload.msg !== undefined && typeof payload.msg !== "string")
        ) {
          return {
            task,
            status: "parse_error",
            message: "响应 code/msg 类型不合法",
            records: [],
            rawResponse: payload,
            attempts,
          };
        }

        if (payload.code !== 0) {
          const message = payload.msg ?? `Tushare 错误码 ${payload.code}`;
          const status = classifyApiError(payload.code, message);
          if (status === "rate_limited" && attempts <= this.maxRetries) {
            await this.sleepFn(this.retryDelay(attempts));
            continue;
          }
          return {
            task,
            status,
            message,
            records: [],
            rawResponse: payload,
            attempts,
          };
        }

        try {
          const records = parseRecords(payload);
          if (task.cardinality === "one" && records.length > 1) {
            return {
              task,
              status: "ambiguous_data",
              message: `预期单条记录，但接口返回 ${records.length} 条；需要人工确认报告口径或修订版本`,
              records,
              rawResponse: payload,
              attempts,
            };
          }
          return {
            task,
            status: records.length === 0 ? "no_data" : "ok",
            message: records.length === 0 ? "接口返回空数据集" : null,
            records,
            rawResponse: payload,
            attempts,
          };
        } catch (error) {
          return {
            task,
            status: "parse_error",
            message: error instanceof Error ? error.message : "响应字段解析失败",
            records: [],
            rawResponse: payload,
            attempts,
          };
        }
      } catch (error) {
        lastNetworkMessage =
          error instanceof Error && error.name === "AbortError"
            ? `请求超过 ${this.timeoutMs}ms`
            : error instanceof Error
              ? error.message
              : "未知网络错误";
        if (attempts <= this.maxRetries) {
          await this.sleepFn(this.retryDelay(attempts));
          continue;
        }
      } finally {
        clearTimeout(timer);
      }
    }

    return {
      task,
      status: "network_error",
      message: lastNetworkMessage,
      records: [],
      rawResponse: null,
      attempts,
    };
  }
}
