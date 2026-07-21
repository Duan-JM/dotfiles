"""合并已生成的公司调研章节为完整报告。

排序规则：
    ``output/sections/*.md`` 按文件名升序合并。新约定章节编号：
    - ``00_overview.md``（``rough`` 默认；``--with-overview`` 可选）—— 粗读闸门或投资要点概览，置于报告最前
    - ``01_...`` ~ ``08_...`` —— 标准 8 章
    - ``09_research_decision.md``（``rough`` 默认；``--with-decision`` 可选）—— 研究决策章

附录：
    - 附录 A：全网检索证据库（来自 ``output/web_search_log.md``）
    - 附录 B：审计闭环结果摘要（若存在 ``output/audits/audit_summary.md``）

向后兼容：
    若没有 ``00`` / ``09`` 章节，按既有 8 章顺序合并；若没有 audits 附录，按既有方式合并。
"""

import argparse
import sys
from pathlib import Path

from audit_summary import run as refresh_audit_summary
from verify_pipeline import print_validation_result, validate_pipeline

ROOT = Path(__file__).resolve().parents[1]


def read_file(file_path: Path) -> str:
    """读取文件内容，文件不存在则返回空字符串。"""
    if not file_path.exists():
        return ""
    return file_path.read_text(encoding="utf-8").strip()


def extract_field(company_text, header):
    """从 input/company.md 中提取「- 字段名：值」形式的值。"""
    target = f"- {header}："
    for line in company_text.split("\n"):
        line = line.strip()
        if line.startswith(target):
            value = line[len(target):].strip()
            # 去掉占位提示
            if value and value not in {"（请填写）", ""} and not value.startswith("YYYY"):
                return value
    return ""


def build_header(company_text):
    """构建报告抬头：公司名 + 数据截至日期 + 报告模式。"""
    name = extract_field(company_text, "公司中文名") or "公司调研报告"
    as_of = extract_field(company_text, "数据截至日期") or "未填写"
    mode = extract_field(company_text, "报告模式") or "deep"
    code = extract_field(company_text, "证券代码") or ""

    title = f"# {name} 公司调研报告"
    if code:
        title += f"（{code}）"
    meta_lines = [
        title,
        "",
        f"- 报告模式：{mode}",
        f"- 数据截至：{as_of}",
        "",
        "> 本报告基于公开信息整理，不构成投资建议、评级意见或买卖证券建议。",
        "> 公开信息可能存在滞后、遗漏或错误，使用者应自行核验关键数据。",
        "",
    ]
    return "\n".join(meta_lines)


def collect_section_files(root: Path = ROOT) -> list[Path]:
    """按文件名升序收集所有可合并的章节文件。

    返回包含 00_overview / 01..08 / 09_research_decision 等已存在章节的有序列表。
    跳过 .gitkeep 等占位文件。
    """
    sections_dir = root / "output" / "sections"
    return [
        path
        for path in sorted(sections_dir.glob("*.md"))
        if path.name != ".gitkeep"
    ]


def run_merge(*, force: bool = False, root: Path = ROOT) -> bool:
    """合并所有章节文件为完整调研报告。"""
    root = root.resolve()
    validation = validate_pipeline(root, force=force)
    print_validation_result(validation)
    if not validation.ok:
        return False
    if refresh_audit_summary(root) != 0:
        print("错误: 审计附录生成失败。", file=sys.stderr)
        return False

    company_file = root / "input" / "company.md"
    merged_file = root / "output" / "research_report.md"
    search_log_file = root / "output" / "web_search_log.md"
    audit_summary_file = root / "output" / "audits" / "audit_summary.md"

    company_text = read_file(company_file)
    if not company_text:
        print("错误: 未找到 input/company.md，请先填写公司信息。")
        return False

    section_files = collect_section_files(root)
    if not section_files:
        print("错误: 没有找到已生成的章节文件，请先运行 /company-generate")
        return False

    parts = [build_header(company_text)]
    for filepath in section_files:
        content = read_file(filepath)
        if content:
            parts.append(content)

    # 附录 A：证据库
    search_log = read_file(search_log_file)
    if search_log:
        parts.append("# 附录 A · 全网检索证据库\n\n" + search_log)

    # 附录 B：审计闭环结果摘要（若已生成）
    audit_summary = read_file(audit_summary_file)
    if audit_summary:
        parts.append(audit_summary)

    merged = "\n\n---\n\n".join(parts)

    merged_file.parent.mkdir(parents=True, exist_ok=True)
    merged_file.write_text(merged, encoding="utf-8")

    print(f"调研报告已合并到: {merged_file.relative_to(root)}")
    print(f"  - 章节数：{len(section_files)}")
    print(f"  - 证据库附录：{'是' if search_log else '否'}")
    print(f"  - 审计闭环附录：{'是' if audit_summary else '否'}")
    return True


def _parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="验证并合并公司调研章节")
    parser.add_argument(
        "--force",
        action="store_true",
        help="仅允许绕过 audit_status=failed；其它闸门仍必须通过",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    """CLI 入口。"""

    args = _parse_args(argv)
    return 0 if run_merge(force=args.force) else 1


if __name__ == "__main__":
    sys.exit(main())
