#!/usr/bin/env python3
"""把 audits/*.json 聚合成 markdown 附录。

定位：
    最终合并报告时，把审计中间产物压缩成一份 markdown 附录写入 ``output/research_report.md``，
    供读者快速理解"这份报告经历了哪些审计、有哪些已知缺口"。

输入：
    - ``output/audits/programmatic_check.json``
    - ``output/audits/<chapter>.audit.json``（多份）
    - ``output/audits/<chapter>.confirm.json``（可选）
    - ``output/audits/final_consistency.audit.json``（可选）

输出：
    ``output/audits/audit_summary.md`` — 由 ``merge.py`` 自动附加到最终报告附录 B。
"""

from __future__ import annotations

import json
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable

ROOT = Path(__file__).resolve().parents[1]
AUDITS_DIR = ROOT / "output" / "audits"
PROGRAMMATIC_CHECK_FILE = AUDITS_DIR / "programmatic_check.json"
FINAL_AUDIT_FILE = AUDITS_DIR / "final_consistency.audit.json"
AUDIT_SUMMARY_FILE = AUDITS_DIR / "audit_summary.md"

_AUDIT_SUFFIX = ".audit.json"
_CONFIRM_SUFFIX = ".confirm.json"


@dataclass(frozen=True)
class ChapterAuditFile:
    """单章审计产物。

    Args:
        chapter: 章节 stem。
        audit_path: 单章 audit JSON 路径；可能不存在。
        confirm_path: 单章 confirm JSON 路径；可能不存在。
    """

    chapter: str
    audit_path: Path
    confirm_path: Path


def _read_json(path: Path) -> dict[str, Any] | None:
    """读取 JSON 文件；不存在或解析失败时返回 ``None``。

    Args:
        path: 目标 JSON 文件路径。

    Returns:
        解析后的字典；文件不存在或解析失败返回 ``None``。

    Raises:
        无。
    """

    if not path.exists():
        return None
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return None


def _collect_chapter_audit_files() -> list[ChapterAuditFile]:
    """枚举 audits/ 下所有章节级审计文件。

    Args:
        无。

    Returns:
        按章节 stem 排序的 ``ChapterAuditFile`` 列表。

    Raises:
        无。
    """

    if not AUDITS_DIR.exists():
        return []
    chapters: dict[str, ChapterAuditFile] = {}
    for child in sorted(AUDITS_DIR.iterdir()):
        if not child.is_file() or not child.name.endswith(_AUDIT_SUFFIX):
            continue
        if child.name in {PROGRAMMATIC_CHECK_FILE.name, FINAL_AUDIT_FILE.name}:
            continue
        chapter = child.name[: -len(_AUDIT_SUFFIX)]
        if chapter in chapters:
            continue
        confirm_path = AUDITS_DIR / f"{chapter}{_CONFIRM_SUFFIX}"
        chapters[chapter] = ChapterAuditFile(chapter=chapter, audit_path=child, confirm_path=confirm_path)
    return sorted(chapters.values(), key=lambda entry: entry.chapter)


def _render_programmatic_section() -> str:
    """渲染程序化检查段。

    Args:
        无。

    Returns:
        markdown 段落字符串；无数据时返回提示。

    Raises:
        无。
    """

    payload = _read_json(PROGRAMMATIC_CHECK_FILE)
    if payload is None:
        return "## B.1 程序化检查\n\n- 未运行 `scripts/check_evidence.py`。\n"
    lines: list[str] = ["## B.1 程序化检查\n"]
    lines.append(f"- 生成时间：{payload.get('generated_at', '未知')}")
    chapters = payload.get("chapters", [])
    if not chapters:
        lines.append("- 未发现可检查的章节文件。\n")
        return "\n".join(lines) + "\n"
    lines.append("")
    lines.append("| 章节 | error | warning | 合计 |")
    lines.append("| --- | ---: | ---: | ---: |")
    for chapter in chapters:
        issues = chapter.get("issues", [])
        error_count = sum(1 for issue in issues if issue.get("severity") == "error")
        warning_count = sum(1 for issue in issues if issue.get("severity") == "warning")
        lines.append(
            f"| `{chapter.get('chapter', '?')}` | {error_count} | {warning_count} | {len(issues)} |"
        )
    return "\n".join(lines) + "\n"


def _render_chapter_audit_entry(entry: ChapterAuditFile) -> str:
    """渲染单章 audit / confirm 摘要。

    Args:
        entry: 单章审计产物路径。

    Returns:
        该章节的 markdown 段落。

    Raises:
        无。
    """

    audit_payload = _read_json(entry.audit_path)
    if audit_payload is None:
        return f"### {entry.chapter}\n\n- audit JSON 缺失或解析失败：`{entry.audit_path.name}`\n"
    lines: list[str] = [f"### {entry.chapter}\n"]
    lines.append(f"- audit 文件：`{entry.audit_path.relative_to(ROOT)}`")
    category = audit_payload.get("category", "unknown")
    violations: list[dict[str, Any]] = audit_payload.get("violations", []) or []
    lines.append(f"- 审计结论：`{category}`；违规条目 {len(violations)} 条")
    if violations:
        lines.append("")
        lines.append("| 序号 | 规则 | 严重度 | 建议动作 | 摘要 |")
        lines.append("| ---: | --- | --- | --- | --- |")
        for index, violation in enumerate(violations):
            snippet = str(violation.get("claim_quote", "")).replace("|", "\\|").replace("\n", " ")
            if len(snippet) > 80:
                snippet = snippet[:80] + "…"
            lines.append(
                f"| {index} | {violation.get('rule', '?')} | "
                f"{violation.get('severity', '?')} | "
                f"{violation.get('suggested_action', '?')} | {snippet} |"
            )

    confirm_payload = _read_json(entry.confirm_path)
    if confirm_payload is not None:
        results = confirm_payload.get("results", []) or []
        lines.append("")
        lines.append(f"- confirm 文件：`{entry.confirm_path.relative_to(ROOT)}`；复核 {len(results)} 条")
        if results:
            lines.append("")
            lines.append("| 违规序号 | 复核结论 | SRC | 说明 |")
            lines.append("| ---: | --- | --- | --- |")
            for result in results:
                reason = str(result.get("reason", "")).replace("|", "\\|").replace("\n", " ")
                if len(reason) > 80:
                    reason = reason[:80] + "…"
                lines.append(
                    f"| {result.get('violation_index', '?')} | "
                    f"{result.get('status', '?')} | "
                    f"{result.get('src_id', '-')} | {reason} |"
                )
    return "\n".join(lines) + "\n"


def _render_chapter_audits_section(entries: list[ChapterAuditFile]) -> str:
    """渲染所有章节 audit/confirm 段。

    Args:
        entries: 章节级审计文件列表。

    Returns:
        markdown 段落字符串。

    Raises:
        无。
    """

    if not entries:
        return "## B.2 章节审计\n\n- 未发现任何章节 audit JSON。\n"
    parts: list[str] = ["## B.2 章节审计\n"]
    for entry in entries:
        parts.append(_render_chapter_audit_entry(entry))
    return "\n".join(parts)


def _render_final_audit_section() -> str:
    """渲染最终一致性审计段。

    Args:
        无。

    Returns:
        markdown 段落字符串；无数据时返回提示。

    Raises:
        无。
    """

    payload = _read_json(FINAL_AUDIT_FILE)
    if payload is None:
        return "## B.3 最终一致性审计\n\n- 未生成 `final_consistency.audit.json`。\n"
    lines: list[str] = ["## B.3 最终一致性审计\n"]
    lines.append(f"- 检查时间：{payload.get('checked_at', '未知')}")
    category = payload.get("category", "unknown")
    violations: list[dict[str, Any]] = payload.get("violations", []) or []
    lines.append(f"- 审计结论：`{category}`；违规条目 {len(violations)} 条")
    if violations:
        lines.append("")
        lines.append("| 规则 | 严重度 | 涉及章节 | 摘要 |")
        lines.append("| --- | --- | --- | --- |")
        for violation in violations:
            chapters_field = violation.get("chapters", [])
            chapters_str = ", ".join(str(item) for item in chapters_field) if chapters_field else "-"
            snippet = str(violation.get("claim_quote", "")).replace("|", "\\|").replace("\n", " ")
            if len(snippet) > 80:
                snippet = snippet[:80] + "…"
            lines.append(
                f"| {violation.get('rule', '?')} | {violation.get('severity', '?')} | {chapters_str} | {snippet} |"
            )
    return "\n".join(lines) + "\n"


def _render_header() -> str:
    """渲染附录抬头。

    Args:
        无。

    Returns:
        附录抬头字符串。

    Raises:
        无。
    """

    now = datetime.now(timezone.utc).isoformat(timespec="seconds")
    return (
        "# 附录 B · 审计闭环结果摘要\n\n"
        f"> 生成时间：{now}\n"
        "> 本附录由 `scripts/audit_summary.py` 自动汇总 `output/audits/` 下的中间产物。\n"
        "> 详细 JSON 请直接查看 `output/audits/` 目录。\n"
    )


def build_summary() -> str:
    """构建完整附录字符串。

    Args:
        无。

    Returns:
        完整附录 markdown。

    Raises:
        无。
    """

    sections: Iterable[str] = (
        _render_header(),
        _render_programmatic_section(),
        _render_chapter_audits_section(_collect_chapter_audit_files()),
        _render_final_audit_section(),
    )
    return "\n".join(section.rstrip() + "\n" for section in sections)


def _has_any_audit_input() -> bool:
    """判定是否存在任何可聚合的审计输入。

    Args:
        无。

    Returns:
        ``True`` 表示 ``programmatic_check.json`` / 任一章节 audit / final audit 至少存在一份。

    Raises:
        无。
    """

    if PROGRAMMATIC_CHECK_FILE.exists():
        return True
    if FINAL_AUDIT_FILE.exists():
        return True
    if _collect_chapter_audit_files():
        return True
    return False


def run() -> int:
    """执行聚合并落盘。

    Args:
        无。

    Returns:
        进程退出码（始终为 0）。

    Raises:
        OSError: 文件写入失败时由底层抛出。
    """

    AUDITS_DIR.mkdir(parents=True, exist_ok=True)
    if not _has_any_audit_input():
        # 无任何审计输入则不生成附录，避免 merge 阶段出现"未生成"的占位附录
        if AUDIT_SUMMARY_FILE.exists():
            AUDIT_SUMMARY_FILE.unlink()
        print("[audit_summary] 未发现任何审计输入，跳过附录生成")
        return 0
    summary = build_summary()
    AUDIT_SUMMARY_FILE.write_text(summary, encoding="utf-8")
    print(f"[audit_summary] 已写入 {AUDIT_SUMMARY_FILE.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(run())
