#!/usr/bin/env python3
"""财报质量核查工具。

输入为 JSON，输出为 JSON；只使用 Python 标准库。脚本不会为缺失字段做静默估算，
所有无法计算的项目都会在 ``missing_fields`` 或 ``errors`` 中结构化列出。
"""

from __future__ import annotations

import argparse
import json
import math
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any

VERSION = "1.0"


class FinancialQualityInputError(ValueError):
    """输入 JSON 结构或字段类型不合法。"""

    def __init__(self, code: str, message: str) -> None:
        super().__init__(message)
        self.code = code
        self.message = message


@dataclass(frozen=True)
class MissingField:
    """单个核查项的缺失字段说明。"""

    check_id: str
    severity: str
    period: str
    missing: tuple[str, ...]
    accepted_alternatives: tuple[tuple[str, ...], ...]
    message: str


@dataclass(frozen=True)
class CheckResult:
    """单个财报质量核查项结果。"""

    check_id: str
    name: str
    status: str
    value: float | None
    unit: str | None
    method: str
    fields_used: tuple[str, ...]
    missing_fields: tuple[str, ...]
    thresholds: dict[str, str]
    interpretation: str


def _json_error(code: str, message: str) -> dict[str, Any]:
    """生成 JSON 错误输出。"""

    return {
        "version": VERSION,
        "grade": {"level": "D", "label": "可信度 D", "rationale": ["输入错误，无法完成核查"]},
        "checks": [],
        "missing_fields": [],
        "errors": [{"code": code, "message": message}],
    }


def _ensure_object(value: Any, *, label: str) -> dict[str, Any]:
    """校验对象类型。"""

    if not isinstance(value, dict):
        raise FinancialQualityInputError("INVALID_SCHEMA", f"{label} 必须是 JSON object")
    return value


def _ensure_periods(payload: dict[str, Any]) -> list[dict[str, Any]]:
    """读取并校验 periods 数组。"""

    periods = payload.get("periods")
    if not isinstance(periods, list) or not periods:
        raise FinancialQualityInputError("INVALID_SCHEMA", "periods 必须是非空 array")
    normalized: list[dict[str, Any]] = []
    for index, item in enumerate(periods):
        row = _ensure_object(item, label=f"periods[{index}]")
        period = row.get("period")
        if not isinstance(period, str) or not period.strip():
            raise FinancialQualityInputError("INVALID_SCHEMA", f"periods[{index}].period 必须是非空字符串")
        normalized.append(row)
    return normalized


def _period_label(row: dict[str, Any]) -> str:
    """返回期间标签。"""

    period = row.get("period")
    return str(period) if period is not None else "未知期间"


def _get_number(row: dict[str, Any], field: str) -> float | None:
    """读取数值字段；缺失返回 None，非数值抛错。"""

    if field not in row or row[field] is None:
        return None
    value = row[field]
    if isinstance(value, bool) or not isinstance(value, (int, float)) or not math.isfinite(float(value)):
        raise FinancialQualityInputError(
            "INVALID_FIELD_TYPE",
            f"{_period_label(row)} 的 {field} 必须是有限数字，不能用字符串、布尔值或空值代替",
        )
    return float(value)


def _round_or_none(value: float | None) -> float | None:
    """统一输出小数精度。"""

    if value is None:
        return None
    return round(value, 6)


def _missing(
    *,
    check_id: str,
    severity: str,
    period: str,
    missing: tuple[str, ...],
    accepted_alternatives: tuple[tuple[str, ...], ...],
    message: str,
) -> MissingField:
    """构造缺失字段记录。"""

    return MissingField(check_id, severity, period, missing, accepted_alternatives, message)


def _average_assets(current: dict[str, Any], previous: dict[str, Any] | None) -> tuple[float | None, tuple[str, ...], tuple[str, ...]]:
    """获取平均总资产，不用期末总资产静默替代。"""

    avg_assets = _get_number(current, "avg_total_assets")
    if avg_assets is not None:
        return avg_assets, ("avg_total_assets",), ()
    current_assets = _get_number(current, "total_assets")
    previous_assets = _get_number(previous, "total_assets") if previous is not None else None
    if current_assets is not None and previous_assets is not None:
        return (current_assets + previous_assets) / 2, ("total_assets", "previous.total_assets"), ()
    missing: list[str] = []
    if current_assets is None:
        missing.append("total_assets")
    if previous is None or previous_assets is None:
        missing.append("previous.total_assets")
    return None, (), tuple(missing)


def _check_accrual_ratio(
    current: dict[str, Any], previous: dict[str, Any] | None, missing_items: list[MissingField]
) -> CheckResult:
    """核查经营现金流代理的总应计比率。"""

    period = _period_label(current)
    net_income = _get_number(current, "net_income")
    cfo = _get_number(current, "operating_cash_flow")
    avg_assets, asset_fields, asset_missing = _average_assets(current, previous)
    missing_fields = tuple(
        field
        for field, value in (("net_income", net_income), ("operating_cash_flow", cfo))
        if value is None
    ) + asset_missing
    thresholds = {"低风险": "<= 5%", "关注": "5% 到 10%", "高风险": "> 10%"}
    if missing_fields:
        missing_items.append(
            _missing(
                check_id="accrual_ratio",
                severity="core",
                period=period,
                missing=missing_fields,
                accepted_alternatives=(
                    ("net_income", "operating_cash_flow", "avg_total_assets"),
                    ("net_income", "operating_cash_flow", "total_assets", "previous.total_assets"),
                ),
                message="无法计算总应计比率代理；不会用单期期末资产或收入静默替代平均资产",
            )
        )
        return CheckResult(
            "accrual_ratio",
            "总应计比率代理",
            "not_calculated",
            None,
            "ratio",
            "(净利润 - 经营现金流) / 平均总资产；这是现金流口径的总应计代理",
            tuple(field for field in ("net_income", "operating_cash_flow") + asset_fields if field),
            missing_fields,
            thresholds,
            "字段不足，无法判断利润含金量",
        )
    assert net_income is not None and cfo is not None and avg_assets is not None
    if avg_assets == 0:
        raise FinancialQualityInputError("ZERO_DENOMINATOR", f"{period} 平均总资产为 0，无法计算应计比率")
    value = (net_income - cfo) / abs(avg_assets)
    if value > 0.10:
        status = "high_risk"
        interpretation = "利润显著高于经营现金流，占资产比例偏高，应作为硬伤快筛候选"
    elif value > 0.05:
        status = "warning"
        interpretation = "利润现金含量偏弱，需要结合应收、存货和收入确认继续核验"
    else:
        status = "ok"
        interpretation = "按现金流代理口径，未见明显高应计压力"
    return CheckResult(
        "accrual_ratio",
        "总应计比率代理",
        status,
        value,
        "ratio",
        "(净利润 - 经营现金流) / 平均总资产；这是现金流口径的总应计代理",
        ("net_income", "operating_cash_flow") + asset_fields,
        (),
        thresholds,
        interpretation,
    )


def _check_cash_conversion(current: dict[str, Any], missing_items: list[MissingField]) -> CheckResult:
    """核查经营现金流 / 净利润现金转化。"""

    period = _period_label(current)
    net_income = _get_number(current, "net_income")
    cfo = _get_number(current, "operating_cash_flow")
    missing_fields = tuple(
        field
        for field, value in (("net_income", net_income), ("operating_cash_flow", cfo))
        if value is None
    )
    thresholds = {"低风险": ">= 0.8", "关注": "0.5 到 0.8", "高风险": "< 0.5 或为负"}
    if missing_fields:
        missing_items.append(
            _missing(
                check_id="cash_conversion",
                severity="core",
                period=period,
                missing=missing_fields,
                accepted_alternatives=(("net_income", "operating_cash_flow"),),
                message="无法计算经营现金流 / 净利润现金转化",
            )
        )
        return CheckResult(
            "cash_conversion",
            "经营现金流 / 净利润现金转化",
            "not_calculated",
            None,
            "ratio",
            "经营现金流 / 净利润",
            tuple(field for field in ("net_income", "operating_cash_flow") if field not in missing_fields),
            missing_fields,
            thresholds,
            "字段不足，无法判断净利润现金转化",
        )
    assert net_income is not None and cfo is not None
    if net_income == 0:
        raise FinancialQualityInputError("ZERO_DENOMINATOR", f"{period} 净利润为 0，无法计算现金转化率")
    value = cfo / net_income
    if value < 0.5:
        status = "high_risk"
        interpretation = "经营现金流对净利润覆盖不足，若连续出现需纳入粗读硬伤"
    elif value < 0.8:
        status = "warning"
        interpretation = "现金转化偏弱，需要核验应收、合同资产、存货和一次性项目"
    else:
        status = "ok"
        interpretation = "经营现金流对净利润覆盖较好"
    return CheckResult(
        "cash_conversion",
        "经营现金流 / 净利润现金转化",
        status,
        value,
        "ratio",
        "经营现金流 / 净利润",
        ("operating_cash_flow", "net_income"),
        (),
        thresholds,
        interpretation,
    )


def _derive_dso(row: dict[str, Any], *, prefix: str) -> tuple[float | None, tuple[str, ...], tuple[str, ...]]:
    """读取或计算 DSO；计算时必须显式提供 days_in_period。"""

    dso = _get_number(row, "dso")
    if dso is not None:
        return dso, (f"{prefix}dso",), ()
    receivable = _get_number(row, "accounts_receivable")
    revenue = _get_number(row, "revenue")
    days = _get_number(row, "days_in_period")
    if receivable is not None and revenue is not None and days is not None:
        if revenue == 0:
            raise FinancialQualityInputError("ZERO_DENOMINATOR", f"{_period_label(row)} revenue 为 0，无法计算 DSO")
        return receivable / revenue * days, (
            f"{prefix}accounts_receivable",
            f"{prefix}revenue",
            f"{prefix}days_in_period",
        ), ()
    missing = tuple(
        field
        for field, value in (("dso", dso), ("accounts_receivable", receivable), ("revenue", revenue), ("days_in_period", days))
        if value is None
    )
    return None, (), tuple(f"{prefix}{field}" for field in missing)


def _revenue_growth(current: dict[str, Any], previous: dict[str, Any] | None) -> tuple[float | None, tuple[str, ...], tuple[str, ...]]:
    """读取或计算收入增速。"""

    explicit = _get_number(current, "revenue_growth")
    if explicit is not None:
        return explicit, ("revenue_growth",), ()
    current_revenue = _get_number(current, "revenue")
    previous_revenue = _get_number(previous, "revenue") if previous is not None else None
    if current_revenue is not None and previous_revenue is not None:
        if previous_revenue == 0:
            raise FinancialQualityInputError("ZERO_DENOMINATOR", "上一期 revenue 为 0，无法计算收入增速")
        return (current_revenue - previous_revenue) / abs(previous_revenue), ("revenue", "previous.revenue"), ()
    missing: list[str] = []
    if current_revenue is None:
        missing.append("revenue")
    if previous is None or previous_revenue is None:
        missing.append("previous.revenue")
    return None, (), tuple(missing)


def _check_dso_divergence(
    current: dict[str, Any], previous: dict[str, Any] | None, missing_items: list[MissingField]
) -> CheckResult:
    """核查 DSO 与收入增长背离。"""

    period = _period_label(current)
    thresholds = {
        "低风险": "DSO 增幅未明显快于收入增速",
        "关注": "DSO 增加超过 10 天且快于收入增速 20 个百分点以上",
        "高风险": "收入下滑或低增长时 DSO 增加超过 15 天",
    }
    if previous is None:
        missing_items.append(
            _missing(
                check_id="dso_revenue_divergence",
                severity="optional",
                period=period,
                missing=("previous period",),
                accepted_alternatives=(("dso", "previous.dso", "revenue_growth"),),
                message="缺少上一期数据，DSO / 收入增长背离核查跳过",
            )
        )
        return CheckResult(
            "dso_revenue_divergence",
            "DSO / 收入增长背离",
            "not_calculated",
            None,
            "days",
            "比较本期与上期 DSO 变化，并与收入增速交叉验证",
            (),
            ("previous period",),
            thresholds,
            "字段不存在时按可选项跳过，但已结构化记录缺口",
        )
    dso_current, dso_current_fields, dso_current_missing = _derive_dso(current, prefix="")
    dso_previous, dso_previous_fields, dso_previous_missing = _derive_dso(previous, prefix="previous.")
    growth, growth_fields, growth_missing = _revenue_growth(current, previous)
    missing_fields = dso_current_missing + dso_previous_missing + growth_missing
    if missing_fields:
        missing_items.append(
            _missing(
                check_id="dso_revenue_divergence",
                severity="optional",
                period=period,
                missing=missing_fields,
                accepted_alternatives=(
                    ("dso", "previous.dso", "revenue_growth"),
                    ("accounts_receivable", "revenue", "days_in_period", "previous.accounts_receivable", "previous.revenue", "previous.days_in_period"),
                ),
                message="字段不足，未执行 DSO / 收入增长背离核查；不会假设 365 天或自行估算收入增速",
            )
        )
        return CheckResult(
            "dso_revenue_divergence",
            "DSO / 收入增长背离",
            "not_calculated",
            None,
            "days",
            "比较本期与上期 DSO 变化，并与收入增速交叉验证",
            dso_current_fields + dso_previous_fields + growth_fields,
            missing_fields,
            thresholds,
            "字段不存在时按可选项跳过，但已结构化记录缺口",
        )
    assert dso_current is not None and dso_previous is not None and growth is not None
    dso_change = dso_current - dso_previous
    dso_growth = dso_change / abs(dso_previous) if dso_previous else None
    if dso_change > 15 and growth < 0.05:
        status = "high_risk"
        interpretation = "收入低增长或下滑时 DSO 明显拉长，可能存在回款质量或收入确认压力"
    elif dso_change > 10 and dso_growth is not None and dso_growth - growth > 0.20:
        status = "warning"
        interpretation = "DSO 增速明显快于收入增速，需要核验信用政策、渠道压货或应收质量"
    else:
        status = "ok"
        interpretation = "未见 DSO 相对收入增长的明显背离"
    return CheckResult(
        "dso_revenue_divergence",
        "DSO / 收入增长背离",
        status,
        dso_change,
        "days",
        "DSO 变化天数 = 本期 DSO - 上期 DSO；收入增速来自显式字段或 revenue 同比",
        dso_current_fields + dso_previous_fields + growth_fields,
        (),
        thresholds,
        interpretation + f"；收入增速={growth:.2%}",
    )


def _grade(checks: list[CheckResult], missing_items: list[MissingField]) -> dict[str, Any]:
    """汇总 A/B/C/D 可信度分级。"""

    core = [check for check in checks if check.check_id in {"accrual_ratio", "cash_conversion"}]
    calculated_core = [check for check in core if check.status != "not_calculated"]
    high_count = sum(1 for check in checks if check.status == "high_risk")
    warning_count = sum(1 for check in checks if check.status == "warning")
    core_missing = any(item.severity == "core" for item in missing_items)
    optional_missing = any(item.severity == "optional" for item in missing_items)
    rationale: list[str] = []

    if len(calculated_core) == 0:
        level = "D"
        rationale.append("两个核心现金质量核查项均无法计算")
    elif high_count >= 2:
        level = "D"
        rationale.append("多个高风险财报质量信号同时命中")
    elif high_count == 1:
        level = "C"
        rationale.append("存在一个高风险财报质量信号")
    elif core_missing:
        level = "C"
        rationale.append("至少一个核心核查项缺字段，不能给出高可信结论")
    elif warning_count >= 2:
        level = "C"
        rationale.append("多个关注项同时出现")
    elif warning_count == 1 or optional_missing:
        level = "B"
        if warning_count == 1:
            rationale.append("存在一个需复核的关注项")
        if optional_missing:
            rationale.append("DSO / 收入背离等可选字段不足，数据完整性未达 A")
    else:
        level = "A"
        rationale.append("核心现金质量与回款背离核查均未见异常")

    labels = {
        "A": "可信度 A：现金质量与字段完整性较好",
        "B": "可信度 B：核心结论可用但仍有关注项或可选缺口",
        "C": "可信度 C：存在高风险信号或核心字段缺口",
        "D": "可信度 D：无法可信使用或存在多个高风险信号",
    }
    return {"level": level, "label": labels[level], "rationale": rationale}


def _asdict_check(check: CheckResult) -> dict[str, Any]:
    """序列化核查项。"""

    return {
        "id": check.check_id,
        "name": check.name,
        "status": check.status,
        "value": _round_or_none(check.value),
        "unit": check.unit,
        "method": check.method,
        "fields_used": list(check.fields_used),
        "missing_fields": list(check.missing_fields),
        "thresholds": check.thresholds,
        "interpretation": check.interpretation,
    }


def _asdict_missing(item: MissingField) -> dict[str, Any]:
    """序列化缺失字段说明。"""

    return {
        "check_id": item.check_id,
        "severity": item.severity,
        "period": item.period,
        "missing": list(item.missing),
        "accepted_alternatives": [list(group) for group in item.accepted_alternatives],
        "message": item.message,
    }


def evaluate(payload: dict[str, Any]) -> dict[str, Any]:
    """执行财报质量核查。"""

    _ensure_object(payload, label="根输入")
    periods = _ensure_periods(payload)
    current = periods[-1]
    previous = periods[-2] if len(periods) >= 2 else None
    missing_items: list[MissingField] = []
    checks = [
        _check_accrual_ratio(current, previous, missing_items),
        _check_cash_conversion(current, missing_items),
        _check_dso_divergence(current, previous, missing_items),
    ]
    return {
        "version": VERSION,
        "company": payload.get("company"),
        "period": _period_label(current),
        "currency": payload.get("currency"),
        "unit": payload.get("unit"),
        "grade": _grade(checks, missing_items),
        "checks": [_asdict_check(check) for check in checks],
        "missing_fields": [_asdict_missing(item) for item in missing_items],
        "errors": [],
    }


def _read_json(path_value: str) -> dict[str, Any]:
    """从文件或 stdin 读取 JSON。"""

    try:
        text = sys.stdin.read() if path_value == "-" else Path(path_value).read_text(encoding="utf-8")
        payload = json.loads(text)
    except FileNotFoundError as exc:
        raise FinancialQualityInputError("INPUT_NOT_FOUND", f"输入文件不存在：{exc.filename}") from exc
    except json.JSONDecodeError as exc:
        raise FinancialQualityInputError("INVALID_JSON", f"输入不是合法 JSON：line {exc.lineno}, column {exc.colno}") from exc
    return _ensure_object(payload, label="根输入")


def _write_json(payload: dict[str, Any], path_value: str) -> None:
    """写出 JSON 到文件或 stdout。"""

    text = json.dumps(payload, ensure_ascii=False, indent=2) + "\n"
    if path_value == "-":
        sys.stdout.write(text)
    else:
        Path(path_value).write_text(text, encoding="utf-8")


def _parse_args(argv: list[str] | None) -> argparse.Namespace:
    """解析命令行参数。"""

    parser = argparse.ArgumentParser(description="财报质量核查：JSON 输入，JSON 输出，仅使用标准库")
    parser.add_argument("--input", "-i", default="-", help="输入 JSON 文件；默认从 stdin 读取")
    parser.add_argument("--output", "-o", default="-", help="输出 JSON 文件；默认写到 stdout")
    return parser.parse_args(argv)


def run(argv: list[str] | None = None) -> int:
    """命令行运行入口。"""

    args = _parse_args(argv)
    try:
        result = evaluate(_read_json(args.input))
        _write_json(result, args.output)
        return 0
    except FinancialQualityInputError as exc:
        _write_json(_json_error(exc.code, exc.message), args.output)
        return 2
    except OSError as exc:
        _write_json(_json_error("IO_ERROR", f"文件读写失败：{exc}"), args.output)
        return 2


def main() -> int:
    """脚本入口。"""

    return run()


if __name__ == "__main__":
    sys.exit(main())
