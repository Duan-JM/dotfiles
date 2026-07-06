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

import glob
import os

SECTIONS_DIR = "output/sections"
MERGED_FILE = "output/research_report.md"
COMPANY_FILE = "input/company.md"
SEARCH_LOG_FILE = "output/web_search_log.md"
AUDIT_SUMMARY_FILE = "output/audits/audit_summary.md"


def read_file(file_path):
    """读取文件内容，文件不存在则返回空字符串。"""
    if not os.path.exists(file_path):
        return ""
    with open(file_path, "r", encoding="utf-8") as f:
        return f.read().strip()


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


def collect_section_files():
    """按文件名升序收集所有可合并的章节文件。

    返回包含 00_overview / 01..08 / 09_research_decision 等已存在章节的有序列表。
    跳过 .gitkeep 等占位文件。
    """
    section_files = sorted(glob.glob(os.path.join(SECTIONS_DIR, "*.md")))
    return [f for f in section_files if not f.endswith(".gitkeep")]


def run_merge():
    """合并所有章节文件为完整调研报告。"""
    company_text = read_file(COMPANY_FILE)
    if not company_text:
        print("错误: 未找到 input/company.md，请先填写公司信息。")
        return False

    section_files = collect_section_files()
    if not section_files:
        print("错误: 没有找到已生成的章节文件，请先运行 /company-generate")
        return False

    parts = [build_header(company_text)]
    for filepath in section_files:
        content = read_file(filepath)
        if content:
            parts.append(content)

    # 附录 A：证据库
    search_log = read_file(SEARCH_LOG_FILE)
    if search_log:
        parts.append("# 附录 A · 全网检索证据库\n\n" + search_log)

    # 附录 B：审计闭环结果摘要（若已生成）
    audit_summary = read_file(AUDIT_SUMMARY_FILE)
    if audit_summary:
        parts.append(audit_summary)

    merged = "\n\n---\n\n".join(parts)

    os.makedirs(os.path.dirname(MERGED_FILE), exist_ok=True)
    with open(MERGED_FILE, "w", encoding="utf-8") as f:
        f.write(merged)

    print(f"调研报告已合并到: {MERGED_FILE}")
    print(f"  - 章节数：{len(section_files)}")
    print(f"  - 证据库附录：{'是' if search_log else '否'}")
    print(f"  - 审计闭环附录：{'是' if audit_summary else '否'}")
    return True


if __name__ == "__main__":
    run_merge()
