from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(PROJECT_ROOT / "scripts"))

import industry_rules  # noqa: E402


class IndustryRulesTests(unittest.TestCase):
    def test_default_rule_package_is_valid_and_covers_initial_industries(self) -> None:
        package = industry_rules.load_rule_package(PROJECT_ROOT / "data" / "industry_rules.json")

        self.assertEqual(package.version, "1.0")
        self.assertEqual(
            {rule.id for rule in package.rules},
            {
                "software_subscription",
                "semiconductor",
                "bank",
                "consumer",
                "resource_extraction",
                "heavy_asset_production",
            },
        )
        for rule in package.rules:
            self.assertTrue(rule.business_model_tags)
            self.assertTrue(rule.required_kpi_groups)
            self.assertTrue(rule.preferred_valuation_methods)
            self.assertTrue(rule.key_risks)
            self.assertTrue(rule.required_conclusions)

    def test_select_rules_matches_one_to_three_rules_and_unknown_degrades_empty(self) -> None:
        package = industry_rules.load_rule_package(PROJECT_ROOT / "data" / "industry_rules.json")

        selected = industry_rules.select_rules_for_tags(package, ["软件订阅", "半导体", "银行", "其它"])
        unknown = industry_rules.select_rules_for_tags(package, ["其它"])

        self.assertEqual([rule.id for rule in selected], ["software_subscription", "semiconductor", "bank"])
        self.assertEqual(unknown, ())

    def test_validate_rejects_invalid_schema(self) -> None:
        with self.assertRaises(industry_rules.IndustryRuleError):
            industry_rules.validate_rule_package(json.loads('{"version":"1.0","rules":[]}'))


if __name__ == "__main__":
    unittest.main()
