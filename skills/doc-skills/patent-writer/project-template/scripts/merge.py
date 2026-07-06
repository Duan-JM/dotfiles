"""合并已生成的交底书章节为完整文档。"""

import os
import glob

# 硬编码路径（从项目根目录运行）
SECTIONS_DIR = "output/sections"
MERGED_FILE = "output/disclosure.md"
IDEA_FILE = "input/invention_idea.md"


def read_file(file_path):
    """读取文件内容，文件不存在则返回空字符串。"""
    if not os.path.exists(file_path):
        return ""
    with open(file_path, "r", encoding="utf-8") as f:
        return f.read().strip()


def run_merge():
    """合并所有章节文件为完整交底书。"""
    # 读取发明思路，提取发明名称
    idea = read_file(IDEA_FILE)
    invention_name = "专利技术交底书"
    found_name_header = False
    for line in idea.split("\n"):
        if line.strip() == "## 发明名称":
            found_name_header = True
            continue
        if found_name_header and line.strip() and not line.startswith("#") and not line.startswith("<!--"):
            candidate = line.strip().strip("（）()").strip()
            if candidate and candidate != "请填写":
                invention_name = candidate
            break

    # 收集并排序章节文件
    section_files = sorted(glob.glob(os.path.join(SECTIONS_DIR, "*.md")))
    section_files = [f for f in section_files if not f.endswith(".gitkeep")]
    if not section_files:
        print("错误: 没有找到已生成的章节文件，请先运行 /patent-generate")
        return False

    # 构建合并文档
    parts = [f"# {invention_name}\n\n## 技术交底书\n"]
    for filepath in section_files:
        content = read_file(filepath)
        if content:
            parts.append(content)

    merged = "\n\n---\n\n".join(parts)

    os.makedirs(os.path.dirname(MERGED_FILE), exist_ok=True)
    with open(MERGED_FILE, "w", encoding="utf-8") as f:
        f.write(merged)

    print(f"交底书已合并到: {MERGED_FILE}")
    return True


if __name__ == "__main__":
    run_merge()
