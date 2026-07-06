#!/usr/bin/env python3
"""程序化证据 linter。

定位：
    审计闭环的 Step 1，输出**确定性**、低假阳率的违规线索，作为 LLM ``audit`` role
    的前置输入。**不**触发自动修复，**不**做最终违规裁决。

规则集：
    - ``E1``：句子或表格行内出现数字 + 单位（亿元 / 万人 / 倍 / `%` / 元 / ...），
      但同一句 / 同一表格行内未发现 ``SRC-XXX`` 引用。
    - ``E2``：正文出现的 ``SRC-XXX`` 引用未在 ``output/web_search_log.md`` 中登记。
    - ``C1``：扫描"据称 / 传闻 / 或将 / 据悉 / 应该会 / 业内人士"等弱来源用语。

白名单（不视为定量断言）：
    - 年份 / 月份 / 日 / 季度（``2024 年``、``Q3``、``2023H2``）
    - 章节 / 表号 / 图号 / 页码（``第 3 章``、``表 1``、``图 2-3``、``P12``）
    - 源 ID / 事实 ID（``SRC-001``、``F012``）
    - 股票代码（``002594.SZ``、``1211.HK``、``AAPL``）
    - 电话 / 邮编 / ISO 日期 / ISBN
    - 公司沿革年份（在公司沿革语境下，单独年份不触发 E1）

输出：
    ``output/audits/programmatic_check.json`` —— JSON 数组，每个章节一份汇总。

退出码：
    - ``0`` 总是；本脚本只产出诊断信息，是否中断流程由调用方决定。
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable

ROOT = Path(__file__).resolve().parents[1]
OUTPUT_DIR = ROOT / "output"
SECTIONS_DIR = OUTPUT_DIR / "sections"
SEARCH_LOG_FILE = OUTPUT_DIR / "web_search_log.md"
AUDITS_DIR = OUTPUT_DIR / "audits"
PROGRAMMATIC_CHECK_FILE = AUDITS_DIR / "programmatic_check.json"

# 数字 + 单位 / 后缀的核心模式：捕获定量断言。
# 注意：不匹配单独年份（4 位数 + "年"）和"第 X 章 / 第 X 条"等结构性数字。
_QUANTITATIVE_PATTERNS: tuple[re.Pattern[str], ...] = (
    # 数字 + 中文金额 / 单位词
    re.compile(
        r"\d[\d,，\.]*\s*"
        r"(?:亿元|万元|千元|百万元|亿美元|亿港元|亿欧元|"
        r"万人|千人|百万人|"
        r"万吨|千吨|百万吨|"
        r"万台|千台|万辆|千辆|万平方米|"
        r"倍|"
        r"个百分点)",
        re.UNICODE,
    ),
    # 百分比
    re.compile(r"\d[\d\.]*\s*%"),
    # 货币符号
    re.compile(r"[¥$€£]\s*\d[\d,，\.]*"),
    # 形如 "1,234.56 元 / 美元 / 港元"
    re.compile(r"\d[\d,，\.]+\s*(?:元|美元|港元|欧元|日元|英镑)"),
)

_SRC_REFERENCE = re.compile(r"SRC-(?:[A-Z]+-)?\d{3,4}", re.IGNORECASE)
_SRC_HEADING = re.compile(r"^##\s*(SRC-(?:[A-Z]+-)?\d{3,4})", re.IGNORECASE | re.MULTILINE)

_WEAK_SOURCE_PHRASES: tuple[str, ...] = (
    "据称",
    "传闻",
    "或将",
    "据悉",
    "应该会",
    "业内人士",
    "市场人士",
    "知情人士",
    "据传",
    "外界普遍认为",
)

# 白名单：以下模式即便被 _QUANTITATIVE_PATTERNS 命中也不算定量断言。
_WHITELIST_PATTERNS: tuple[re.Pattern[str], ...] = (
    re.compile(r"第\s*\d+\s*[章节条款项页]"),
    re.compile(r"表\s*\d+[-\d]*"),
    re.compile(r"图\s*\d+[-\d]*"),
    re.compile(r"[Pp]\.?\s*\d+"),
    re.compile(r"\bSRC-(?:[A-Z]+-)?\d{3,4}\b", re.IGNORECASE),
    re.compile(r"\bF(?:-[A-Z]+-)?\d{3,4}\b"),
    re.compile(r"\b\d{6}\.(?:SZ|SH|BJ)\b"),
    re.compile(r"\b\d{4,5}\.HK\b"),
    re.compile(r"\b[A-Z]{1,5}\b"),  # 美股代码
    re.compile(r"\b\d{4}-\d{2}-\d{2}\b"),  # ISO 日期
    re.compile(r"\b\d{4}\s*[年/-]\s*\d{1,2}\s*[月/-]"),  # 中文年月
    re.compile(r"\bQ[1-4]\b"),
    re.compile(r"\b\d{4}\s*[Hh][12]\b"),
)

_TABLE_ROW_PREFIX = re.compile(r"^\s*\|")
_CODE_FENCE = re.compile(r"^\s*```")
_CHAPTER_FILE_PATTERN = re.compile(r"^(\d{2})_[\w_]+\.md$")

_PROGRAMMATIC_RULE_E1 = "E1"
_PROGRAMMATIC_RULE_E2 = "E2"
_PROGRAMMATIC_RULE_C1 = "C1"

_SEVERITY_ERROR = "error"
_SEVERITY_WARNING = "warning"


@dataclass(frozen=True)
class Issue:
    """单条程序化检查发现。

    Args:
        rule: 规则码，取值 ``E1`` / ``E2`` / ``C1``。
        severity: 严重程度，取值 ``error`` / ``warning``。
        line: 1-based 行号。
        snippet: 命中的原文片段（最多 80 字符）。
        hint: 给 LLM 审计的提示。
    """

    rule: str
    severity: str
    line: int
    snippet: str
    hint: str


@dataclass(frozen=True)
class ChapterReport:
    """单章检查结果。

    Args:
        chapter: 章节文件 stem（如 ``03_financials``）。
        checked_at: ISO 时间戳。
        issues: 该章命中的所有 Issue。
    """

    chapter: str
    checked_at: str
    issues: tuple[Issue, ...]


def _read_text(path: Path) -> str:
    """读取文件内容；不存在则返回空字符串。

    Args:
        path: 目标文件路径。

    Returns:
        文件文本内容（UTF-8）；文件不存在时返回空字符串。

    Raises:
        OSError: 文件存在但读取失败时抛出。
    """

    if not path.exists():
        return ""
    return path.read_text(encoding="utf-8")


def _collect_registered_src_ids(search_log_text: str) -> frozenset[str]:
    """从证据库 markdown 中收集所有已登记的 ``SRC-XXX`` ID。

    Args:
        search_log_text: ``output/web_search_log.md`` 全文。

    Returns:
        已登记的 ``SRC-XXX`` 集合，全部大写归一化。

    Raises:
        无。
    """

    return frozenset(match.group(1).upper() for match in _SRC_HEADING.finditer(search_log_text))


def _strip_whitelisted_spans(text: str) -> str:
    """把白名单命中片段替换为空格，避免被 _QUANTITATIVE_PATTERNS 误识。

    Args:
        text: 原始行 / 句文本。

    Returns:
        移除白名单片段后的文本，长度不变（用空格占位）。

    Raises:
        无。
    """

    stripped = text
    for pattern in _WHITELIST_PATTERNS:
        stripped = pattern.sub(lambda m: " " * len(m.group(0)), stripped)
    return stripped


def _split_into_sentences(line: str) -> list[str]:
    """按中文标点把单行拆成"句子"。

    Args:
        line: 单行文本，已去除两端空白。

    Returns:
        子句列表，保留每一段含义最小化的判断单元。

    Raises:
        无。
    """

    pieces = re.split(r"[。！？；;]+", line)
    return [piece.strip() for piece in pieces if piece.strip()]


def _line_is_table_row(line: str) -> bool:
    """判断该行是否为 markdown 表格行。

    Args:
        line: 单行原始文本。

    Returns:
        ``True`` 表示该行是表格行（首字符为 ``|``）。

    Raises:
        无。
    """

    return bool(_TABLE_ROW_PREFIX.match(line))


def _segment_contains_quantitative_claim(segment: str) -> str | None:
    """判断 segment 是否包含定量断言；若包含返回首个命中的原文片段。

    Args:
        segment: 已去除白名单片段的子句 / 表格单元字符串。

    Returns:
        首个匹配到的定量片段；若不包含则返回 ``None``。

    Raises:
        无。
    """

    for pattern in _QUANTITATIVE_PATTERNS:
        match = pattern.search(segment)
        if match:
            return match.group(0)
    return None


def _truncate(text: str, *, limit: int = 80) -> str:
    """把字符串截断到给定字符数。

    Args:
        text: 原始字符串。
        limit: 最大保留字符数；超出部分以 ``…`` 标记。

    Returns:
        截断后的字符串。

    Raises:
        无。
    """

    if len(text) <= limit:
        return text
    return text[:limit] + "…"


def _is_inside_code_fence(state_open: bool, raw_line: str) -> bool:
    """根据当前 fenced code 状态与当前行更新 fence 状态。

    Args:
        state_open: 进入当前行前 fenced code 是否处于打开状态。
        raw_line: 当前行原文。

    Returns:
        进入下一行前 fenced code 的状态。

    Raises:
        无。
    """

    if _CODE_FENCE.match(raw_line):
        return not state_open
    return state_open


def _scan_e1_in_line(line: str, *, line_number: int) -> list[Issue]:
    """对单行扫描 E1（定量断言无 SRC 引用）。

    Args:
        line: 已去除右侧换行的原始行。
        line_number: 1-based 行号。

    Returns:
        该行命中的 E1 Issue 列表。

    Raises:
        无。
    """

    issues: list[Issue] = []
    if _line_is_table_row(line):
        # 表格行整行作为一个证据单元
        stripped_line = _strip_whitelisted_spans(line)
        quantitative_hit = _segment_contains_quantitative_claim(stripped_line)
        if quantitative_hit and not _SRC_REFERENCE.search(line):
            issues.append(
                Issue(
                    rule=_PROGRAMMATIC_RULE_E1,
                    severity=_SEVERITY_ERROR,
                    line=line_number,
                    snippet=_truncate(line.strip()),
                    hint=f"表格行内出现定量片段 ``{quantitative_hit}`` 但未发现 SRC-XXX 引用",
                )
            )
        return issues

    # 普通文本行：拆句后逐句检查
    for segment in _split_into_sentences(line):
        stripped_segment = _strip_whitelisted_spans(segment)
        quantitative_hit = _segment_contains_quantitative_claim(stripped_segment)
        if quantitative_hit and not _SRC_REFERENCE.search(segment):
            severity = (
                _SEVERITY_WARNING if "约" in segment or "左右" in segment or "上下" in segment else _SEVERITY_ERROR
            )
            issues.append(
                Issue(
                    rule=_PROGRAMMATIC_RULE_E1,
                    severity=severity,
                    line=line_number,
                    snippet=_truncate(segment),
                    hint=f"句内出现定量片段 ``{quantitative_hit}`` 但未发现 SRC-XXX 引用",
                )
            )
    return issues


def _scan_e2_in_line(line: str, *, line_number: int, registered: frozenset[str]) -> list[Issue]:
    """对单行扫描 E2（引用了未登记的 SRC-XXX）。

    Args:
        line: 已去除右侧换行的原始行。
        line_number: 1-based 行号。
        registered: ``web_search_log.md`` 中已登记的 SRC ID 集合。

    Returns:
        该行命中的 E2 Issue 列表。

    Raises:
        无。
    """

    issues: list[Issue] = []
    for match in _SRC_REFERENCE.finditer(line):
        src_id = match.group(0).upper()
        if src_id not in registered:
            issues.append(
                Issue(
                    rule=_PROGRAMMATIC_RULE_E2,
                    severity=_SEVERITY_ERROR,
                    line=line_number,
                    snippet=_truncate(line.strip()),
                    hint=f"引用了 {src_id}，但其未在 web_search_log.md 中以 ``## {src_id}`` 标题登记",
                )
            )
    return issues


def _scan_c1_in_line(line: str, *, line_number: int) -> list[Issue]:
    """对单行扫描 C1（弱来源 / 主观用语）。

    Args:
        line: 已去除右侧换行的原始行。
        line_number: 1-based 行号。

    Returns:
        该行命中的 C1 Issue 列表。

    Raises:
        无。
    """

    issues: list[Issue] = []
    for phrase in _WEAK_SOURCE_PHRASES:
        if phrase in line:
            issues.append(
                Issue(
                    rule=_PROGRAMMATIC_RULE_C1,
                    severity=_SEVERITY_WARNING,
                    line=line_number,
                    snippet=_truncate(line.strip()),
                    hint=f"命中弱来源 / 主观用语 ``{phrase}``，请确认是否改写或删除",
                )
            )
    return issues


def _scan_chapter(chapter_path: Path, *, registered: frozenset[str]) -> ChapterReport:
    """扫描单个章节文件，返回章节级检查报告。

    Args:
        chapter_path: 章节 markdown 路径。
        registered: 已登记 SRC 集合。

    Returns:
        ``ChapterReport`` 实例。

    Raises:
        OSError: 文件读取失败时抛出。
    """

    text = chapter_path.read_text(encoding="utf-8")
    issues: list[Issue] = []
    inside_code = False
    for line_number, raw_line in enumerate(text.splitlines(), start=1):
        # 维护 fenced code 状态，跳过代码块内行
        previously_inside = inside_code
        inside_code = _is_inside_code_fence(inside_code, raw_line)
        if previously_inside or inside_code and _CODE_FENCE.match(raw_line):
            continue
        line = raw_line.rstrip()
        if not line:
            continue
        issues.extend(_scan_e1_in_line(line, line_number=line_number))
        issues.extend(_scan_e2_in_line(line, line_number=line_number, registered=registered))
        issues.extend(_scan_c1_in_line(line, line_number=line_number))

    return ChapterReport(
        chapter=chapter_path.stem,
        checked_at=datetime.now(timezone.utc).isoformat(timespec="seconds"),
        issues=tuple(issues),
    )


def _iter_target_chapter_files(section_filter: str | None) -> Iterable[Path]:
    """枚举待检查的章节文件。

    Args:
        section_filter: 若提供，则只检查匹配的章节 stem 或文件名前缀（如 ``03`` 或
            ``03_financials``）；为 ``None`` 表示扫描 ``sections/`` 下所有章节。

    Yields:
        匹配条件的章节文件路径。

    Raises:
        无。
    """

    if not SECTIONS_DIR.exists():
        return
    for child in sorted(SECTIONS_DIR.iterdir()):
        if not child.is_file() or child.suffix != ".md":
            continue
        if not _CHAPTER_FILE_PATTERN.match(child.name):
            continue
        if section_filter is not None:
            if not child.stem.startswith(section_filter) and child.stem != section_filter:
                continue
        yield child


def _serialize_report(report: ChapterReport) -> dict[str, object]:
    """把单章报告序列化为 JSON 兼容字典。

    Args:
        report: 单章检查结果。

    Returns:
        JSON 兼容字典，保持 ``issues`` 顺序。

    Raises:
        无。
    """

    return {
        "chapter": report.chapter,
        "checked_at": report.checked_at,
        "issues": [asdict(issue) for issue in report.issues],
    }


def _write_aggregated_report(reports: list[ChapterReport]) -> Path:
    """把所有章节报告写入 ``output/audits/programmatic_check.json``。

    Args:
        reports: 多章节检查结果。

    Returns:
        写入的文件路径。

    Raises:
        OSError: 文件系统写入失败时抛出。
    """

    AUDITS_DIR.mkdir(parents=True, exist_ok=True)
    payload = {
        "version": "1.0",
        "generated_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "chapters": [_serialize_report(report) for report in reports],
    }
    PROGRAMMATIC_CHECK_FILE.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    return PROGRAMMATIC_CHECK_FILE


def _print_summary(reports: list[ChapterReport]) -> None:
    """把章节级 issue 计数打印到 stdout，便于 CI 与人工快速浏览。

    Args:
        reports: 检查结果列表。

    Returns:
        无。

    Raises:
        无。
    """

    if not reports:
        print("[check_evidence] 未发现可检查的章节文件。")
        return
    total_issues = 0
    for report in reports:
        error_count = sum(1 for issue in report.issues if issue.severity == _SEVERITY_ERROR)
        warning_count = sum(1 for issue in report.issues if issue.severity == _SEVERITY_WARNING)
        total_issues += len(report.issues)
        print(
            f"[check_evidence] {report.chapter}: "
            f"error={error_count}, warning={warning_count}, total={len(report.issues)}"
        )
    print(f"[check_evidence] 累计 {total_issues} 条线索；详见 {PROGRAMMATIC_CHECK_FILE.relative_to(ROOT)}")


def _parse_arguments(argv: list[str] | None) -> argparse.Namespace:
    """解析命令行参数。

    Args:
        argv: 可选的参数列表；默认读取 ``sys.argv``。

    Returns:
        ``argparse.Namespace`` 实例，包含 ``section`` 字段。

    Raises:
        SystemExit: 解析失败时由 argparse 抛出。
    """

    parser = argparse.ArgumentParser(
        description="程序化证据 linter：扫描 sections/*.md 输出 audits/programmatic_check.json"
    )
    parser.add_argument(
        "--section",
        type=str,
        default=None,
        help="只检查指定章节（章节 stem 或前缀，如 03 / 03_financials）；默认全部",
    )
    return parser.parse_args(argv)


def run(section_filter: str | None) -> int:
    """运行整条检查流水线。

    Args:
        section_filter: 章节过滤参数。

    Returns:
        进程退出码；当前实现总是返回 0（脚本只产出诊断信息）。

    Raises:
        OSError: 读写文件失败时由底层抛出。
    """

    registered = _collect_registered_src_ids(_read_text(SEARCH_LOG_FILE))
    reports = [_scan_chapter(path, registered=registered) for path in _iter_target_chapter_files(section_filter)]
    _write_aggregated_report(reports)
    _print_summary(reports)
    return 0


def main(argv: list[str] | None = None) -> int:
    """命令行入口。

    Args:
        argv: 可选的参数列表；默认读取 ``sys.argv``。

    Returns:
        进程退出码。

    Raises:
        无。
    """

    args = _parse_arguments(argv)
    return run(args.section)


if __name__ == "__main__":
    sys.exit(main())
