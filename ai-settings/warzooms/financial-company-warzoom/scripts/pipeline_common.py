#!/usr/bin/env python3
"""流水线脚本共享的哈希与章节拼接工具。"""

from __future__ import annotations

import hashlib
from pathlib import Path
from typing import Iterable


def sha256_bytes(data: bytes) -> str:
    """返回带算法前缀的 SHA-256。"""

    return f"sha256:{hashlib.sha256(data).hexdigest()}"


def sha256_text(text: str) -> str:
    """按 UTF-8 编码计算文本 SHA-256。"""

    return sha256_bytes(text.encode("utf-8"))


def sha256_file(path: Path) -> str:
    """计算文件原始字节的 SHA-256。"""

    return sha256_bytes(path.read_bytes())


def merge_section_texts(section_files: Iterable[Path]) -> str:
    """按给定顺序拼接非空章节，格式与 final_audit prompt 一致。"""

    parts = [
        content
        for path in section_files
        if (content := path.read_text(encoding="utf-8").strip())
    ]
    return "\n\n---\n\n".join(parts)
