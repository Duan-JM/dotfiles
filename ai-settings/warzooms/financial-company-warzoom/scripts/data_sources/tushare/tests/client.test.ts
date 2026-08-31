import assert from "node:assert/strict";
import test from "node:test";

import { TushareClient } from "../src/client.js";
import type { QueryTask } from "../src/types.js";

const TASK: QueryTask = {
  id: "stock_basic",
  apiName: "stock_basic",
  params: { ts_code: "600000.SH" },
  fields: "ts_code,name",
  sourceUrl: "https://tushare.pro/document/2",
  cardinality: "one",
};

test("把 fields/items 转换为对象记录", async () => {
  const client = new TushareClient({
    token: "test-token",
    fetchFn: async () =>
      new Response(
        JSON.stringify({
          code: 0,
          msg: null,
          data: {
            fields: ["ts_code", "name"],
            items: [["600000.SH", "浦发银行"]],
          },
        }),
        { status: 200 },
      ),
  });

  const result = await client.query(TASK);
  assert.equal(result.status, "ok");
  assert.deepEqual(result.records, [{ ts_code: "600000.SH", name: "浦发银行" }]);
});

test("空结果明确标记为 no_data", async () => {
  const client = new TushareClient({
    token: "test-token",
    fetchFn: async () =>
      new Response(
        JSON.stringify({
          code: 0,
          msg: null,
          data: { fields: ["ts_code"], items: [] },
        }),
        { status: 200 },
      ),
  });

  const result = await client.query(TASK);
  assert.equal(result.status, "no_data");
});

test("权限错误不会被当成空数据", async () => {
  const client = new TushareClient({
    token: "test-token",
    fetchFn: async () =>
      new Response(JSON.stringify({ code: 2002, msg: "没有接口权限" }), {
        status: 200,
      }),
  });

  const result = await client.query(TASK);
  assert.equal(result.status, "permission_denied");
  assert.equal(result.attempts, 1);
});

test("限流后按配置重试", async () => {
  let calls = 0;
  const client = new TushareClient({
    token: "test-token",
    maxRetries: 1,
    sleepFn: async () => undefined,
    fetchFn: async () => {
      calls += 1;
      if (calls === 1) {
        return new Response(JSON.stringify({ code: -1, msg: "每分钟访问频次超限" }), {
          status: 200,
        });
      }
      return new Response(
        JSON.stringify({
          code: 0,
          msg: null,
          data: { fields: ["ts_code"], items: [["600000.SH"]] },
        }),
        { status: 200 },
      );
    },
  });

  const result = await client.query(TASK);
  assert.equal(result.status, "ok");
  assert.equal(result.attempts, 2);
});

test("字段数量不一致时返回 parse_error", async () => {
  const client = new TushareClient({
    token: "test-token",
    fetchFn: async () =>
      new Response(
        JSON.stringify({
          code: 0,
          msg: null,
          data: { fields: ["ts_code", "name"], items: [["600000.SH"]] },
        }),
        { status: 200 },
      ),
  });

  const result = await client.query(TASK);
  assert.equal(result.status, "parse_error");
});

test("null 顶层响应返回 parse_error 且不重试", async () => {
  let calls = 0;
  const client = new TushareClient({
    token: "test-token",
    maxRetries: 2,
    fetchFn: async () => {
      calls += 1;
      return new Response("null", { status: 200 });
    },
  });

  const result = await client.query(TASK);
  assert.equal(result.status, "parse_error");
  assert.equal(calls, 1);
});

test("HTTP 认证和权限状态保持语义", async () => {
  for (const [httpStatus, expected] of [
    [400, "invalid_request"],
    [401, "authentication_failed"],
    [403, "permission_denied"],
  ] as const) {
    const client = new TushareClient({
      token: "test-token",
      fetchFn: async () => new Response("", { status: httpStatus }),
    });
    const result = await client.query(TASK);
    assert.equal(result.status, expected);
  }
});

test("官方频次错误文案会触发重试", async () => {
  let calls = 0;
  const client = new TushareClient({
    token: "test-token",
    maxRetries: 1,
    sleepFn: async () => undefined,
    randomFn: () => 0,
    fetchFn: async () => {
      calls += 1;
      if (calls === 1) {
        return new Response(
          JSON.stringify({
            code: -1,
            msg: "抱歉，您每分钟最多访问该接口50次，权限的具体详情访问...",
          }),
          { status: 200 },
        );
      }
      return new Response(
        JSON.stringify({
          code: 0,
          msg: null,
          data: { fields: ["ts_code"], items: [["600000.SH"]] },
        }),
        { status: 200 },
      );
    },
  });

  const result = await client.query(TASK);
  assert.equal(result.status, "ok");
  assert.equal(calls, 2);
});

test("重复字段和非标量值会被拒绝", async () => {
  for (const payload of [
    {
      code: 0,
      msg: null,
      data: { fields: ["name", "name"], items: [["A", "B"]] },
    },
    {
      code: 0,
      msg: null,
      data: { fields: ["value"], items: [[{ nested: true }]] },
    },
  ]) {
    const client = new TushareClient({
      token: "test-token",
      fetchFn: async () =>
        new Response(JSON.stringify(payload), { status: 200 }),
    });
    const result = await client.query(TASK);
    assert.equal(result.status, "parse_error");
  }
});

test("单记录接口返回多行时标记为 ambiguous_data", async () => {
  const client = new TushareClient({
    token: "test-token",
    fetchFn: async () =>
      new Response(
        JSON.stringify({
          code: 0,
          msg: null,
          data: {
            fields: ["ts_code"],
            items: [["600000.SH"], ["600000.SH"]],
          },
        }),
        { status: 200 },
      ),
  });

  const result = await client.query(TASK);
  assert.equal(result.status, "ambiguous_data");
  assert.equal(result.records.length, 2);
});

test("响应体读取中断按网络错误重试", async () => {
  let calls = 0;
  const client = new TushareClient({
    token: "test-token",
    maxRetries: 1,
    sleepFn: async () => undefined,
    fetchFn: async () => {
      calls += 1;
      if (calls === 1) {
        return new Response(
          new ReadableStream({
            start(controller) {
              controller.error(new Error("connection reset"));
            },
          }),
          { status: 200 },
        );
      }
      return new Response(
        JSON.stringify({
          code: 0,
          msg: null,
          data: { fields: ["ts_code"], items: [["600000.SH"]] },
        }),
        { status: 200 },
      );
    },
  });

  const result = await client.query(TASK);
  assert.equal(result.status, "ok");
  assert.equal(calls, 2);
});

test("流式响应超过字节上限立即拒绝", async () => {
  let pulls = 0;
  const client = new TushareClient({
    token: "test-token",
    maxResponseBytes: 10,
    fetchFn: async () =>
      new Response(
        new ReadableStream({
          pull(controller) {
            pulls += 1;
            controller.enqueue(new Uint8Array(8));
          },
        }),
        { status: 200 },
      ),
  });

  const result = await client.query(TASK);
  assert.equal(result.status, "parse_error");
  assert.match(result.message ?? "", /响应大小超过上限/);
  assert.ok(pulls <= 3, `响应流读取未及时停止，pull 次数为 ${pulls}`);
});

test("请求禁止跟随重定向", async () => {
  let redirect: RequestRedirect | undefined;
  const client = new TushareClient({
    token: "test-token",
    fetchFn: async (_input, init) => {
      redirect = init?.redirect;
      return new Response(
        JSON.stringify({
          code: 0,
          msg: null,
          data: { fields: ["ts_code"], items: [["600000.SH"]] },
        }),
        { status: 200 },
      );
    },
  });

  await client.query(TASK);
  assert.equal(redirect, "error");
});
