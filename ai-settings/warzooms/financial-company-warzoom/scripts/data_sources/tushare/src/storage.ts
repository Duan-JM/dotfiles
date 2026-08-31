import { createHash, randomUUID } from "node:crypto";
import {
  link,
  lstat,
  mkdir,
  open,
  readFile,
  realpath,
  unlink,
} from "node:fs/promises";
import path from "node:path";

import type {
  NormalizedQueryResult,
  QueryExecution,
  StoredArtifacts,
} from "./types.js";

export function sha256(value: string): string {
  return `sha256:${createHash("sha256").update(value, "utf8").digest("hex")}`;
}

function shortHash(value: string): string {
  return value.replace("sha256:", "").slice(0, 12);
}

function serialize(value: unknown): string {
  return `${JSON.stringify(value, null, 2)}\n`;
}

async function writeImmutable(filePath: string, content: string): Promise<void> {
  try {
    const metadata = await lstat(filePath);
    if (!metadata.isFile() || metadata.isSymbolicLink()) {
      throw new Error(`拒绝使用非普通文件：${filePath}`);
    }
    const current = await readFile(filePath, "utf8");
    if (current !== content) {
      throw new Error(`拒绝覆盖内容不同的历史文件：${filePath}`);
    }
    return;
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code !== "ENOENT") {
      throw error;
    }
  }

  const temporaryPath = `${filePath}.${process.pid}.${randomUUID()}.tmp`;
  let handle: Awaited<ReturnType<typeof open>> | null = null;
  try {
    handle = await open(temporaryPath, "wx");
    await handle.writeFile(content, "utf8");
    await handle.sync();
    await handle.close();
    handle = null;

    try {
      await link(temporaryPath, filePath);
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code !== "EEXIST") {
        throw error;
      }
      const metadata = await lstat(filePath);
      if (!metadata.isFile() || metadata.isSymbolicLink()) {
        throw new Error(`拒绝使用非普通文件：${filePath}`);
      }
      const current = await readFile(filePath, "utf8");
      if (current !== content) {
        throw new Error(`拒绝覆盖内容不同的历史文件：${filePath}`);
      }
    }
  } finally {
    if (handle !== null) {
      await handle.close().catch(() => undefined);
    }
    await unlink(temporaryPath).catch((error: NodeJS.ErrnoException) => {
      if (error.code !== "ENOENT") {
        throw error;
      }
    });
  }
}

function safePathSegment(value: string, label: string): string {
  if (!/^[A-Za-z0-9._-]+$/.test(value) || value === "." || value === "..") {
    throw new Error(`${label} 包含非法路径字符`);
  }
  return value;
}

async function ensureSafeDirectory(
  root: string,
  ...segments: string[]
): Promise<string> {
  await mkdir(root, { recursive: true });
  const rootMetadata = await lstat(root);
  if (!rootMetadata.isDirectory() || rootMetadata.isSymbolicLink()) {
    throw new Error(`拒绝使用符号链接或非目录输出根：${root}`);
  }
  const resolvedRoot = await realpath(root);
  let current = resolvedRoot;

  for (const segment of segments) {
    const candidate = path.join(current, segment);
    await mkdir(candidate).catch((error: NodeJS.ErrnoException) => {
      if (error.code !== "EEXIST") {
        throw error;
      }
    });
    const metadata = await lstat(candidate);
    if (!metadata.isDirectory() || metadata.isSymbolicLink()) {
      throw new Error(`拒绝使用符号链接或非目录路径：${candidate}`);
    }
    current = await realpath(candidate);
    if (
      current !== resolvedRoot &&
      !current.startsWith(`${resolvedRoot}${path.sep}`)
    ) {
      throw new Error("输出路径越出 outputRoot");
    }
  }

  return current;
}

export async function storeExecution(
  outputRoot: string,
  companyId: string,
  execution: QueryExecution,
  retrievedAt: string,
): Promise<StoredArtifacts> {
  const requestPayload = {
    api_name: execution.task.apiName,
    params: execution.task.params,
    fields: execution.task.fields,
  };
  const requestHash = sha256(JSON.stringify(requestPayload));
  const rawContent =
    execution.rawResponse === null ? null : serialize(execution.rawResponse);
  const responseHash = rawContent === null ? null : sha256(rawContent);
  const failureHash =
    rawContent === null
      ? sha256(
          JSON.stringify({
            status: execution.status,
            message: execution.message,
            attempts: execution.attempts,
          }),
        )
      : null;
  const baseName = [
    safePathSegment(execution.task.id, "task.id"),
    shortHash(requestHash),
    responseHash === null ? shortHash(failureHash ?? sha256(execution.status)) : shortHash(responseHash),
  ].join("-");
  const safeCompanyId = safePathSegment(companyId, "companyId");
  const safeApiName = safePathSegment(execution.task.apiName, "task.apiName");
  const targetDir = await ensureSafeDirectory(
    outputRoot,
    safeCompanyId,
    safeApiName,
  );

  let rawPath: string | null = null;
  if (rawContent !== null) {
    const targetRawPath = path.join(targetDir, `${baseName}.raw.json`);
    await writeImmutable(targetRawPath, rawContent);
    rawPath = targetRawPath;
  }

  const normalized: NormalizedQueryResult = {
    schema_version: 1,
    source: "tushare",
    request: {
      query_type: execution.task.apiName,
      company_id: companyId,
      params: execution.task.params,
      fields: execution.task.fields
        .split(",")
        .map((field) => field.trim())
        .filter(Boolean),
    },
    retrieved_at: retrievedAt,
    source_url: execution.task.sourceUrl,
    source_tier: "secondary",
    data_semantics: {
      currency: "CNY",
      unit_policy: "field_specific",
      accounting_basis: "provider_reported",
      period:
        typeof execution.task.params.period === "string"
          ? execution.task.params.period
          : null,
    },
    response_sha256: responseHash,
    status: execution.status,
    message: execution.message,
    attempts: execution.attempts,
    records: execution.records,
  };
  const normalizedPath = path.join(targetDir, `${baseName}.normalized.json`);
  try {
    await writeImmutable(normalizedPath, serialize(normalized));
  } catch (error) {
    if (
      error instanceof Error &&
      error.message.startsWith("拒绝覆盖内容不同的历史文件")
    ) {
      const existing = JSON.parse(await readFile(normalizedPath, "utf8")) as NormalizedQueryResult;
      if (
        existing.response_sha256 === normalized.response_sha256 &&
        existing.status === normalized.status
      ) {
        return { rawPath, normalizedPath };
      }
    }
    throw error;
  }

  return { rawPath, normalizedPath };
}

export async function storeRunSummary(
  outputRoot: string,
  companyId: string,
  retrievedAt: string,
  results: Array<{
    id: string;
    status: string;
    message: string | null;
    normalized_path: string | null;
    raw_path: string | null;
  }>,
): Promise<string> {
  const content = serialize({
    schema_version: 1,
    source: "tushare",
    company_id: companyId,
    retrieved_at: retrievedAt,
    results,
  });
  const summaryDir = await ensureSafeDirectory(
    outputRoot,
    safePathSegment(companyId, "companyId"),
    "runs",
  );
  const timestamp = retrievedAt.replace(/[:.]/g, "-");
  const filePath = path.join(summaryDir, `${timestamp}-${shortHash(sha256(content))}.json`);
  await writeImmutable(filePath, content);
  return filePath;
}
