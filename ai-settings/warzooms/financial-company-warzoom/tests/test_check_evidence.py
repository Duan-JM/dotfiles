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


if __name__ == "__main__":
    unittest.main()
