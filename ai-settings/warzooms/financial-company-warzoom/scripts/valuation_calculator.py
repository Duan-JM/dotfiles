#!/usr/bin/env python3
"""粗读优先的估值计算器。

脚本只使用标准库，输入 / 输出均为 JSON。它只做确定性计算，不补数、不联网、不读取
output 生成物；缺少字段时返回 ``unavailable`` 与缺失项，非法输入则拒绝并返回错误。
"""

from __future__ import annotations

import argparse
import json
import math
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any


Number = int | float


class ValuationInputError(ValueError):
    """输入字段存在无法安全计算的非法值。"""


@dataclass(frozen=True)
class MetricSpec:
    """单个指标的输出元信息。"""

    name: str
    label: str
    formula: str
    unit: str


METRIC_SPECS: dict[str, MetricSpec] = {
    "market_cap": MetricSpec("market_cap", "市值", "price × shares_outstanding；或直接采用 market_cap", "输入币种·输入单位"),
    "enterprise_value": MetricSpec(
        "enterprise_value",
        "企业价值 EV",
        "市值 + 总债务 + 优先股 + 少数股东权益 - 现金及等价物 - 短期投资",
        "输入币种·输入单位",
    ),
    "pb": MetricSpec("pb", "P/B", "市值 / 归母或合并口径账面股东权益", "倍"),
    "ev_ebit": MetricSpec("ev_ebit", "EV/EBIT", "EV / EBIT", "倍"),
    "ev_ebitda": MetricSpec("ev_ebitda", "EV/EBITDA", "EV / EBITDA", "倍"),
    "fcf_yield": MetricSpec("fcf_yield", "FCF yield", "自由现金流 / 市值", "比例"),
    "net_shareholder_return": MetricSpec(
        "net_shareholder_return",
        "净股东回报率",
        "(现金分红 + 净回购 - 股权激励 SBC - 增发摊薄) / 市值",
        "比例",
    ),
    "net_debt": MetricSpec(
        "net_debt",
        "净现金 / 净负债",
        "总债务 + 优先股 + 少数股东权益 - 现金及等价物 - 短期投资",
        "输入币种·输入单位",
    ),
}


def _metric_available(spec: MetricSpec, value: float, *, inputs: list[str], extra: dict[str, Any] | None = None) -> dict[str, Any]:
    """构造可用指标输出。"""

    payload: dict[str, Any] = {
        "status": "available",
        "label": spec.label,
        "value": value,
        "unit": spec.unit,
        "formula": spec.formula,
        "inputs": inputs,
    }
    if extra:
        payload.update(extra)
    return payload


def _metric_unavailable(
    spec: MetricSpec,
    *,
    missing: list[str] | None = None,
    reason: str,
    inputs: list[str] | None = None,
) -> dict[str, Any]:
    """构造缺失 / 不适用指标输出。"""

    return {
        "status": "unavailable",
        "label": spec.label,
        "value": None,
        "unit": spec.unit,
        "formula": spec.formula,
        "missing": missing or [],
        "inputs": inputs or [],
        "reason": reason,
    }


def _get_number(payload: dict[str, Any], key: str) -> float | None:
    """读取可选数字字段；缺失返回 None，非数字拒绝。"""

    if key not in payload or payload[key] is None:
        return None
    value = payload[key]
    if isinstance(value, bool) or not isinstance(value, (int, float)) or not math.isfinite(value):
        raise ValuationInputError(f"{key} 必须是有限数字")
    return float(value)


def _get_number_with_default(payload: dict[str, Any], key: str, default: float, *, label: str | None = None) -> float:
    """读取带默认值的数字字段；仅字段缺失时使用默认值。"""

    if key not in payload:
        return default
    value = payload[key]
    field = label or key
    if value is None or isinstance(value, bool) or not isinstance(value, (int, float)) or not math.isfinite(value):
        raise ValuationInputError(f"{field} 必须是有限数字")
    return float(value)


def _require_positive(payload: dict[str, Any], key: str) -> float | None:
    """读取可选正数字段；字段存在但非正时拒绝。"""

    value = _get_number(payload, key)
    if value is not None and value <= 0:
        raise ValuationInputError(f"{key} 必须大于 0")
    return value


def _require_non_negative(payload: dict[str, Any], key: str) -> float | None:
    """读取可选非负数字段；字段存在但小于 0 时拒绝。"""

    value = _get_number(payload, key)
    if value is not None and value < 0:
        raise ValuationInputError(f"{key} 不能为负数")
    return value


def _optional_zero(payload: dict[str, Any], key: str) -> float:
    """读取可选非负字段，缺失按 0 处理仅用于 EV / 净债务的附加项。"""

    return _require_non_negative(payload, key) or 0.0


def _get_non_negative_alias(payload: dict[str, Any], canonical: str, aliases: tuple[str, ...] = ()) -> tuple[float | None, str]:
    """按主字段与别名读取非负字段，返回值与实际使用的字段名。"""

    for key in (canonical, *aliases):
        if key in payload:
            return _require_non_negative(payload, key), key
    return None, canonical


def _safe_ratio(spec: MetricSpec, numerator: float | None, denominator: float | None, *, missing: list[str], inputs: list[str]) -> dict[str, Any]:
    """计算需要正分母的比率。"""

    if numerator is None or denominator is None:
        return _metric_unavailable(spec, missing=missing, reason="缺少计算所需字段", inputs=inputs)
    if denominator <= 0:
        return _metric_unavailable(spec, reason="分母为非正值，指标不适用", inputs=inputs)
    return _metric_available(spec, numerator / denominator, inputs=inputs)


def _compute_market_cap(payload: dict[str, Any]) -> tuple[dict[str, Any], float | None]:
    """计算市值，优先采用直接输入，其次采用股价乘股本。"""

    spec = METRIC_SPECS["market_cap"]
    direct = _require_positive(payload, "market_cap")
    if direct is not None:
        return _metric_available(spec, direct, inputs=["market_cap"], extra={"source": "direct"}), direct
    price = _require_positive(payload, "price")
    shares = _require_positive(payload, "shares_outstanding")
    missing = [key for key, value in (("price", price), ("shares_outstanding", shares)) if value is None]
    if missing:
        return (
            _metric_unavailable(spec, missing=missing, reason="缺少 market_cap，且无法由 price × shares_outstanding 推导", inputs=[]),
            None,
        )
    assert price is not None and shares is not None
    return _metric_available(spec, price * shares, inputs=["price", "shares_outstanding"], extra={"source": "price_times_shares"}), price * shares


def _compute_net_debt(payload: dict[str, Any]) -> tuple[dict[str, Any], float | None]:
    """计算净债务；负值表示净现金。"""

    spec = METRIC_SPECS["net_debt"]
    debt = _require_non_negative(payload, "total_debt")
    cash = _require_non_negative(payload, "cash_and_equivalents")
    missing = [key for key, value in (("total_debt", debt), ("cash_and_equivalents", cash)) if value is None]
    inputs = ["total_debt", "cash_and_equivalents"]
    if missing:
        return _metric_unavailable(spec, missing=missing, reason="缺少总债务或现金，无法判断净现金 / 净负债", inputs=inputs), None
    preferred = _optional_zero(payload, "preferred_equity")
    minority = _optional_zero(payload, "minority_interest")
    short_investments = _optional_zero(payload, "short_term_investments")
    value = debt + preferred + minority - cash - short_investments  # type: ignore[operator]
    classification = "净负债" if value > 0 else "净现金" if value < 0 else "净现金 / 净负债为零"
    return (
        _metric_available(
            spec,
            value,
            inputs=inputs + ["preferred_equity", "minority_interest", "short_term_investments"],
            extra={"classification": classification},
        ),
        value,
    )


def _compute_enterprise_value(market_cap: float | None, net_debt: float | None) -> tuple[dict[str, Any], float | None]:
    """计算 EV。"""

    spec = METRIC_SPECS["enterprise_value"]
    if market_cap is None or net_debt is None:
        missing = []
        if market_cap is None:
            missing.append("market_cap 或 price + shares_outstanding")
        if net_debt is None:
            missing.extend(["total_debt", "cash_and_equivalents"])
        return _metric_unavailable(spec, missing=missing, reason="缺少市值或净债务口径", inputs=[]), None
    return _metric_available(spec, market_cap + net_debt, inputs=["market_cap", "net_debt"]), market_cap + net_debt


def _compute_reverse_dcf(payload: dict[str, Any], *, market_cap: float | None, net_debt: float | None) -> dict[str, Any] | None:
    """可选反向 DCF：求解隐含 FCF 年复合增长率。"""

    config = payload.get("reverse_dcf")
    if config in (None, False):
        return None
    if not isinstance(config, dict):
        raise ValuationInputError("reverse_dcf 必须是 JSON object")

    wacc = _require_positive(config, "wacc")
    terminal_g = _get_number(config, "terminal_g")
    if wacc is None or terminal_g is None:
        return {"status": "unavailable", "missing": [k for k, v in (("wacc", wacc), ("terminal_g", terminal_g)) if v is None], "reason": "缺少 WACC 或永续增长率"}
    if wacc <= terminal_g:
        raise ValuationInputError("reverse_dcf.wacc 必须大于 reverse_dcf.terminal_g")
    if terminal_g <= -1:
        raise ValuationInputError("reverse_dcf.terminal_g 必须大于 -100%")

    years_raw = config.get("projection_years", 5)
    if isinstance(years_raw, bool) or not isinstance(years_raw, int) or years_raw <= 0:
        raise ValuationInputError("reverse_dcf.projection_years 必须是正整数")
    fcf = _require_positive(config, "free_cash_flow")
    if fcf is None:
        fcf = _require_positive(payload, "free_cash_flow")
    target_ev = _require_positive(config, "enterprise_value")
    if target_ev is None and market_cap is not None and net_debt is not None:
        target_ev = market_cap + net_debt
    missing = []
    if fcf is None:
        missing.append("reverse_dcf.free_cash_flow 或 free_cash_flow")
    if target_ev is None:
        missing.append("reverse_dcf.enterprise_value 或可计算 EV")
    if missing:
        return {"status": "unavailable", "missing": missing, "reason": "缺少反向 DCF 所需字段"}

    low = _get_number_with_default(config, "growth_low", -0.9, label="reverse_dcf.growth_low")
    high = _get_number_with_default(config, "growth_high", 1.0, label="reverse_dcf.growth_high")
    if not math.isfinite(low) or not math.isfinite(high) or low <= -1 or low >= high:
        raise ValuationInputError("reverse_dcf.growth_low/growth_high 区间非法")

    def pv_at_growth(growth: float) -> float:
        total = 0.0
        current_fcf = fcf  # type: ignore[assignment]
        for year in range(1, years_raw + 1):
            current_fcf *= 1 + growth
            total += current_fcf / ((1 + wacc) ** year)
        terminal_value = current_fcf * (1 + terminal_g) / (wacc - terminal_g)
        return total + terminal_value / ((1 + wacc) ** years_raw)

    low_pv = pv_at_growth(low)
    high_pv = pv_at_growth(high)
    if not (low_pv <= target_ev <= high_pv):  # type: ignore[operator]
        return {
            "status": "unavailable",
            "missing": [],
            "reason": "给定增长率搜索区间无法覆盖当前 EV；请调整 growth_low/growth_high 或复核输入",
            "pv_at_growth_low": low_pv,
            "pv_at_growth_high": high_pv,
            "target_enterprise_value": target_ev,
        }
    for _ in range(80):
        mid = (low + high) / 2
        if pv_at_growth(mid) < target_ev:  # type: ignore[operator]
            low = mid
        else:
            high = mid
    required_growth = (low + high) / 2
    return {
        "status": "available",
        "label": "反向 DCF 隐含 FCF 年复合增长率",
        "required_fcf_cagr": required_growth,
        "projection_years": years_raw,
        "wacc": wacc,
        "terminal_g": terminal_g,
        "target_enterprise_value": target_ev,
        "formula": "用当前 EV 反解未来 N 年 FCF CAGR，并以第 N 年 FCF × (1+terminal_g)/(WACC-terminal_g) 计算终值",
    }


def calculate_valuation(payload: dict[str, Any]) -> dict[str, Any]:
    """执行估值计算并返回 JSON 可序列化对象。"""

    if not isinstance(payload, dict):
        raise ValuationInputError("输入顶层必须是 JSON object")

    market_cap_metric, market_cap = _compute_market_cap(payload)
    net_debt_metric, net_debt = _compute_net_debt(payload)
    ev_metric, ev = _compute_enterprise_value(market_cap, net_debt)

    book_equity = _get_number(payload, "book_equity")
    ebit = _get_number(payload, "ebit")
    ebitda = _get_number(payload, "ebitda")
    free_cash_flow = _get_number(payload, "free_cash_flow")

    metrics: dict[str, Any] = {
        "market_cap": market_cap_metric,
        "enterprise_value": ev_metric,
        "pb": _safe_ratio(METRIC_SPECS["pb"], market_cap, book_equity, missing=[key for key, value in (("market_cap", market_cap), ("book_equity", book_equity)) if value is None], inputs=["market_cap", "book_equity"]),
        "ev_ebit": _safe_ratio(METRIC_SPECS["ev_ebit"], ev, ebit, missing=[key for key, value in (("enterprise_value", ev), ("ebit", ebit)) if value is None], inputs=["enterprise_value", "ebit"]),
        "ev_ebitda": _safe_ratio(METRIC_SPECS["ev_ebitda"], ev, ebitda, missing=[key for key, value in (("enterprise_value", ev), ("ebitda", ebitda)) if value is None], inputs=["enterprise_value", "ebitda"]),
        "fcf_yield": _safe_ratio(METRIC_SPECS["fcf_yield"], free_cash_flow, market_cap, missing=[key for key, value in (("free_cash_flow", free_cash_flow), ("market_cap", market_cap)) if value is None], inputs=["free_cash_flow", "market_cap"]),
        "net_debt": net_debt_metric,
    }

    shareholder_fields = ("dividends", "buybacks", "sbc", "issuance_dilution")
    dividends, dividends_key = _get_non_negative_alias(payload, "dividends")
    buybacks, buybacks_key = _get_non_negative_alias(payload, "buybacks", ("net_buybacks",))
    sbc, sbc_key = _get_non_negative_alias(payload, "sbc")
    issuance_dilution, issuance_key = _get_non_negative_alias(payload, "issuance_dilution")
    shareholder_values = {
        "dividends": dividends,
        "buybacks": buybacks,
        "sbc": sbc,
        "issuance_dilution": issuance_dilution,
    }
    used_shareholder_fields = [dividends_key, buybacks_key, sbc_key, issuance_key]
    shareholder_missing = [key for key, value in shareholder_values.items() if value is None]
    if market_cap is None:
        shareholder_missing.append("market_cap 或 price + shares_outstanding")
    if shareholder_missing:
        metrics["net_shareholder_return"] = _metric_unavailable(
            METRIC_SPECS["net_shareholder_return"],
            missing=shareholder_missing,
            reason="缺少现金分红、净回购、SBC、增发摊薄或市值字段；0 值也需显式输入",
            inputs=used_shareholder_fields + ["market_cap"],
        )
    else:
        numerator = (
            dividends
            + buybacks
            - sbc
            - issuance_dilution
        )
        metrics["net_shareholder_return"] = _metric_available(
            METRIC_SPECS["net_shareholder_return"],
            numerator / market_cap,  # type: ignore[operator]
            inputs=used_shareholder_fields + ["market_cap"],
            extra={"numerator": numerator},
        )

    result: dict[str, Any] = {
        "status": "ok",
        "schema_version": "1.0",
        "meta": {
            "currency": payload.get("currency", "未指定"),
            "unit": payload.get("unit", "未指定"),
            "accounting_basis": payload.get("accounting_basis", "未指定"),
            "as_of": payload.get("as_of", "未指定"),
        },
        "metrics": metrics,
        "notes": [
            "所有金额字段必须使用同一币种、同一单位与同一会计口径；脚本不做币种或单位换算。",
            "缺失字段返回 unavailable，不自动估算；0 值如果代表真实披露值必须显式输入。",
            "本计算器服务 rough 粗读闸门，不构成投资建议，也不替代审计闭环。",
        ],
    }
    reverse_dcf = _compute_reverse_dcf(payload, market_cap=market_cap, net_debt=net_debt)
    if reverse_dcf is not None:
        result["reverse_dcf"] = reverse_dcf
    return result


def _read_json(path: str | None) -> dict[str, Any]:
    """从文件或 stdin 读取 JSON。"""

    text = Path(path).read_text(encoding="utf-8") if path else sys.stdin.read()
    try:
        payload = json.loads(text)
    except json.JSONDecodeError as exc:
        raise ValuationInputError(f"输入不是合法 JSON：line {exc.lineno}, column {exc.colno}") from exc
    if not isinstance(payload, dict):
        raise ValuationInputError("输入顶层必须是 JSON object")
    return payload


def run(argv: list[str] | None = None) -> int:
    """命令行入口；成功输出计算结果，失败输出错误 JSON。"""

    parser = argparse.ArgumentParser(description="粗读优先估值计算器（JSON 输入 / JSON 输出）")
    parser.add_argument("--input", "-i", help="输入 JSON 文件；省略时从 stdin 读取")
    parser.add_argument("--output", "-o", help="输出 JSON 文件；省略时写入 stdout")
    parser.add_argument("--pretty", action="store_true", help="缩进输出，便于阅读")
    args = parser.parse_args(argv)

    try:
        result = calculate_valuation(_read_json(args.input))
        exit_code = 0
    except ValuationInputError as exc:
        result = {"status": "error", "error": {"type": "invalid_input", "message": str(exc)}}
        exit_code = 1

    rendered = json.dumps(result, ensure_ascii=False, indent=2 if args.pretty else None, sort_keys=True)
    if args.output:
        Path(args.output).write_text(rendered + "\n", encoding="utf-8")
    else:
        print(rendered)
    return exit_code


if __name__ == "__main__":
    sys.exit(run())
