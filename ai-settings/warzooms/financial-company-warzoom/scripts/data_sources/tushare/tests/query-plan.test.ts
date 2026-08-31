import assert from "node:assert/strict";
import test from "node:test";

import {
  buildQueryPlan,
  subtractDays,
  validateDate,
  validateRequestBudget,
} from "../src/query-plan.js";

test("财务数据按报告期拆成独立查询", () => {
  const plan = buildQueryPlan({
    tsCode: "600000.SH",
    periods: ["20251231", "20241231"],
    asOf: "20260831",
    datasets: ["income", "daily_basic"],
  });

  assert.deepEqual(
    plan.map((task) => task.id),
    ["income-20251231", "income-20241231", "daily_basic-20260831"],
  );
  assert.deepEqual(plan[2]?.params, {
    ts_code: "600000.SH",
    start_date: "20260811",
    end_date: "20260831",
  });
});

test("财务接口缺少 periods 时拒绝运行", () => {
  assert.throws(
    () =>
      buildQueryPlan({
        tsCode: "600000.SH",
        periods: [],
        asOf: "20260831",
        datasets: ["cashflow"],
      }),
    /必须通过 --periods/,
  );
});

test("日期校验拒绝不存在的日期", () => {
  assert.throws(() => validateDate("20260230", "as_of"), /有效的 YYYYMMDD/);
});

test("日期回退跨月保持正确", () => {
  assert.equal(subtractDays("20260305", 20), "20260213");
});

test("报告期自动去重并限制数量", () => {
  const deduplicated = buildQueryPlan({
    tsCode: "600000.SH",
    periods: ["20251231", "20251231"],
    asOf: "20260831",
    datasets: ["income"],
  });
  assert.equal(deduplicated.length, 1);

  assert.throws(
    () =>
      buildQueryPlan({
        tsCode: "600000.SH",
        periods: Array.from(
          { length: 21 },
          (_, index) => `${2000 + index}1231`,
        ),
        asOf: "20260831",
        datasets: ["income"],
      }),
    /不能超过 20/,
  );
});

test("拒绝空数据集列表", () => {
  assert.throws(
    () =>
      buildQueryPlan({
        tsCode: "600000.SH",
        periods: [],
        asOf: "20260831",
        datasets: [],
      }),
    /至少需要指定一个数据集/,
  );
});

test("限制单次运行的最坏请求总量", () => {
  assert.doesNotThrow(() => validateRequestBudget(50, 3));
  assert.throws(() => validateRequestBudget(51, 3), /超过单次运行上限 200/);
});
