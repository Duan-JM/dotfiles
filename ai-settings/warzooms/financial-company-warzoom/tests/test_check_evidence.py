from __future__ import annotations

import json
import shutil
import sys
import unittest
import uuid
from pathlib import Path
from unittest.mock import patch

PROJECT_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(PROJECT_ROOT / "scripts"))

import check_evidence  # noqa: E402
from pipeline_common import sha256_file  # noqa: E402


class CheckEvidenceTests(unittest.TestCase):
    def setUp(self) -> None:
        self.root = PROJECT_ROOT / "tests" / ".scratch" / f"check_evidence_{uuid.uuid4().hex}"
        self.sections_dir = self.root / "output" / "sections"
        self.audits_dir = self.root / "output" / "audits"
        self.search_log = self.root / "output" / "web_search_log.md"
        self.sections_dir.mkdir(parents=True)
        self.audits_dir.mkdir(parents=True)
        self.patcher = patch.multiple(
            check_evidence,
            ROOT=self.root,
            OUTPUT_DIR=self.root / "output",
            SECTIONS_DIR=self.sections_dir,
            SEARCH_LOG_FILE=self.search_log,
            AUDITS_DIR=self.audits_dir,
            PROGRAMMATIC_CHECK_FILE=self.audits_dir / "programmatic_check.json",
        )
        self.patcher.start()

    def tearDown(self) -> None:
        self.patcher.stop()
        shutil.rmtree(self.root, ignore_errors=True)

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

    def test_investment_thesis_warns_when_expectation_gap_missing(self) -> None:
        self.search_log.write_text("## SRC-001\n", encoding="utf-8")
        (self.sections_dir / "08_investment_thesis.md").write_text(
            "# 投资逻辑与风险\n\n营业收入为 10 亿元（SRC-001）。\n",
            encoding="utf-8",
        )

        exit_code = check_evidence.run(None, fail_on_error=True, require_sections=True)
        payload = json.loads(
            (self.audits_dir / "programmatic_check.json").read_text(encoding="utf-8")
        )
        issues = payload["chapters"][0]["issues"]

        self.assertEqual(exit_code, 0)
        self.assertEqual({issue["rule"] for issue in issues}, {"S6"})
        self.assertTrue(all(issue["severity"] == "warning" for issue in issues))

    def test_rough_decision_does_not_force_expectation_gap_after_rejection(self) -> None:
        self.search_log.write_text("## SRC-001\n", encoding="utf-8")
        (self.sections_dir / "09_research_decision.md").write_text(
            "# 九、是否值得继续深研与待验证问题\n\n"
            "研究结论：排除。观察池触发价暂未获取。营业收入为 10 亿元（SRC-001）。\n",
            encoding="utf-8",
        )

        exit_code = check_evidence.run(None, fail_on_error=True, require_sections=True)
        payload = json.loads(
            (self.audits_dir / "programmatic_check.json").read_text(encoding="utf-8")
        )

        self.assertEqual(exit_code, 0)
        self.assertEqual(payload["chapters"][0]["issues"], [])

    def test_rough_decision_does_not_match_negated_deep_research_phrase(self) -> None:
        self.search_log.write_text("## SRC-001\n", encoding="utf-8")
        (self.sections_dir / "09_research_decision.md").write_text(
            "# 九、是否值得继续深研与待验证问题\n\n"
            "研究结论：排除，未达到进入深研标准。营业收入为 10 亿元（SRC-001）。\n",
            encoding="utf-8",
        )

        exit_code = check_evidence.run(None, fail_on_error=True, require_sections=True)
        payload = json.loads(
            (self.audits_dir / "programmatic_check.json").read_text(encoding="utf-8")
        )

        self.assertEqual(exit_code, 0)
        self.assertEqual(payload["chapters"][0]["issues"], [])

    def test_rough_decision_warns_when_active_gate_lacks_expectation_gap(self) -> None:
        self.search_log.write_text("## SRC-001\n", encoding="utf-8")
        (self.sections_dir / "09_research_decision.md").write_text(
            "# 九、是否值得继续深研与待验证问题\n\n研究结论：观察池。营业收入为 10 亿元（SRC-001）。\n",
            encoding="utf-8",
        )

        exit_code = check_evidence.run(None, fail_on_error=True, require_sections=True)
        payload = json.loads(
            (self.audits_dir / "programmatic_check.json").read_text(encoding="utf-8")
        )
        issues = payload["chapters"][0]["issues"]

        self.assertEqual(exit_code, 0)
        self.assertEqual({issue["rule"] for issue in issues}, {"S6"})

    def test_overview_warns_when_active_gate_lacks_expectation_gap(self) -> None:
        self.search_log.write_text("## SRC-001\n", encoding="utf-8")
        (self.sections_dir / "00_overview.md").write_text(
            "# 一页纸粗读闸门\n\n初步结论：进入深研。营业收入为 10 亿元（SRC-001）。\n",
            encoding="utf-8",
        )

        exit_code = check_evidence.run(None, fail_on_error=True, require_sections=True)
        payload = json.loads(
            (self.audits_dir / "programmatic_check.json").read_text(encoding="utf-8")
        )
        issues = payload["chapters"][0]["issues"]

        self.assertEqual(exit_code, 0)
        self.assertEqual({issue["rule"] for issue in issues}, {"S6"})

    def test_overview_expectation_gap_does_not_require_decision_split(self) -> None:
        self.search_log.write_text("## SRC-001\n", encoding="utf-8")
        (self.sections_dir / "00_overview.md").write_text(
            "# 一页纸粗读闸门\n\n"
            "初步结论：观察池。营业收入为 10 亿元（SRC-001）。\n\n"
            "| 市场隐含预期 | 我方预期 | 证据锚点 | 差异方向 | 验证日期 | 先行指标 | 上行失效条件 | 下行失效条件 |\n"
            "|---|---|---|---|---|---|---|---|\n"
            "| 暂未获取 | 暂无可证伪预期差 | SRC-001 | 暂未判断 | 2026-08-17 | 收入 | 收入不达预期 | 估值不降 |\n",
            encoding="utf-8",
        )

        exit_code = check_evidence.run(None, fail_on_error=True, require_sections=True)
        payload = json.loads(
            (self.audits_dir / "programmatic_check.json").read_text(encoding="utf-8")
        )

        self.assertEqual(exit_code, 0)
        self.assertEqual(payload["chapters"][0]["issues"], [])


if __name__ == "__main__":
    unittest.main()
