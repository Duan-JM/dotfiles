#!/usr/bin/env python3
"""行业规则包加载、校验与匹配。

规则包是机器可检查的 JSON 文件，仅使用标准库读取与 schema 校验。它服务两类场景：

1. ``infer`` 阶段根据 ``business_model_tags`` 选择 1-3 条行业规则；
2. ``check_evidence`` 阶段按已选择规则检查章节是否覆盖必备 KPI 语义组。
"""

from __future__ import annotations

import json
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_RULES_FILE = ROOT / "data" / "industry_rules.json"

_RULE_ID = re.compile(r"^[a-z][a-z0-9_]*$")
_CHAPTER_ID = re.compile(r"^(?:0[0-9]|1[0-9])_[a-z0-9_]+$")


class IndustryRuleError(ValueError):
    """行业规则包 schema 校验失败。"""


@dataclass(frozen=True)
class KpiGroup:
    """必备 KPI 语义组。"""

    id: str
    name: str
    description: str
    aliases: tuple[str, ...]
    required_in_chapters: tuple[str, ...]


@dataclass(frozen=True)
class IndustryRule:
    """单条行业规则。"""

    id: str
    name: str
    business_model_tags: tuple[str, ...]
    required_kpi_groups: tuple[KpiGroup, ...]
    preferred_valuation_methods: tuple[str, ...]
    key_risks: tuple[str, ...]
    required_conclusions: tuple[str, ...]


@dataclass(frozen=True)
class IndustryRulePackage:
    """行业规则包。"""

    version: str
    rules: tuple[IndustryRule, ...]


def _expect_dict(value: Any, path: str) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise IndustryRuleError(f"{path} 必须是 object")
    return value


def _expect_non_empty_string(value: Any, path: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise IndustryRuleError(f"{path} 必须是非空字符串")
    return value.strip()


def _expect_string_list(value: Any, path: str, *, min_items: int = 1) -> tuple[str, ...]:
    if not isinstance(value, list):
        raise IndustryRuleError(f"{path} 必须是 array")
    if len(value) < min_items:
        raise IndustryRuleError(f"{path} 至少需要 {min_items} 项")
    items: list[str] = []
    for index, item in enumerate(value):
        items.append(_expect_non_empty_string(item, f"{path}[{index}]"))
    if len(set(items)) != len(items):
        raise IndustryRuleError(f"{path} 不允许重复项")
    return tuple(items)


def _parse_kpi_group(value: Any, path: str) -> KpiGroup:
    group = _expect_dict(value, path)
    group_id = _expect_non_empty_string(group.get("id"), f"{path}.id")
    if not _RULE_ID.match(group_id):
        raise IndustryRuleError(f"{path}.id 只能使用小写字母、数字和下划线，且以字母开头")
    chapters = _expect_string_list(group.get("required_in_chapters"), f"{path}.required_in_chapters")
    for chapter in chapters:
        if not _CHAPTER_ID.match(chapter):
            raise IndustryRuleError(f"{path}.required_in_chapters 包含非法章节 ID：{chapter}")
    return KpiGroup(
        id=group_id,
        name=_expect_non_empty_string(group.get("name"), f"{path}.name"),
        description=_expect_non_empty_string(group.get("description"), f"{path}.description"),
        aliases=_expect_string_list(group.get("aliases"), f"{path}.aliases"),
        required_in_chapters=chapters,
    )


def _parse_rule(value: Any, path: str) -> IndustryRule:
    rule = _expect_dict(value, path)
    rule_id = _expect_non_empty_string(rule.get("id"), f"{path}.id")
    if not _RULE_ID.match(rule_id):
        raise IndustryRuleError(f"{path}.id 只能使用小写字母、数字和下划线，且以字母开头")
    kpi_values = rule.get("required_kpi_groups")
    if not isinstance(kpi_values, list) or not kpi_values:
        raise IndustryRuleError(f"{path}.required_kpi_groups 必须是非空 array")
    kpi_groups = tuple(_parse_kpi_group(item, f"{path}.required_kpi_groups[{index}]") for index, item in enumerate(kpi_values))
    kpi_ids = [group.id for group in kpi_groups]
    if len(set(kpi_ids)) != len(kpi_ids):
        raise IndustryRuleError(f"{path}.required_kpi_groups 不允许重复 id")
    return IndustryRule(
        id=rule_id,
        name=_expect_non_empty_string(rule.get("name"), f"{path}.name"),
        business_model_tags=_expect_string_list(rule.get("business_model_tags"), f"{path}.business_model_tags"),
        required_kpi_groups=kpi_groups,
        preferred_valuation_methods=_expect_string_list(
            rule.get("preferred_valuation_methods"),
            f"{path}.preferred_valuation_methods",
        ),
        key_risks=_expect_string_list(rule.get("key_risks"), f"{path}.key_risks"),
        required_conclusions=_expect_string_list(rule.get("required_conclusions"), f"{path}.required_conclusions"),
    )


def validate_rule_package(payload: Any) -> IndustryRulePackage:
    """校验并转换行业规则包 JSON。

    Args:
        payload: ``json.loads`` 后的对象。

    Returns:
        结构化规则包。

    Raises:
        IndustryRuleError: schema 不合法。
    """

    root = _expect_dict(payload, "$")
    version = _expect_non_empty_string(root.get("version"), "$.version")
    raw_rules = root.get("rules")
    if not isinstance(raw_rules, list) or not raw_rules:
        raise IndustryRuleError("$.rules 必须是非空 array")
    rules = tuple(_parse_rule(item, f"$.rules[{index}]") for index, item in enumerate(raw_rules))
    rule_ids = [rule.id for rule in rules]
    if len(set(rule_ids)) != len(rule_ids):
        raise IndustryRuleError("$.rules 不允许重复 id")
    return IndustryRulePackage(version=version, rules=rules)


def load_rule_package(path: Path = DEFAULT_RULES_FILE) -> IndustryRulePackage:
    """从 JSON 文件加载并校验行业规则包。"""

    return validate_rule_package(json.loads(path.read_text(encoding="utf-8")))


def select_rules_for_tags(
    package: IndustryRulePackage,
    business_model_tags: Iterable[str],
    *,
    max_rules: int = 3,
) -> tuple[IndustryRule, ...]:
    """按 ``business_model_tags`` 匹配 1-3 条规则；未知 / 混合行业安全降级为空。

    匹配逻辑保持确定性：按规则包顺序选择，只要规则的任一
    ``business_model_tags`` 被公司标签命中即入选。
    """

    normalized_tags = {tag.strip() for tag in business_model_tags if tag and tag.strip()}
    if not normalized_tags:
        return ()
    selected: list[IndustryRule] = []
    for rule in package.rules:
        if normalized_tags.intersection(rule.business_model_tags):
            selected.append(rule)
        if len(selected) >= max_rules:
            break
    return tuple(selected)


def find_rules_by_id(package: IndustryRulePackage, rule_ids: Iterable[str]) -> tuple[IndustryRule, ...]:
    """按 ID 取规则；未知 ID 忽略以支持旧文件与安全降级。"""

    index = {rule.id: rule for rule in package.rules}
    selected: list[IndustryRule] = []
    for rule_id in rule_ids:
        rule = index.get(rule_id)
        if rule is not None and rule not in selected:
            selected.append(rule)
        if len(selected) >= 3:
            break
    return tuple(selected)

