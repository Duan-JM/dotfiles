from __future__ import annotations

import io
import json
import sys
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from unittest.mock import patch

PROJECT_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(PROJECT_ROOT / "scripts"))

import valuation_calculator  # noqa: E402


class ValuationCalculatorTests(unittest.TestCase):
    def test_calculates_rough_gate_metrics_from_complete_input(self) -> None:
        payload = {
            "currency": "人民币",
            "unit": "亿元",
            "price": 10,
            "shares_outstanding": 100,
            "total_debt": 300,
            "cash_and_equivalents": 120,
            "short_term_investments": 20,
            "book_equity": 500,
            "ebit": 80,
            "ebitda": 100,
            "free_cash_flow": 50,
            "dividends": 20,
            "buybacks": 10,
            "sbc": 3,
            "issuance_dilution": 2,
        }

        result = valuation_calculator.calculate_valuation(payload)
        metrics = result["metrics"]

        self.assertEqual(result["status"], "ok")
        self.assertEqual(metrics["market_cap"]["value"], 1000)
        self.assertEqual(metrics["enterprise_value"]["value"], 1160)
        self.assertEqual(metrics["net_debt"]["value"], 160)
        self.assertEqual(metrics["pb"]["value"], 2)
        self.assertAlmostEqual(metrics["ev_ebit"]["value"], 14.5)
        self.assertAlmostEqual(metrics["ev_ebitda"]["value"], 11.6)
        self.assertAlmostEqual(metrics["fcf_yield"]["value"], 0.05)
        self.assertAlmostEqual(metrics["net_shareholder_return"]["value"], 0.025)

    def test_net_buybacks_alias_is_supported(self) -> None:
        result = valuation_calculator.calculate_valuation(
            {
                "market_cap": 100,
                "total_debt": 0,
                "cash_and_equivalents": 0,
                "dividends": 1,
                "net_buybacks": 2,
                "sbc": 0,
                "issuance_dilution": 0,
            }
        )

        metric = result["metrics"]["net_shareholder_return"]
        self.assertEqual(metric["status"], "available")
        self.assertAlmostEqual(metric["value"], 0.03)
        self.assertIn("net_buybacks", metric["inputs"])

    def test_missing_fields_are_unavailable_not_fabricated(self) -> None:
        result = valuation_calculator.calculate_valuation(
            {
                "market_cap": 100,
                "total_debt": 0,
                "cash_and_equivalents": 20,
            }
        )

        metrics = result["metrics"]
        self.assertEqual(metrics["market_cap"]["status"], "available")
        self.assertEqual(metrics["pb"]["status"], "unavailable")
        self.assertEqual(metrics["pb"]["missing"], ["book_equity"])
        self.assertEqual(metrics["ev_ebit"]["status"], "unavailable")
        self.assertEqual(metrics["fcf_yield"]["status"], "unavailable")
        self.assertIsNone(metrics["pb"]["value"])

    def test_rejects_non_positive_share_count(self) -> None:
        with self.assertRaisesRegex(valuation_calculator.ValuationInputError, "shares_outstanding"):
            valuation_calculator.calculate_valuation({"price": 10, "shares_outstanding": 0})

    def test_rejects_wacc_not_above_terminal_growth(self) -> None:
        payload = {
            "market_cap": 100,
            "total_debt": 0,
            "cash_and_equivalents": 0,
            "free_cash_flow": 10,
            "reverse_dcf": {"wacc": 0.03, "terminal_g": 0.03},
        }

        with self.assertRaisesRegex(valuation_calculator.ValuationInputError, "wacc"):
            valuation_calculator.calculate_valuation(payload)

    def test_reverse_dcf_returns_required_growth(self) -> None:
        result = valuation_calculator.calculate_valuation(
            {
                "market_cap": 120,
                "total_debt": 0,
                "cash_and_equivalents": 0,
                "free_cash_flow": 10,
                "reverse_dcf": {
                    "wacc": 0.10,
                    "terminal_g": 0.02,
                    "projection_years": 5,
                },
            }
        )

        self.assertEqual(result["reverse_dcf"]["status"], "available")
        self.assertGreater(result["reverse_dcf"]["required_fcf_cagr"], -0.1)
        self.assertLess(result["reverse_dcf"]["required_fcf_cagr"], 0.1)

    def test_cli_reads_stdin_and_writes_error_json(self) -> None:
        stdin = io.StringIO(json.dumps({"price": 10, "shares_outstanding": -1}))
        stdout = io.StringIO()

        with patch("sys.stdin", stdin), redirect_stdout(stdout):
            exit_code = valuation_calculator.run([])

        payload = json.loads(stdout.getvalue())
        self.assertEqual(exit_code, 1)
        self.assertEqual(payload["status"], "error")
        self.assertIn("shares_outstanding", payload["error"]["message"])


if __name__ == "__main__":
    unittest.main()
