#!/bin/bash
# 把合并后的公司调研报告 markdown 转成 Word 文档。

set -euo pipefail

INPUT="${1:-output/research_report.md}"
OUTPUT="${2:-output/research_report.docx}"

if [ ! -f "$INPUT" ]; then
    echo "错误: 输入文件不存在: $INPUT"
    echo "请先运行 make merge"
    exit 1
fi

if ! command -v pandoc &> /dev/null; then
    echo "错误: 未安装 pandoc"
    echo "请安装: brew install pandoc"
    exit 1
fi

pandoc "$INPUT" \
    -o "$OUTPUT" \
    --from markdown \
    --to docx \
    -V lang=zh-CN

echo "Word 文件已生成: $OUTPUT"
