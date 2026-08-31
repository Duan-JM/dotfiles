import assert from "node:assert/strict";
import { mkdir, mkdtemp, readFile, rm, symlink } from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import test from "node:test";

import { storeExecution } from "../src/storage.js";
import type { QueryExecution } from "../src/types.js";

const EXECUTION: QueryExecution = {
  task: {
    id: "stock_basic",
    apiName: "stock_basic",
    params: { ts_code: "600000.SH" },
    fields: "ts_code,name",
    sourceUrl: "https://tushare.pro/document/2",
    cardinality: "one",
  },
  status: "ok",
  message: null,
  records: [{ ts_code: "600000.SH", name: "浦发银行" }],
  rawResponse: {
    code: 0,
    msg: null,
    data: {
      fields: ["ts_code", "name"],
      items: [["600000.SH", "浦发银行"]],
    },
  },
  attempts: 1,
};

test("相同请求和响应复用同一份不可变文件", async () => {
  const root = await mkdtemp(path.join(os.tmpdir(), "tushare-storage-"));
  try {
    const first = await storeExecution(
      root,
      "600000.SH",
      EXECUTION,
      "2026-08-31T00:00:00.000Z",
    );
    const second = await storeExecution(
      root,
      "600000.SH",
      EXECUTION,
      "2026-08-31T01:00:00.000Z",
    );

    assert.deepEqual(second, first);
    const normalized = JSON.parse(
      await readFile(first.normalizedPath, "utf8"),
    ) as { retrieved_at: string; response_sha256: string };
    assert.equal(normalized.retrieved_at, "2026-08-31T00:00:00.000Z");
    assert.match(normalized.response_sha256, /^sha256:[0-9a-f]{64}$/);
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

test("同一请求返回新内容时保留新旧两个版本", async () => {
  const root = await mkdtemp(path.join(os.tmpdir(), "tushare-storage-"));
  try {
    const first = await storeExecution(
      root,
      "600000.SH",
      EXECUTION,
      "2026-08-31T00:00:00.000Z",
    );
    const changed: QueryExecution = {
      ...EXECUTION,
      records: [{ ts_code: "600000.SH", name: "浦发银行股份有限公司" }],
      rawResponse: {
        code: 0,
        msg: null,
        data: {
          fields: ["ts_code", "name"],
          items: [["600000.SH", "浦发银行股份有限公司"]],
        },
      },
    };
    const second = await storeExecution(
      root,
      "600000.SH",
      changed,
      "2026-08-31T01:00:00.000Z",
    );

    assert.notEqual(second.rawPath, first.rawPath);
    assert.notEqual(second.normalizedPath, first.normalizedPath);
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

test("无 raw 响应的不同错误不会复用旧诊断", async () => {
  const root = await mkdtemp(path.join(os.tmpdir(), "tushare-storage-"));
  try {
    const timeout: QueryExecution = {
      ...EXECUTION,
      status: "network_error",
      message: "请求超时",
      records: [],
      rawResponse: null,
    };
    const dnsFailure: QueryExecution = {
      ...timeout,
      message: "DNS 查询失败",
    };
    const first = await storeExecution(
      root,
      "600000.SH",
      timeout,
      "2026-08-31T00:00:00.000Z",
    );
    const second = await storeExecution(
      root,
      "600000.SH",
      dnsFailure,
      "2026-08-31T01:00:00.000Z",
    );

    assert.notEqual(first.normalizedPath, second.normalizedPath);
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

test("并发写入相同响应保持幂等", async () => {
  const root = await mkdtemp(path.join(os.tmpdir(), "tushare-storage-"));
  try {
    const [first, second] = await Promise.all([
      storeExecution(
        root,
        "600000.SH",
        EXECUTION,
        "2026-08-31T00:00:00.000Z",
      ),
      storeExecution(
        root,
        "600000.SH",
        EXECUTION,
        "2026-08-31T00:00:00.000Z",
      ),
    ]);

    assert.deepEqual(first, second);
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

test("拒绝越出输出根目录的路径组件", async () => {
  const root = await mkdtemp(path.join(os.tmpdir(), "tushare-storage-"));
  try {
    await assert.rejects(
      storeExecution(
        root,
        "../outside",
        EXECUTION,
        "2026-08-31T00:00:00.000Z",
      ),
      /非法路径字符/,
    );
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

test("拒绝通过目录符号链接写出输出根目录", async () => {
  const root = await mkdtemp(path.join(os.tmpdir(), "tushare-storage-"));
  const outside = await mkdtemp(path.join(os.tmpdir(), "tushare-outside-"));
  try {
    await mkdir(path.join(root, "600000.SH"));
    await symlink(outside, path.join(root, "600000.SH", "stock_basic"));
    await assert.rejects(
      storeExecution(
        root,
        "600000.SH",
        EXECUTION,
        "2026-08-31T00:00:00.000Z",
      ),
      /拒绝使用符号链接/,
    );
  } finally {
    await rm(root, { recursive: true, force: true });
    await rm(outside, { recursive: true, force: true });
  }
});

test("拒绝符号链接形式的输出根目录", async () => {
  const parent = await mkdtemp(path.join(os.tmpdir(), "tushare-parent-"));
  const outside = await mkdtemp(path.join(os.tmpdir(), "tushare-outside-"));
  const linkedRoot = path.join(parent, "linked-root");
  try {
    await symlink(outside, linkedRoot);
    await assert.rejects(
      storeExecution(
        linkedRoot,
        "600000.SH",
        EXECUTION,
        "2026-08-31T00:00:00.000Z",
      ),
      /拒绝使用符号链接或非目录输出根/,
    );
  } finally {
    await rm(parent, { recursive: true, force: true });
    await rm(outside, { recursive: true, force: true });
  }
});
