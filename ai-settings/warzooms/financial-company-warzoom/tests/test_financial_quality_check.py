from __future__ import annotations

import io
import json
import shutil
import sys
import unittest
import uuid
from contextlib import redirect_stdout
from pathlib import Path
from unittest.mock import patch

PROJECT_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(PROJECT_ROOT / "scripts"))

import financial_quality_check  # noqa: E402


class FinancialQualityCheckTests(unittest.TestCase):
    def scratch_dir(self) -> Path:
        root = PROJECT_ROOT / "tests" / ".scratch" / f"financial_quality_{uuid.uuid4().hex}"
        root.mkdir(parents=True)
        self.addCleanup(lambda: shutil.rmtree(root, ignore_errors=True))
        return root

    def test_grade_a_when_core_and_dso_checks_are_clean(self) -> None:
        payload = {
            "company": "示例公司",
            "currency": "CNY",
            "unit": "亿元",
            "periods": [
                {"period": "2025", "net_income": 90, "operating_cash_flow": 95, "total_assets": 900, "revenue": 450, "dso": 60},
                {"period": "2026", "net_income": 100, "operating_cash_flow": 110, "total_assets": 1000, "revenue": 500, "dso": 58},
            ],
        }

        result = financial_quality_check.evaluate(payload)

        self.assertEqual(result["grade"]["level"], "A")
        self.assertEqual(result["period"], "2026")
        self.assertEqual(result["missing_fields"], [])
        checks = {item["id"]: item for item in result["checks"]}
        self.assertAlmostEqual(checks["cash_conversion"]["value"], 1.1)
        self.assertLessEqual(checks["accrual_ratio"]["value"], 0)

    def test_high_accrual_and_weak_cash_conversion_drive_d_grade(self) -> None:
        payload = {
            "periods": [
                {"period": "2025", "total_assets": 800, "revenue": 500, "dso": 45},
                {
                    "period": "2026",
                    "net_income": 120,
                    "operating_cash_flow": 20,
                    "total_assets": 900,
                    "revenue": 480,
                    "dso": 80,
                },
            ]
        }

        result = financial_quality_check.evaluate(payload)

        self.assertEqual(result["grade"]["level"], "D")
        statuses = {item["id"]: item["status"] for item in result["checks"]}
        self.assertEqual(statuses["accrual_ratio"], "high_risk")
        self.assertEqual(statuses["cash_conversion"], "high_risk")
        self.assertEqual(statuses["dso_revenue_divergence"], "high_risk")

    def test_missing_fields_are_structured_without_guessing(self) -> None:
        payload = {"periods": [{"period": "2026", "net_income": 100}]}

        result = financial_quality_check.evaluate(payload)

        self.assertEqual(result["grade"]["level"], "D")
        missing_by_check = {item["check_id"]: item for item in result["missing_fields"]}
        self.assertIn("accrual_ratio", missing_by_check)
        self.assertIn("cash_conversion", missing_by_check)
        self.assertIn("operating_cash_flow", missing_by_check["cash_conversion"]["missing"])
        self.assertIn("previous.total_assets", missing_by_check["accrual_ratio"]["missing"])

    def test_dso_can_be_derived_only_with_explicit_days_in_period(self) -> None:
        payload = {
            "periods": [
                {"period": "2025", "net_income": 90, "operating_cash_flow": 90, "total_assets": 900, "revenue": 400, "accounts_receivable": 60},
                {"period": "2026", "net_income": 100, "operating_cash_flow": 105, "total_assets": 1000, "revenue": 500, "accounts_receivable": 80},
            ]
        }

        result = financial_quality_check.evaluate(payload)

        dso_check = next(item for item in result["checks"] if item["id"] == "dso_revenue_divergence")
        self.assertEqual(dso_check["status"], "not_calculated")
        missing = next(item for item in result["missing_fields"] if item["check_id"] == "dso_revenue_divergence")
        self.assertIn("days_in_period", missing["missing"])
        self.assertIn("previous.days_in_period", missing["missing"])

    def test_invalid_numeric_field_returns_json_error_from_cli(self) -> None:
        root = self.scratch_dir()
        input_file = root / "input.json"
        input_file.write_text(
            json.dumps({"periods": [{"period": "2026", "net_income": "100"}]}, ensure_ascii=False),
            encoding="utf-8",
        )
        stdout = io.StringIO()

        with redirect_stdout(stdout):
            exit_code = financial_quality_check.run(["--input", str(input_file)])

        payload = json.loads(stdout.getvalue())
        self.assertEqual(exit_code, 2)
        self.assertEqual(payload["errors"][0]["code"], "INVALID_FIELD_TYPE")
        self.assertEqual(payload["grade"]["level"], "D")

    def test_cli_accepts_stdin_and_outputs_json(self) -> None:
        stdin = io.StringIO(json.dumps({"periods": [{"period": "2026", "net_income": 100}]}))
        stdout = io.StringIO()

        with patch("sys.stdin", stdin), redirect_stdout(stdout):
            exit_code = financial_quality_check.run([])

        self.assertEqual(exit_code, 0)
        payload = json.loads(stdout.getvalue())
        self.assertEqual(payload["version"], "1.0")

    def test_negative_profit_uses_loss_making_interpretation_not_positive_profit_thresholds(self) -> None:
        payload = {
            "periods": [
                {"period": "2025", "total_assets": 1000, "revenue": 480, "dso": 50},
                {
                    "period": "2026",
                    "net_income": -100,
                    "operating_cash_flow": -20,
                    "total_assets": 1000,
                    "revenue": 500,
                    "dso": 52,
                },
            ]
        }

        result = financial_quality_check.evaluate(payload)

        cash = next(item for item in result["checks"] if item["id"] == "cash_conversion")
        self.assertEqual(cash["status"], "high_risk")
        self.assertIsNone(cash["value"])
        self.assertIn("净亏损", cash["interpretation"])
        self.assertNotIn("覆盖较好", cash["interpretation"])

    def test_zero_denominators_do_not_abort_other_checks(self) -> None:
        payload = {
            "periods": [
                {"period": "2025", "total_assets": 0, "revenue": 0, "dso": 0},
                {
                    "period": "2026",
                    "net_income": 0,
                    "operating_cash_flow": 10,
                    "total_assets": 0,
                    "revenue": 0,
                    "dso": 25,
                },
            ]
        }

        result = financial_quality_check.evaluate(payload)

        self.assertEqual(result["errors"], [])
        checks = {item["id"]: item for item in result["checks"]}
        self.assertEqual(checks["accrual_ratio"]["status"], "not_calculated")
        self.assertEqual(checks["cash_conversion"]["status"], "not_calculated")
        self.assertEqual(checks["dso_revenue_divergence"]["status"], "not_calculated")
        self.assertIn("平均总资产为 0", checks["accrual_ratio"]["interpretation"])
        self.assertIn("净利润为 0", checks["cash_conversion"]["interpretation"])
        self.assertIn("上一期收入为 0", checks["dso_revenue_divergence"]["interpretation"])

    def test_explicit_optional_fields_path_allows_zero_revenue_data(self) -> None:
        payload = {
            "periods": [
                {"period": "2025", "total_assets": 1000, "revenue": 0, "dso": 0},
                {
                    "period": "2026",
                    "net_income": 10,
                    "operating_cash_flow": 12,
                    "total_assets": 1000,
                    "revenue": 0,
                    "dso": 8,
                    "revenue_growth": 0.5,
                },
            ]
        }

        result = financial_quality_check.evaluate(payload)

        dso_check = next(item for item in result["checks"] if item["id"] == "dso_revenue_divergence")
        self.assertEqual(dso_check["status"], "ok")
        self.assertEqual(dso_check["fields_used"], ["dso", "previous.dso", "revenue_growth"])
        self.assertNotIn("dso_revenue_divergence", {item["check_id"] for item in result["missing_fields"]})

    def test_dso_warning_when_previous_dso_is_zero_and_current_rises(self) -> None:
        payload = {
            "periods": [
                {"period": "2025", "total_assets": 1000, "revenue": 100, "dso": 0},
                {
                    "period": "2026",
                    "net_income": 10,
                    "operating_cash_flow": 12,
                    "total_assets": 1000,
                    "revenue": 110,
                    "dso": 12,
                },
            ]
        }

        result = financial_quality_check.evaluate(payload)

        dso_check = next(item for item in result["checks"] if item["id"] == "dso_revenue_divergence")
        self.assertEqual(dso_check["status"], "warning")
        self.assertIn("上期 DSO 为 0", dso_check["interpretation"])


if __name__ == "__main__":
    unittest.main()
