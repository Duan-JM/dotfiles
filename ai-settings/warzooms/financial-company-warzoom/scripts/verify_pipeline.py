#!/usr/bin/env python3
"""在合并前验证章节、证据、manifest 与审计产物是否一致。"""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from pipeline_common import merge_section_texts, sha256_file, sha256_text

ROOT = Path(__file__).resolve().parents[1]

_BASE_SECTIONS: dict[str, tuple[str, ...]] = {
    "rough": (
        "00_overview",
        "01_company_profile",
        "02_business_model",
        "03_financials",
        "06_recent_news",
        "09_research_decision",
    ),
    "short": (
        "01_company_profile",
        "02_business_model",
        "03_financials",
        "06_recent_news",
        "08_investment_thesis",
    ),
    "deep": (
        "01_company_profile",
        "02_business_model",
        "03_financials",
        "04_industry_competition",
        "05_management_governance",
        "06_recent_news",
        "07_swot",
        "08_investment_thesis",
    ),
}
_VALID_WORKFLOW_MODES = {"full", "fast"}
_DATE_PATTERN = re.compile(r"^\d{4}-\d{2}-\d{2}$")


@dataclass(frozen=True)
class ValidationIssue:
    """单条合并前验证问题。"""

    code: str
    message: str
    forceable: bool = False


@dataclass(frozen=True)
class ValidationResult:
    """合并前验证结果。"""

    errors: tuple[ValidationIssue, ...]
    bypassed: tuple[ValidationIssue, ...]

    @property
    def ok(self) -> bool:
        """没有不可绕过错误时返回 True。"""

        return not self.errors


def expected_section_ids(
    report_mode: str,
    *,
    with_decision: bool,
    with_overview: bool,
) -> tuple[str, ...]:
    """根据报告模式与可选标记返回严格章节集合。"""

    base = list(_BASE_SECTIONS[report_mode])
    if report_mode != "rough" and with_overview:
        base.insert(0, "00_overview")
    if report_mode != "rough" and with_decision:
        base.append("09_research_decision")
    return tuple(base)


def _extract_input_field(company_text: str, header: str) -> str:
    """提取 input/company.md 中的单行字段值。"""

    prefix = f"- {header}："
    for raw_line in company_text.splitlines():
        line = raw_line.strip()
        if line.startswith(prefix):
            return line[len(prefix) :].strip().strip("`")
    return ""


def _load_json_object(
    path: Path,
    *,
    label: str,
    code: str,
    issues: list[ValidationIssue],
) -> dict[str, Any] | None:
    """读取 JSON 对象；错误写入 issues。"""

    if not path.is_file():
        issues.append(ValidationIssue(code, f"缺少{label}：{path}"))
        return None
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        issues.append(
            ValidationIssue(
                code,
                f"{label}不是合法 JSON：{path}（line {exc.lineno}, column {exc.colno}）",
            )
        )
        return None
    if not isinstance(payload, dict):
        issues.append(ValidationIssue(code, f"{label}顶层必须是 JSON object：{path}"))
        return None
    return payload


def _require_nonempty_text(
    path: Path,
    *,
    label: str,
    code: str,
    issues: list[ValidationIssue],
) -> str | None:
    """读取必需文本；缺失或空文件写入 issues。"""

    if not path.is_file():
        issues.append(ValidationIssue(code, f"缺少{label}：{path}"))
        return None
    text = path.read_text(encoding="utf-8")
    if not text.strip():
        issues.append(ValidationIssue(code, f"{label}为空：{path}"))
        return None
    return text


def _validate_hash(
    manifest: dict[str, Any],
    *,
    key: str,
    path: Path,
    issues: list[ValidationIssue],
) -> None:
    """校验 manifest 中的文件 hash。"""

    if not path.is_file():
        return
    expected = manifest.get(key)
    actual = sha256_file(path)
    if expected != actual:
        issues.append(
            ValidationIssue(
                "HASH_MISMATCH",
                f"{key} 与当前文件不一致：manifest={expected!r}，actual={actual}",
            )
        )


def _safe_audit_path(
    root: Path,
    raw_path: object,
    *,
    label: str,
    issues: list[ValidationIssue],
) -> Path | None:
    """解析并限制审计路径只能位于 output/audits。"""

    if not isinstance(raw_path, str) or not raw_path:
        issues.append(ValidationIssue("AUDIT_PATH", f"{label}路径缺失或不是字符串"))
        return None
    candidate = (root / raw_path).resolve()
    audit_root = (root / "output" / "audits").resolve()
    if not candidate.is_relative_to(audit_root):
        issues.append(ValidationIssue("AUDIT_PATH", f"{label}越出 output/audits：{raw_path}"))
        return None
    return candidate


def _find_chapter_audit_path(
    root: Path,
    section_id: str,
    state: dict[str, Any],
    *,
    issues: list[ValidationIssue],
) -> Path | None:
    """从章节 manifest 项中找到主 audit JSON。"""

    audit_files = state.get("audit_files")
    if not isinstance(audit_files, list):
        issues.append(ValidationIssue("AUDIT_FILE", f"{section_id} 缺少 audit_files 列表"))
        return None
    audit_path_value = next(
        (
            item
            for item in audit_files
            if isinstance(item, str) and item.endswith(f"{section_id}.audit.json")
        ),
        None,
    )
    return _safe_audit_path(
        root,
        audit_path_value,
        label=f"{section_id} audit",
        issues=issues,
    )


def _validate_passed_audit(
    audit_payload: dict[str, Any],
    *,
    section_id: str,
    issues: list[ValidationIssue],
) -> None:
    """校验标记为通过的单章 audit 内容。"""

    if audit_payload.get("chapter") != section_id:
        issues.append(
            ValidationIssue(
                "AUDIT_CHAPTER",
                f"{section_id} audit 的 chapter 字段不匹配：{audit_payload.get('chapter')!r}",
            )
        )
    violations = audit_payload.get("violations")
    if audit_payload.get("category") != "ok" or violations not in ([], None):
        issues.append(
            ValidationIssue(
                "AUDIT_NOT_OK",
                f"{section_id} 标记 passed，但 audit category/violations 仍未通过",
            )
        )


def validate_pipeline(root: Path = ROOT, *, force: bool = False) -> ValidationResult:
    """验证当前输出是否满足合并条件。"""

    root = root.resolve()
    issues: list[ValidationIssue] = []
    input_file = root / "input" / "company.md"
    output_dir = root / "output"
    sections_dir = output_dir / "sections"
    audits_dir = output_dir / "audits"
    manifest_file = output_dir / "manifest.json"
    search_log_file = output_dir / "web_search_log.md"
    facts_file = output_dir / "facts.md"
    facets_file = output_dir / "company_facets.md"
    programmatic_file = audits_dir / "programmatic_check.json"

    company_text = _require_nonempty_text(
        input_file,
        label="公司输入",
        code="INPUT_REQUIRED",
        issues=issues,
    )
    _require_nonempty_text(
        search_log_file,
        label="证据库",
        code="SOURCE_REQUIRED",
        issues=issues,
    )
    _require_nonempty_text(
        facts_file,
        label="事实表",
        code="FACTS_REQUIRED",
        issues=issues,
    )
    _require_nonempty_text(
        facets_file,
        label="公司画像",
        code="FACETS_REQUIRED",
        issues=issues,
    )
    manifest = _load_json_object(
        manifest_file,
        label="manifest",
        code="MANIFEST_INVALID",
        issues=issues,
    )
    programmatic = _load_json_object(
        programmatic_file,
        label="程序化检查结果",
        code="PROGRAMMATIC_INVALID",
        issues=issues,
    )
    if manifest is None:
        return ValidationResult(tuple(issues), ())

    report_mode = manifest.get("report_mode")
    if report_mode not in _BASE_SECTIONS:
        issues.append(ValidationIssue("REPORT_MODE", f"manifest.report_mode 非法：{report_mode!r}"))
        return ValidationResult(tuple(issues), ())
    workflow_mode = manifest.get("workflow_mode")
    if workflow_mode not in _VALID_WORKFLOW_MODES:
        issues.append(
            ValidationIssue("WORKFLOW_MODE", f"manifest.workflow_mode 非法：{workflow_mode!r}")
        )
        return ValidationResult(tuple(issues), ())
    if manifest.get("run_status") != "completed":
        issues.append(
            ValidationIssue(
                "RUN_STATUS",
                f"manifest.run_status 必须为 completed：{manifest.get('run_status')!r}",
            )
        )

    with_decision = manifest.get("with_decision", False)
    with_overview = manifest.get("with_overview", False)
    if not isinstance(with_decision, bool) or not isinstance(with_overview, bool):
        issues.append(ValidationIssue("OPTION_FLAGS", "with_decision/with_overview 必须为 boolean"))
        with_decision = False
        with_overview = False
    expected_ids = expected_section_ids(
        report_mode,
        with_decision=with_decision,
        with_overview=with_overview,
    )

    if company_text is not None:
        input_mode = _extract_input_field(company_text, "报告模式")
        if input_mode != report_mode:
            issues.append(
                ValidationIssue(
                    "INPUT_MODE",
                    f"input/company.md 报告模式与 manifest 不一致：{input_mode!r} != {report_mode!r}",
                )
            )
        input_date = _extract_input_field(company_text, "数据截至日期")
        manifest_date = manifest.get("data_as_of")
        if not _DATE_PATTERN.fullmatch(input_date):
            issues.append(ValidationIssue("INPUT_DATE", f"数据截至日期未填写有效日期：{input_date!r}"))
        elif manifest_date != input_date:
            issues.append(
                ValidationIssue(
                    "INPUT_DATE",
                    f"数据截至日期与 manifest 不一致：{input_date!r} != {manifest_date!r}",
                )
            )

    _validate_hash(manifest, key="source_log_hash", path=search_log_file, issues=issues)
    _validate_hash(manifest, key="facts_hash", path=facts_file, issues=issues)
    _validate_hash(manifest, key="company_facets_hash", path=facets_file, issues=issues)

    actual_section_files = (
        sorted(path for path in sections_dir.glob("*.md") if path.name != ".gitkeep")
        if sections_dir.is_dir()
        else []
    )
    actual_ids = tuple(path.stem for path in actual_section_files)
    missing_ids = [section_id for section_id in expected_ids if section_id not in actual_ids]
    extra_ids = [section_id for section_id in actual_ids if section_id not in expected_ids]
    if missing_ids:
        issues.append(ValidationIssue("SECTION_MISSING", f"缺少必需章节：{', '.join(missing_ids)}"))
    if extra_ids:
        issues.append(ValidationIssue("SECTION_EXTRA", f"发现模式外章节：{', '.join(extra_ids)}"))

    manifest_sections = manifest.get("sections")
    if not isinstance(manifest_sections, dict):
        issues.append(ValidationIssue("MANIFEST_SECTIONS", "manifest.sections 必须是 object"))
        manifest_sections = {}

    reports_by_id: dict[str, dict[str, Any]] = {}
    if programmatic is not None:
        current_source_hash = sha256_file(search_log_file) if search_log_file.is_file() else None
        if programmatic.get("source_log_hash") != current_source_hash:
            issues.append(
                ValidationIssue(
                    "PROGRAMMATIC_STALE",
                    "programmatic_check.json 的 source_log_hash 与当前证据库不一致",
                )
            )
        reports = programmatic.get("chapters")
        if not isinstance(reports, list):
            issues.append(
                ValidationIssue("PROGRAMMATIC_INVALID", "programmatic_check.chapters 必须是 array")
            )
        else:
            reports_by_id = {
                report.get("chapter"): report
                for report in reports
                if isinstance(report, dict) and isinstance(report.get("chapter"), str)
            }

    expected_paths = [sections_dir / f"{section_id}.md" for section_id in expected_ids]
    for section_id, section_path in zip(expected_ids, expected_paths):
        state = manifest_sections.get(section_id)
        if not isinstance(state, dict):
            issues.append(ValidationIssue("SECTION_STATE", f"manifest 缺少章节状态：{section_id}"))
            continue
        if state.get("status") != "generated":
            issues.append(
                ValidationIssue(
                    "SECTION_STATUS",
                    f"{section_id}.status 必须为 generated：{state.get('status')!r}",
                )
            )
        attempts = state.get("repair_attempts")
        if not isinstance(attempts, int) or not 0 <= attempts <= 3:
            issues.append(
                ValidationIssue(
                    "REPAIR_ATTEMPTS",
                    f"{section_id}.repair_attempts 必须为 0..3：{attempts!r}",
                )
            )
        if not section_path.is_file():
            continue
        if not section_path.read_text(encoding="utf-8").strip():
            issues.append(ValidationIssue("SECTION_EMPTY", f"{section_id} 章节文件为空"))
            continue
        content_hash = sha256_file(section_path)
        if state.get("content_hash") != content_hash:
            issues.append(
                ValidationIssue(
                    "SECTION_HASH",
                    f"{section_id}.content_hash 与当前章节不一致",
                )
            )

        report = reports_by_id.get(section_id)
        if report is None:
            issues.append(
                ValidationIssue("PROGRAMMATIC_MISSING", f"程序化检查缺少章节：{section_id}")
            )
        else:
            if report.get("content_hash") != content_hash:
                issues.append(
                    ValidationIssue(
                        "PROGRAMMATIC_STALE",
                        f"{section_id} 的程序化检查已过期",
                    )
                )
            report_issues = report.get("issues")
            if not isinstance(report_issues, list):
                issues.append(
                    ValidationIssue(
                        "PROGRAMMATIC_INVALID",
                        f"{section_id} 的 programmatic issues 必须是 array",
                    )
                )
            elif any(
                isinstance(item, dict) and item.get("severity") == "error"
                for item in report_issues
            ):
                issues.append(
                    ValidationIssue(
                        "PROGRAMMATIC_ERROR",
                        f"{section_id} 仍有 error 级程序化证据问题",
                    )
                )

        if workflow_mode != "full":
            continue
        audit_status = state.get("audit_status")
        audit_path = _find_chapter_audit_path(root, section_id, state, issues=issues)
        audit_payload = (
            _load_json_object(
                audit_path,
                label=f"{section_id} audit",
                code="AUDIT_INVALID",
                issues=issues,
            )
            if audit_path is not None
            else None
        )
        if audit_status == "failed":
            issues.append(
                ValidationIssue(
                    "AUDIT_FAILED",
                    f"{section_id} 审计失败；仅显式 --force 可绕过",
                    forceable=True,
                )
            )
            continue
        if audit_status != "passed":
            issues.append(
                ValidationIssue(
                    "AUDIT_STATUS",
                    f"{section_id}.audit_status 必须为 passed：{audit_status!r}",
                )
            )
            continue
        if state.get("audited_content_hash") != content_hash:
            issues.append(
                ValidationIssue(
                    "AUDIT_STALE",
                    f"{section_id}.audited_content_hash 与当前章节不一致",
                )
            )
        if audit_payload is not None:
            _validate_passed_audit(audit_payload, section_id=section_id, issues=issues)

    final_state = manifest.get("final_audit")
    if not isinstance(final_state, dict):
        issues.append(ValidationIssue("FINAL_AUDIT", "manifest.final_audit 必须是 object"))
    elif workflow_mode == "full":
        if final_state.get("status") != "passed":
            issues.append(
                ValidationIssue(
                    "FINAL_AUDIT",
                    f"final_audit.status 必须为 passed：{final_state.get('status')!r}",
                )
            )
        existing_expected_paths = [path for path in expected_paths if path.is_file()]
        sections_hash = sha256_text(merge_section_texts(existing_expected_paths))
        if final_state.get("sections_hash") != sections_hash:
            issues.append(
                ValidationIssue(
                    "FINAL_AUDIT_STALE",
                    "final_audit.sections_hash 与当前章节集合不一致",
                )
            )
        final_path = _safe_audit_path(
            root,
            final_state.get("audit_file"),
            label="final audit",
            issues=issues,
        )
        final_payload = (
            _load_json_object(
                final_path,
                label="final audit",
                code="FINAL_AUDIT",
                issues=issues,
            )
            if final_path is not None
            else None
        )
        if final_payload is not None:
            violations = final_payload.get("violations")
            if final_payload.get("category") != "ok" or violations not in ([], None):
                issues.append(
                    ValidationIssue(
                        "FINAL_AUDIT",
                        "final audit 标记 passed，但 category/violations 仍未通过",
                    )
                )
    elif final_state.get("status") not in {"not_run", "passed"}:
        issues.append(
            ValidationIssue(
                "FINAL_AUDIT",
                f"fast 模式 final_audit.status 应为 not_run 或 passed：{final_state.get('status')!r}",
            )
        )

    bypassed = tuple(issue for issue in issues if force and issue.forceable)
    errors = tuple(issue for issue in issues if not (force and issue.forceable))
    return ValidationResult(errors=errors, bypassed=bypassed)


def print_validation_result(result: ValidationResult) -> None:
    """打印验证结果。"""

    for issue in result.bypassed:
        print(f"[verify_pipeline] FORCE [{issue.code}] {issue.message}")
    for issue in result.errors:
        print(f"[verify_pipeline] ERROR [{issue.code}] {issue.message}", file=sys.stderr)
    if result.ok:
        print("[verify_pipeline] 合并前检查通过。")


def _parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="验证公司调研流水线是否满足合并条件")
    parser.add_argument(
        "--force",
        action="store_true",
        help="仅绕过 audit_status=failed 的章节；不会绕过缺章节、过期 hash 或程序化 error",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    """CLI 入口。"""

    args = _parse_args(argv)
    result = validate_pipeline(force=args.force)
    print_validation_result(result)
    return 0 if result.ok else 1


if __name__ == "__main__":
    sys.exit(main())
