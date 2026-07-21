from __future__ import annotations

import io
import json
import sys
import tempfile
import unittest
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(PROJECT_ROOT / "scripts"))

import merge  # noqa: E402
import verify_pipeline  # noqa: E402
from pipeline_common import merge_section_texts, sha256_file, sha256_text  # noqa: E402


class PipelineFixture:
    def __init__(self, root: Path) -> None:
        self.root = root
        self.output = root / "output"
        self.sections = self.output / "sections"
        self.audits = self.output / "audits"
        (root / "input").mkdir(parents=True)
        self.sections.mkdir(parents=True)
        self.audits.mkdir(parents=True)
        (root / "input" / "company.md").write_text(
            "\n".join(
                (
                    "- 公司中文名：示例公司",
                    "- 证券代码：000001.SZ",
                    "- 报告模式：short",
                    "- 数据截至日期：2026-07-21",
                )
            )
            + "\n",
            encoding="utf-8",
        )
        self.search_log = self.output / "web_search_log.md"
        self.facts = self.output / "facts.md"
        self.facets = self.output / "company_facets.md"
        self.search_log.write_text("## SRC-001\n- 标题：示例来源\n", encoding="utf-8")
        self.facts.write_text("| F001 | 营业收入 | 10 | 亿元 | SRC-001 |\n", encoding="utf-8")
        self.facets.write_text("# 公司画像\n\n- 研究模式：short\n", encoding="utf-8")
        self.section_ids = verify_pipeline.expected_section_ids(
            "short",
            with_decision=False,
            with_overview=False,
        )

    def build(self) -> dict[str, object]:
        section_states: dict[str, object] = {}
        programmatic_chapters: list[dict[str, object]] = []
        section_paths: list[Path] = []
        for section_id in self.section_ids:
            section_path = self.sections / f"{section_id}.md"
            section_path.write_text(
                f"# {section_id}\n\n营业收入为 10 亿元（SRC-001）。\n",
                encoding="utf-8",
            )
            section_paths.append(section_path)
            content_hash = sha256_file(section_path)
            audit_path = self.audits / f"{section_id}.audit.json"
            audit_path.write_text(
                json.dumps(
                    {
                        "chapter": section_id,
                        "category": "ok",
                        "violations": [],
                    },
                    ensure_ascii=False,
                ),
                encoding="utf-8",
            )
            section_states[section_id] = {
                "status": "generated",
                "content_hash": content_hash,
                "audit_status": "passed",
                "audited_content_hash": content_hash,
                "repair_attempts": 0,
                "audit_files": [f"output/audits/{section_id}.audit.json"],
            }
            programmatic_chapters.append(
                {
                    "chapter": section_id,
                    "checked_at": "2026-07-21T00:00:00+00:00",
                    "content_hash": content_hash,
                    "issues": [],
                }
            )

        programmatic = {
            "version": "1.1",
            "generated_at": "2026-07-21T00:00:00+00:00",
            "source_log_hash": sha256_file(self.search_log),
            "chapters": programmatic_chapters,
        }
        (self.audits / "programmatic_check.json").write_text(
            json.dumps(programmatic, ensure_ascii=False, indent=2),
            encoding="utf-8",
        )
        final_path = self.audits / "final_consistency.audit.json"
        final_path.write_text(
            json.dumps({"category": "ok", "violations": []}, ensure_ascii=False),
            encoding="utf-8",
        )
        manifest: dict[str, object] = {
            "report_mode": "short",
            "workflow_mode": "full",
            "run_status": "completed",
            "blocked_reason": None,
            "with_decision": False,
            "with_overview": False,
            "data_as_of": "2026-07-21",
            "source_log_hash": sha256_file(self.search_log),
            "facts_hash": sha256_file(self.facts),
            "company_facets_hash": sha256_file(self.facets),
            "sections": section_states,
            "final_audit": {
                "status": "passed",
                "sections_hash": sha256_text(merge_section_texts(section_paths)),
                "audit_file": "output/audits/final_consistency.audit.json",
            },
        }
        (self.output / "manifest.json").write_text(
            json.dumps(manifest, ensure_ascii=False, indent=2),
            encoding="utf-8",
        )
        return manifest

    def write_manifest(self, manifest: dict[str, object]) -> None:
        (self.output / "manifest.json").write_text(
            json.dumps(manifest, ensure_ascii=False, indent=2),
            encoding="utf-8",
        )

    def read_programmatic(self) -> dict[str, object]:
        return json.loads(
            (self.audits / "programmatic_check.json").read_text(encoding="utf-8")
        )

    def write_programmatic(self, payload: dict[str, object]) -> None:
        (self.audits / "programmatic_check.json").write_text(
            json.dumps(payload, ensure_ascii=False, indent=2),
            encoding="utf-8",
        )

    def make_fast(self, manifest: dict[str, object]) -> None:
        manifest["workflow_mode"] = "fast"
        sections = manifest["sections"]
        assert isinstance(sections, dict)
        for state in sections.values():
            assert isinstance(state, dict)
            state["audit_status"] = "not_run"
            state["audit_files"] = []
            state.pop("audited_content_hash", None)
        manifest["final_audit"] = {"status": "not_run"}
        for audit_path in self.audits.glob("*.audit.json"):
            audit_path.unlink()
        self.write_manifest(manifest)


class VerifyPipelineTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp_dir = tempfile.TemporaryDirectory()
        self.root = Path(self.temp_dir.name)
        self.fixture = PipelineFixture(self.root)
        self.manifest = self.fixture.build()

    def tearDown(self) -> None:
        self.temp_dir.cleanup()

    def test_valid_full_pipeline_passes(self) -> None:
        result = verify_pipeline.validate_pipeline(self.root)

        self.assertTrue(result.ok)
        self.assertEqual(result.bypassed, ())

    def test_missing_expected_section_fails(self) -> None:
        (self.fixture.sections / "03_financials.md").unlink()

        result = verify_pipeline.validate_pipeline(self.root)

        self.assertFalse(result.ok)
        self.assertIn("SECTION_MISSING", {issue.code for issue in result.errors})

    def test_empty_expected_section_fails(self) -> None:
        (self.fixture.sections / "03_financials.md").write_text("", encoding="utf-8")

        result = verify_pipeline.validate_pipeline(self.root)

        self.assertFalse(result.ok)
        self.assertIn("SECTION_EMPTY", {issue.code for issue in result.errors})

    def test_invalid_workflow_mode_fails_closed(self) -> None:
        self.manifest["workflow_mode"] = "full "
        self.fixture.write_manifest(self.manifest)

        result = verify_pipeline.validate_pipeline(self.root)

        self.assertFalse(result.ok)
        self.assertIn("WORKFLOW_MODE", {issue.code for issue in result.errors})

    def test_force_only_bypasses_explicit_failed_audit(self) -> None:
        sections = self.manifest["sections"]
        assert isinstance(sections, dict)
        state = sections["03_financials"]
        assert isinstance(state, dict)
        state["audit_status"] = "failed"
        self.fixture.write_manifest(self.manifest)

        normal = verify_pipeline.validate_pipeline(self.root)
        forced = verify_pipeline.validate_pipeline(self.root, force=True)

        self.assertFalse(normal.ok)
        self.assertTrue(forced.ok)
        self.assertEqual([issue.code for issue in forced.bypassed], ["AUDIT_FAILED"])

    def test_force_requires_failed_audit_artifact(self) -> None:
        sections = self.manifest["sections"]
        assert isinstance(sections, dict)
        state = sections["03_financials"]
        assert isinstance(state, dict)
        state["audit_status"] = "failed"
        (self.fixture.audits / "03_financials.audit.json").unlink()
        self.fixture.write_manifest(self.manifest)

        forced = verify_pipeline.validate_pipeline(self.root, force=True)

        self.assertFalse(forced.ok)
        self.assertIn("AUDIT_INVALID", {issue.code for issue in forced.errors})

    def test_force_does_not_bypass_stale_section_hashes(self) -> None:
        (self.fixture.sections / "03_financials.md").write_text(
            "# changed\n\n营业收入为 11 亿元（SRC-001）。\n",
            encoding="utf-8",
        )

        result = verify_pipeline.validate_pipeline(self.root, force=True)

        self.assertFalse(result.ok)
        codes = {issue.code for issue in result.errors}
        self.assertIn("SECTION_HASH", codes)
        self.assertIn("PROGRAMMATIC_STALE", codes)
        self.assertIn("FINAL_AUDIT_STALE", codes)

    def test_fast_mode_passes_without_llm_audit_artifacts(self) -> None:
        self.fixture.make_fast(self.manifest)

        result = verify_pipeline.validate_pipeline(self.root)

        self.assertTrue(result.ok)

    def test_fast_mode_still_blocks_programmatic_errors(self) -> None:
        self.fixture.make_fast(self.manifest)
        programmatic = self.fixture.read_programmatic()
        chapters = programmatic["chapters"]
        assert isinstance(chapters, list)
        first = chapters[0]
        assert isinstance(first, dict)
        first["issues"] = [{"severity": "error", "rule": "E1"}]
        self.fixture.write_programmatic(programmatic)

        result = verify_pipeline.validate_pipeline(self.root)

        self.assertFalse(result.ok)
        self.assertIn("PROGRAMMATIC_ERROR", {issue.code for issue in result.errors})

    def test_source_change_invalidates_manifest_and_programmatic_hashes(self) -> None:
        self.fixture.search_log.write_text(
            self.fixture.search_log.read_text(encoding="utf-8") + "- 更新：是\n",
            encoding="utf-8",
        )

        result = verify_pipeline.validate_pipeline(self.root)

        self.assertFalse(result.ok)
        codes = {issue.code for issue in result.errors}
        self.assertIn("HASH_MISMATCH", codes)
        self.assertIn("PROGRAMMATIC_STALE", codes)

    def test_running_manifest_cannot_merge(self) -> None:
        self.manifest["run_status"] = "running"
        self.fixture.write_manifest(self.manifest)

        result = verify_pipeline.validate_pipeline(self.root)

        self.assertFalse(result.ok)
        self.assertIn("RUN_STATUS", {issue.code for issue in result.errors})

    def test_input_mode_must_match_manifest(self) -> None:
        company_file = self.root / "input" / "company.md"
        company_file.write_text(
            company_file.read_text(encoding="utf-8").replace(
                "- 报告模式：short",
                "- 报告模式：deep",
            ),
            encoding="utf-8",
        )

        result = verify_pipeline.validate_pipeline(self.root)

        self.assertFalse(result.ok)
        self.assertIn("INPUT_MODE", {issue.code for issue in result.errors})

    def test_malformed_manifest_cannot_merge(self) -> None:
        (self.fixture.output / "manifest.json").write_text("{broken", encoding="utf-8")

        result = verify_pipeline.validate_pipeline(self.root)

        self.assertFalse(result.ok)
        self.assertIn("MANIFEST_INVALID", {issue.code for issue in result.errors})

    def test_merge_returns_failure_without_pipeline_state(self) -> None:
        empty_root = self.root / "empty"
        empty_root.mkdir()
        stdout = io.StringIO()
        stderr = io.StringIO()

        with redirect_stdout(stdout), redirect_stderr(stderr):
            merged = merge.run_merge(root=empty_root)

        self.assertFalse(merged)
        self.assertFalse((empty_root / "output" / "research_report.md").exists())

    def test_merge_writes_report_after_gate_passes(self) -> None:
        summary_file = self.fixture.audits / "audit_summary.md"
        summary_file.write_text("# 旧审计附录\n", encoding="utf-8")
        (self.fixture.audits / "04_stale.audit.json").write_text(
            json.dumps(
                {
                    "chapter": "04_stale",
                    "category": "content_violation",
                    "violations": [{"rule": "C1"}],
                },
                ensure_ascii=False,
            ),
            encoding="utf-8",
        )
        stdout = io.StringIO()
        stderr = io.StringIO()

        with redirect_stdout(stdout), redirect_stderr(stderr):
            merged = merge.run_merge(root=self.root)

        report = self.fixture.output / "research_report.md"
        self.assertTrue(merged, msg=stderr.getvalue())
        self.assertTrue(report.is_file())
        self.assertTrue(summary_file.is_file())
        report_text = report.read_text(encoding="utf-8")
        summary_text = summary_file.read_text(encoding="utf-8")
        self.assertIn("# 示例公司 公司调研报告", report_text)
        self.assertNotIn("旧审计附录", report_text)
        self.assertNotIn("04_stale", summary_text)


if __name__ == "__main__":
    unittest.main()
