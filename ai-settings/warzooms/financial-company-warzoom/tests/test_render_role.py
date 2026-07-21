from __future__ import annotations

import io
import json
import sys
import tempfile
import unittest
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path
from unittest.mock import patch

PROJECT_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(PROJECT_ROOT / "scripts"))

import render_role  # noqa: E402


class RenderRoleTests(unittest.TestCase):
    def test_substitute_rejects_unmapped_template_placeholder(self) -> None:
        with self.assertRaisesRegex(ValueError, "missing"):
            render_role._substitute("{known} {missing}", {"known": "ok"})

    def test_substitute_does_not_expand_placeholders_inside_values(self) -> None:
        rendered = render_role._substitute(
            "{chapter_id}\n{web_search_log}",
            {
                "chapter_id": "03_financials",
                "web_search_log": "原文保留 {chapter_id}",
            },
        )

        self.assertEqual(rendered, "03_financials\n原文保留 {chapter_id}")

    def test_all_registered_roles_render_with_fixture_inputs(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            input_dir = root / "input"
            sections_dir = root / "output" / "sections"
            audits_dir = root / "output" / "audits"
            input_dir.mkdir(parents=True)
            (input_dir / "extra_sources").mkdir()
            sections_dir.mkdir(parents=True)
            audits_dir.mkdir(parents=True)

            company_file = input_dir / "company.md"
            search_log = root / "output" / "web_search_log.md"
            facts_file = root / "output" / "facts.md"
            facets_file = root / "output" / "company_facets.md"
            programmatic_file = audits_dir / "programmatic_check.json"
            company_file.write_text("- 公司中文名：示例公司\n", encoding="utf-8")
            search_log.write_text(
                "## SRC-001\n- 标题：示例\n- 来源：交易所\n- 关键摘录：\n> 示例摘录\n",
                encoding="utf-8",
            )
            facts_file.write_text("| F001 | 示例 | SRC-001 |\n", encoding="utf-8")
            facets_file.write_text("# 公司画像\n", encoding="utf-8")
            (sections_dir / "03_financials.md").write_text(
                "# 财务表现\n\n营业收入 10 亿元（SRC-001）。\n",
                encoding="utf-8",
            )
            programmatic_file.write_text(
                json.dumps(
                    {
                        "chapters": [
                            {
                                "chapter": "03_financials",
                                "issues": [],
                            }
                        ]
                    },
                    ensure_ascii=False,
                ),
                encoding="utf-8",
            )
            (audits_dir / "03_financials.audit.json").write_text(
                json.dumps(
                    {
                        "chapter": "03_financials",
                        "category": "ok",
                        "violations": [],
                    },
                    ensure_ascii=False,
                ),
                encoding="utf-8",
            )
            (audits_dir / "03_financials.confirm.json").write_text(
                json.dumps({"chapter": "03_financials", "results": []}, ensure_ascii=False),
                encoding="utf-8",
            )

            with patch.multiple(
                render_role,
                ROOT=root,
                SECTIONS_DIR=sections_dir,
                AUDITS_DIR=audits_dir,
                INPUT_COMPANY=company_file,
                INPUT_EXTRA_DIR=input_dir / "extra_sources",
                WEB_SEARCH_LOG=search_log,
                FACTS_FILE=facts_file,
                COMPANY_FACETS=facets_file,
                PROGRAMMATIC_CHECK=programmatic_file,
            ):
                invocations = (
                    ["infer"],
                    ["audit", "--chapter", "03_financials"],
                    ["confirm", "--chapter", "03_financials"],
                    ["repair", "--chapter", "03_financials"],
                    ["regenerate", "--chapter", "03_financials"],
                    ["final_audit"],
                )
                for argv in invocations:
                    stdout = io.StringIO()
                    stderr = io.StringIO()
                    with redirect_stdout(stdout), redirect_stderr(stderr):
                        exit_code = render_role.run(argv)
                    self.assertEqual(exit_code, 0, msg=f"{argv}: {stderr.getvalue()}")
                    self.assertTrue(stdout.getvalue().strip())


if __name__ == "__main__":
    unittest.main()
