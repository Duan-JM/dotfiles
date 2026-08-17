from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

PROJECT_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(PROJECT_ROOT / "scripts"))

import check_evidence  # noqa: E402
from pipeline_common import sha256_file  # noqa: E402


class CheckEvidenceTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp_dir = tempfile.TemporaryDirectory()
        self.root = Path(self.temp_dir.name)
        self.sections_dir = self.root / "output" / "sections"
        self.audits_dir = self.root / "output" / "audits"
        self.search_log = self.root / "output" / "web_search_log.md"
        self.company_facets = self.root / "output" / "company_facets.md"
        self.sections_dir.mkdir(parents=True)
        self.audits_dir.mkdir(parents=True)
        self.patcher = patch.multiple(
            check_evidence,
            ROOT=self.root,
            OUTPUT_DIR=self.root / "output",
            SECTIONS_DIR=self.sections_dir,
            SEARCH_LOG_FILE=self.search_log,
            COMPANY_FACETS_FILE=self.company_facets,
            AUDITS_DIR=self.audits_dir,
            PROGRAMMATIC_CHECK_FILE=self.audits_dir / "programmatic_check.json",
            INDUSTRY_RULES_FILE=PROJECT_ROOT / "data" / "industry_rules.json",
        )
        self.patcher.start()

    def tearDown(self) -> None:
        self.patcher.stop()
        self.temp_dir.cleanup()

    def test_require_sections_rejects_empty_output(self) -> None:
        exit_code = check_evidence.run(None, require_sections=True)

        self.assertEqual(exit_code, 2)

    def test_fail_on_error_rejects_unreferenced_number(self) -> None:
        self.search_log.write_text("## SRC-001\n", encoding="utf-8")
        (self.sections_dir / "03_financials.md").write_text(
            "# 财务表现\n\n营业收入为 10 亿元。\n",
            encoding="utf-8",
        )

        exit_code = check_evidence.run(None, fail_on_error=True, require_sections=True)

        self.assertEqual(exit_code, 1)

    def test_report_records_current_source_and_content_hashes(self) -> None:
        self.search_log.write_text("## SRC-001\n", encoding="utf-8")
        section_file = self.sections_dir / "03_financials.md"
        section_file.write_text(
            "# 财务表现\n\n营业收入为 10 亿元（SRC-001）。\n",
            encoding="utf-8",
        )

        exit_code = check_evidence.run(None, fail_on_error=True, require_sections=True)
        payload = json.loads(
            (self.audits_dir / "programmatic_check.json").read_text(encoding="utf-8")
        )

        self.assertEqual(exit_code, 0)
        self.assertEqual(payload["version"], "1.1")
        self.assertEqual(payload["source_log_hash"], sha256_file(self.search_log))
        self.assertEqual(payload["chapters"][0]["content_hash"], sha256_file(section_file))
        self.assertEqual(payload["chapters"][0]["issues"], [])

    def test_selected_industry_rule_missing_kpi_only_warns(self) -> None:
        self.search_log.write_text("## SRC-001\n", encoding="utf-8")
        self.company_facets.write_text(
            """# 公司画像与关键约束

## industry_rule_selection
```json
{"selected_rule_ids": ["software_subscription"]}
```
""",
            encoding="utf-8",
        )
        (self.sections_dir / "03_financials.md").write_text(
            "# 财务表现\n\n营业收入为 10 亿元（SRC-001）。\n",
            encoding="utf-8",
        )

        exit_code = check_evidence.run(None, fail_on_error=True, require_sections=True)
        payload = json.loads(
            (self.audits_dir / "programmatic_check.json").read_text(encoding="utf-8")
        )
        issues = payload["chapters"][0]["issues"]

        self.assertEqual(exit_code, 0)
        self.assertEqual(payload["industry_rules"]["selected_rule_ids"], ["software_subscription"])
        self.assertTrue(any(issue["rule"] == "K1" and issue["severity"] == "warning" for issue in issues))

    def test_unselected_industry_rule_does_not_warn_for_old_facets(self) -> None:
        self.search_log.write_text("## SRC-001\n", encoding="utf-8")
        self.company_facets.write_text(
            "# 公司画像与关键约束\n\n## business_model_tags\n- 软件订阅（一句话理由）\n",
            encoding="utf-8",
        )
        (self.sections_dir / "03_financials.md").write_text(
            "# 财务表现\n\n营业收入为 10 亿元（SRC-001）。\n",
            encoding="utf-8",
        )

        exit_code = check_evidence.run(None, fail_on_error=True, require_sections=True)
        payload = json.loads(
            (self.audits_dir / "programmatic_check.json").read_text(encoding="utf-8")
        )

        self.assertEqual(exit_code, 0)
        self.assertEqual(payload["industry_rules"]["selected_rule_ids"], [])
        self.assertEqual(payload["chapters"][0]["issues"], [])

    def test_english_kpi_alias_requires_token_boundary(self) -> None:
        cases = [
            ("barriers", "ARR"),
            ("macroeconomic", "ROE"),
            ("caching", "CAC"),
        ]

        for text, alias in cases:
            with self.subTest(text=text, alias=alias):
                self.assertFalse(check_evidence._text_contains_alias(text, alias))

    def test_kpi_alias_boundary_keeps_chinese_and_symbol_matches(self) -> None:
        cases = [
            ("ARR 增速改善", "ARR"),
            ("arr增长暂未获取", "ARR"),
            ("LTV/CAC 高于同业", "LTV/CAC"),
            ("EV/ARR 估值较低", "EV/ARR"),
            ("净收入留存暂未获取", "净收入留存"),
        ]

        for text, alias in cases:
            with self.subTest(text=text, alias=alias):
                self.assertTrue(check_evidence._text_contains_alias(text, alias))


if __name__ == "__main__":
    unittest.main()
