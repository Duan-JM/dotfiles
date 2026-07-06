#!/usr/bin/env python3
"""把 ``roles/<role>.md`` 的 Prompt 段渲染成可派发给子代理的完整 prompt。

定位：
    审计闭环的每个 role（infer / audit / confirm / repair / regenerate / final_audit）
    都以 ``roles/<role>.md`` 中的占位符模板形式存储。本脚本负责从工作区文件读出实际
    内容，按 role 的占位符约定填充，并把结果打印到 stdout——主代理（无论 Copilot CLI、
    Claude Code、Codex 还是裸主代理）拿到完整 prompt 后即可派发。

典型用法（Copilot CLI 主代理）::

    python3 scripts/render_role.py audit --chapter 03_financials
        → stdout 即可作为 task 工具的 `prompt` 参数

退出码：
    0 正常；2 输入文件缺失；3 角色文件结构异常。
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Callable

ROOT = Path(__file__).resolve().parents[1]
ROLES_DIR = ROOT / "roles"
SECTIONS_DIR = ROOT / "output" / "sections"
AUDITS_DIR = ROOT / "output" / "audits"
TEMPLATE_FILE = ROOT / "templates" / "report_template.md"

INPUT_COMPANY = ROOT / "input" / "company.md"
INPUT_EXTRA_DIR = ROOT / "input" / "extra_sources"
WEB_SEARCH_LOG = ROOT / "output" / "web_search_log.md"
FACTS_FILE = ROOT / "output" / "facts.md"
COMPANY_FACETS = ROOT / "output" / "company_facets.md"
PROGRAMMATIC_CHECK = AUDITS_DIR / "programmatic_check.json"

EMPTY_PLACEHOLDER = "（暂无）"


def _read_text(path: Path, *, allow_missing: bool = False) -> str:
    """读取文本文件。缺失时按 ``allow_missing`` 处理。

    Args:
        path: 文件路径。
        allow_missing: True 时缺失返回 ``EMPTY_PLACEHOLDER``，False 时抛错。

    Returns:
        文件内容字符串（去掉首尾空白）；缺失且 allow_missing=True 时返回占位字符串。

    Raises:
        FileNotFoundError: 当 allow_missing=False 且文件不存在。
    """

    if not path.exists():
        if allow_missing:
            return EMPTY_PLACEHOLDER
        raise FileNotFoundError(f"必需输入文件不存在：{path}")
    return path.read_text(encoding="utf-8").strip()


def _read_extra_sources() -> str:
    """读取 input/extra_sources/ 下所有 .md 文件并拼接。

    Returns:
        所有 .md 文件内容按文件名拼接后的字符串；目录不存在或为空时返回占位。

    Raises:
        无。
    """

    if not INPUT_EXTRA_DIR.exists():
        return EMPTY_PLACEHOLDER
    parts: list[str] = []
    for md_file in sorted(INPUT_EXTRA_DIR.glob("*.md")):
        parts.append(f"### {md_file.name}\n\n{md_file.read_text(encoding='utf-8').strip()}")
    return "\n\n".join(parts) if parts else EMPTY_PLACEHOLDER


def _read_web_search_summary() -> str:
    """提取 web_search_log.md 中每个 SRC 条目的关键字段摘要。

    用于 audit role，避免一次塞入完整正文。提取规则：
    每个以 ``## SRC-`` 开头的小节抽出该小节中的「- 标题：xxx」、「- 来源 / 发布机构：xxx」、
    「- 来源类型：xxx」与「- 关键摘录：」字段。关键摘录取紧邻的非空首行（去掉首部的
    ``> `` 引用标记或 ``-`` 列表标记）；任一字段缺失则在该 SRC 行中省略，整段保留 header
    与匹配到的字段。

    Returns:
        markdown 字符串；文件不存在时返回占位字符串。

    Raises:
        无。
    """

    if not WEB_SEARCH_LOG.exists():
        return EMPTY_PLACEHOLDER
    raw = WEB_SEARCH_LOG.read_text(encoding="utf-8")
    blocks = re.split(r"\n(?=##\s+SRC-)", raw)
    summary_lines: list[str] = []
    for block in blocks:
        if not block.lstrip().startswith("## SRC-"):
            continue
        header_match = re.search(r"##\s+(SRC-\S+)", block)
        if not header_match:
            continue
        src_id = header_match.group(1)
        title_match = re.search(r"-\s*标题[:：]\s*(.+)", block)
        source_match = re.search(r"-\s*(?:来源|发布机构|发布方|出处)[:：]\s*(.+)", block)
        type_match = re.search(r"-\s*来源类型[:：]\s*(.+)", block)
        excerpt_match = re.search(
            r"-\s*关键摘录[:：]\s*\n((?:[ \t]*[>\-][^\n]*\n?)+)",
            block,
        )
        line = f"- {src_id}"
        if title_match:
            line += f" | 标题：{title_match.group(1).strip()}"
        if source_match:
            line += f" | 发布机构：{source_match.group(1).strip()}"
        if type_match:
            line += f" | 来源类型：{type_match.group(1).strip()}"
        if excerpt_match:
            excerpt_raw = excerpt_match.group(1)
            first_line = next(
                (
                    re.sub(r"^[ \t]*[>\-]\s?", "", piece).strip()
                    for piece in excerpt_raw.splitlines()
                    if re.sub(r"^[ \t]*[>\-]\s?", "", piece).strip()
                ),
                "",
            )
            if first_line:
                truncated = first_line if len(first_line) <= 80 else first_line[:77] + "..."
                line += f" | 摘录：{truncated}"
        summary_lines.append(line)
    if not summary_lines:
        return EMPTY_PLACEHOLDER
    return "\n".join(summary_lines)


def _read_programmatic_check(chapter_id: str) -> str:
    """提取 programmatic_check.json 中 chapter==chapter_id 的部分。

    Args:
        chapter_id: 章节 stem。

    Returns:
        JSON 文本（pretty 打印）；未跑过程序化检查时返回占位字符串。

    Raises:
        无。
    """

    if not PROGRAMMATIC_CHECK.exists():
        return EMPTY_PLACEHOLDER
    try:
        payload = json.loads(PROGRAMMATIC_CHECK.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return EMPTY_PLACEHOLDER
    for chapter in payload.get("chapters", []):
        if chapter.get("chapter") == chapter_id:
            return json.dumps(chapter, ensure_ascii=False, indent=2)
    return EMPTY_PLACEHOLDER


def _read_audit_violations(chapter_id: str, *, only_evidence: bool = False) -> str:
    """读取单章 audit JSON 中 violations 数组。

    Args:
        chapter_id: 章节 stem。
        only_evidence: 仅保留 E1/E2/E3 条目（供 confirm 用）。

    Returns:
        JSON 文本（pretty）；缺失时返回占位字符串。

    Raises:
        无。
    """

    audit_file = AUDITS_DIR / f"{chapter_id}.audit.json"
    if not audit_file.exists():
        return EMPTY_PLACEHOLDER
    try:
        payload = json.loads(audit_file.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return EMPTY_PLACEHOLDER
    violations = payload.get("violations", []) or []
    if only_evidence:
        violations = [v for v in violations if str(v.get("rule", "")).startswith("E")]
    return json.dumps(violations, ensure_ascii=False, indent=2)


def _read_confirm_results(chapter_id: str) -> str:
    """读取单章 confirm JSON 中 results 数组。

    Args:
        chapter_id: 章节 stem。

    Returns:
        JSON 文本（pretty）；缺失时返回占位字符串。

    Raises:
        无。
    """

    confirm_file = AUDITS_DIR / f"{chapter_id}.confirm.json"
    if not confirm_file.exists():
        return EMPTY_PLACEHOLDER
    try:
        payload = json.loads(confirm_file.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return EMPTY_PLACEHOLDER
    return json.dumps(payload.get("results", []) or [], ensure_ascii=False, indent=2)


def _read_chapter_prompt(chapter_id: str) -> str:
    """从 templates/report_template.md 中提取对应章节的 prompt 块。

    Args:
        chapter_id: 章节 stem（如 ``03_financials``）；脚本会按章节编号匹配
            ``---CHAPTER_03_PROMPT---`` 到 ``---END---`` 之间的内容。

    Returns:
        匹配到的 prompt 文本；未找到时返回占位字符串。

    Raises:
        无。
    """

    if not TEMPLATE_FILE.exists():
        return EMPTY_PLACEHOLDER
    match = re.match(r"^(\d{2})_", chapter_id)
    if not match:
        return EMPTY_PLACEHOLDER
    chapter_num = match.group(1)
    raw = TEMPLATE_FILE.read_text(encoding="utf-8")
    pattern = rf"---CHAPTER_{chapter_num}_PROMPT---\s*\n(.*?)\n---END---"
    block = re.search(pattern, raw, re.DOTALL)
    if not block:
        return EMPTY_PLACEHOLDER
    return block.group(1).strip()


def _read_merged_draft() -> str:
    """按文件名升序拼接 output/sections/*.md（不含附录）。

    Returns:
        所有章节文本（章节之间用 ``\\n\\n---\\n\\n`` 分隔）；目录为空时返回占位字符串。

    Raises:
        无。
    """

    if not SECTIONS_DIR.exists():
        return EMPTY_PLACEHOLDER
    parts: list[str] = []
    for md_file in sorted(SECTIONS_DIR.glob("*.md")):
        if md_file.name == ".gitkeep":
            continue
        parts.append(md_file.read_text(encoding="utf-8").strip())
    return "\n\n---\n\n".join(parts) if parts else EMPTY_PLACEHOLDER


def _extract_prompt_section(role_file: Path) -> str:
    """从 role 文件中抽出 ``## Prompt`` 段。

    Args:
        role_file: 角色 .md 文件路径。

    Returns:
        Prompt 段正文。

    Raises:
        SystemExit: role 文件不存在或缺少 ``## Prompt`` 段。
    """

    if not role_file.exists():
        sys.exit(f"[render_role] 角色文件不存在：{role_file}")
    raw = role_file.read_text(encoding="utf-8")
    match = re.search(r"\n##\s+Prompt\s*\n(.*)$", raw, re.DOTALL)
    if not match:
        sys.exit(f"[render_role] 角色文件缺少 `## Prompt` 段：{role_file}")
    return match.group(1).strip()


def _substitute(template: str, mapping: dict[str, str]) -> str:
    """把 ``{key}`` 占位符替换为 mapping 中对应文本，最多迭代 5 轮以处理嵌套占位符。

    Args:
        template: 含 ``{key}`` 的模板字符串。
        mapping: 占位符到替换值的字典。

    Returns:
        替换后的字符串；未在 mapping 中的占位符保持原样。

    Raises:
        无。
    """

    def repl(match: re.Match[str]) -> str:
        key = match.group(1)
        return mapping.get(key, match.group(0))

    pattern = re.compile(r"\{([a-zA-Z_][a-zA-Z0-9_]*)\}")
    current = template
    for _ in range(5):
        rendered = pattern.sub(repl, current)
        if rendered == current:
            break
        current = rendered
    return current


def _build_infer_mapping() -> dict[str, str]:
    """构建 infer role 的占位符填充表。

    Returns:
        占位符到内容字符串的映射。

    Raises:
        FileNotFoundError: input/company.md 缺失。
    """

    return {
        "company_meta": _read_text(INPUT_COMPANY, allow_missing=False),
        "extra_sources": _read_extra_sources(),
        "web_search_log": _read_text(WEB_SEARCH_LOG, allow_missing=True),
        "facts": _read_text(FACTS_FILE, allow_missing=True),
    }


def _build_audit_mapping(chapter_id: str) -> dict[str, str]:
    """构建 audit role 的占位符填充表。

    Args:
        chapter_id: 章节 stem。

    Returns:
        占位符到内容字符串的映射。

    Raises:
        FileNotFoundError: 当前章节文件缺失。
    """

    chapter_file = SECTIONS_DIR / f"{chapter_id}.md"
    return {
        "chapter_id": chapter_id,
        "chapter_markdown": _read_text(chapter_file, allow_missing=False),
        "company_facets": _read_text(COMPANY_FACETS, allow_missing=True),
        "web_search_log": _read_web_search_summary(),
        "facts": _read_text(FACTS_FILE, allow_missing=True),
        "programmatic_check": _read_programmatic_check(chapter_id),
    }


def _build_confirm_mapping(chapter_id: str) -> dict[str, str]:
    """构建 confirm role 的占位符填充表。

    Args:
        chapter_id: 章节 stem。

    Returns:
        占位符到内容字符串的映射。

    Raises:
        FileNotFoundError: 当前章节文件缺失。
    """

    chapter_file = SECTIONS_DIR / f"{chapter_id}.md"
    return {
        "chapter_id": chapter_id,
        "chapter_markdown": _read_text(chapter_file, allow_missing=False),
        "audit_violations": _read_audit_violations(chapter_id, only_evidence=True),
        "web_search_log": _read_text(WEB_SEARCH_LOG, allow_missing=True),
        "facts": _read_text(FACTS_FILE, allow_missing=True),
    }


def _build_repair_mapping(chapter_id: str) -> dict[str, str]:
    """构建 repair role 的占位符填充表。

    Args:
        chapter_id: 章节 stem。

    Returns:
        占位符到内容字符串的映射。

    Raises:
        FileNotFoundError: 当前章节文件缺失。
    """

    chapter_file = SECTIONS_DIR / f"{chapter_id}.md"
    return {
        "chapter_id": chapter_id,
        "chapter_markdown": _read_text(chapter_file, allow_missing=False),
        "audit_violations": _read_audit_violations(chapter_id, only_evidence=False),
        "confirm_results": _read_confirm_results(chapter_id),
        "web_search_log": _read_text(WEB_SEARCH_LOG, allow_missing=True),
    }


def _build_regenerate_mapping(chapter_id: str) -> dict[str, str]:
    """构建 regenerate role 的占位符填充表。

    Args:
        chapter_id: 章节 stem。

    Returns:
        占位符到内容字符串的映射。

    Raises:
        FileNotFoundError: 当前章节文件缺失。
    """

    chapter_file = SECTIONS_DIR / f"{chapter_id}.md"
    return {
        "chapter_id": chapter_id,
        "chapter_prompt": _read_chapter_prompt(chapter_id),
        "chapter_markdown": _read_text(chapter_file, allow_missing=True),
        "audit_violations": _read_audit_violations(chapter_id, only_evidence=False),
        "company_meta": _read_text(INPUT_COMPANY, allow_missing=True),
        "company_facets": _read_text(COMPANY_FACETS, allow_missing=True),
        "web_search_log": _read_text(WEB_SEARCH_LOG, allow_missing=True),
        "facts": _read_text(FACTS_FILE, allow_missing=True),
    }


def _build_final_audit_mapping() -> dict[str, str]:
    """构建 final_audit role 的占位符填充表。

    Returns:
        占位符到内容字符串的映射。

    Raises:
        无。
    """

    return {
        "merged_draft": _read_merged_draft(),
        "web_search_log": _read_text(WEB_SEARCH_LOG, allow_missing=True),
        "facts": _read_text(FACTS_FILE, allow_missing=True),
        "company_facets": _read_text(COMPANY_FACETS, allow_missing=True),
    }


ROLE_BUILDERS: dict[str, Callable[[argparse.Namespace], dict[str, str]]] = {
    "infer": lambda args: _build_infer_mapping(),
    "audit": lambda args: _build_audit_mapping(_require_chapter(args)),
    "confirm": lambda args: _build_confirm_mapping(_require_chapter(args)),
    "repair": lambda args: _build_repair_mapping(_require_chapter(args)),
    "regenerate": lambda args: _build_regenerate_mapping(_require_chapter(args)),
    "final_audit": lambda args: _build_final_audit_mapping(),
}


def _require_chapter(args: argparse.Namespace) -> str:
    """校验并返回 ``--chapter`` 参数。

    Args:
        args: argparse 命名空间。

    Returns:
        章节 stem。

    Raises:
        SystemExit: 未提供 ``--chapter``。
    """

    chapter = getattr(args, "chapter", None)
    if not chapter:
        sys.exit("[render_role] 该 role 需要 --chapter <chapter_id> 参数")
    return chapter


def _parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    """解析命令行参数。

    Args:
        argv: 自定义参数列表；None 时使用 ``sys.argv``。

    Returns:
        argparse 命名空间。

    Raises:
        SystemExit: 参数非法。
    """

    parser = argparse.ArgumentParser(
        description="渲染 roles/<role>.md 为可派发给子代理的完整 prompt",
    )
    parser.add_argument("role", choices=sorted(ROLE_BUILDERS.keys()))
    parser.add_argument("--chapter", help="章节 stem，如 03_financials；audit/confirm/repair/regenerate 必填")
    return parser.parse_args(argv)


def run(argv: list[str] | None = None) -> int:
    """渲染指定 role 并打印到 stdout。

    Args:
        argv: 自定义参数列表；None 时使用 ``sys.argv``。

    Returns:
        进程退出码（0 表示成功）。

    Raises:
        FileNotFoundError: 当 role 缺少必需输入文件时由底层抛出。
    """

    args = _parse_args(argv)
    role_file = ROLES_DIR / f"{args.role}.md"
    template = _extract_prompt_section(role_file)
    mapping = ROLE_BUILDERS[args.role](args)
    rendered = _substitute(template, mapping)
    sys.stdout.write(rendered)
    if not rendered.endswith("\n"):
        sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    sys.exit(run())
