.PHONY: check audit-summary render-role merge docx clean clean-audits help

help: ## 显示帮助信息
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

check: ## 跑程序化 evidence linter（输出 output/audits/programmatic_check.json）
	python3 scripts/check_evidence.py

render-role: ## 渲染 role prompt 到 stdout，需 ROLE=<name> [CHAPTER=<id>]
	@if [ -z "$(ROLE)" ]; then echo "用法: make render-role ROLE=audit [CHAPTER=03_financials]"; exit 1; fi
	@python3 scripts/render_role.py $(ROLE) $(if $(CHAPTER),--chapter $(CHAPTER),)

audit-summary: ## 聚合 output/audits/*.json 到 audit_summary.md（merge 前应先跑）
	python3 scripts/audit_summary.py

merge: audit-summary ## 合并各章节为完整文档（含审计附录）
	python3 scripts/merge.py

docx: ## 转换为 Word 文档
	bash scripts/convert.sh

clean: ## 清理所有生成文件（含审计中间产物）
	rm -f output/sections/*.md
	rm -f output/web_search_log.md
	rm -f output/facts.md
	rm -f output/company_facets.md
	rm -f output/manifest.json
	rm -rf output/audits
	rm -f output/research_report.md
	rm -f output/research_report.docx
	@echo "已清理所有生成文件"

clean-audits: ## 仅清理 output/audits/ 目录
	rm -rf output/audits
	@echo "已清理审计中间产物"
