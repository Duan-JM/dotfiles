.PHONY: merge docx clean help

help: ## 显示帮助信息
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

merge: ## 合并各章节为完整文档
	python3 scripts/merge.py

docx: ## 转换为 Word 文档
	bash scripts/convert.sh

clean: ## 清理生成的文件
	rm -f output/sections/*.md
	rm -f output/disclosure.md
	rm -f output/disclosure.docx
	rm -f output/research_report.md
	@echo "已清理所有生成文件"
