.PHONY: check verify pipeline-check audit-summary render-role merge docx clean clean-audits help

help: ## 显示帮助信息
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

check: ## 严格检查已生成章节；无章节或存在 error 时失败
	python3 scripts/check_evidence.py --require-sections --fail-on-error

verify: ## 运行仓库级单元测试（无需生成报告）
	PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests -p 'test_*.py'

pipeline-check: ## 校验 manifest / hash / 章节 / 审计闸门；FORCE=1 仅绕过失败审计
	python3 scripts/verify_pipeline.py $(if $(FORCE),--force,)

render-role: ## 渲染 role prompt 到 stdout，需 ROLE=<name> [CHAPTER=<id>]
	@if [ -z "$(ROLE)" ]; then echo "用法: make render-role ROLE=audit [CHAPTER=03_financials]"; exit 1; fi
	@python3 scripts/render_role.py $(ROLE) $(if $(CHAPTER),--chapter $(CHAPTER),)

audit-summary: ## 聚合 output/audits/*.json 到 audit_summary.md（merge 前应先跑）
	python3 scripts/audit_summary.py

merge: ## 验证后合并各章节为完整文档（含审计附录）；可用 FORCE=1
	python3 scripts/merge.py $(if $(FORCE),--force,)

docx: ## 转换为 Word 文档
	bash scripts/convert.sh

clean: ## 清理所有生成文件（含审计中间产物）
	find output/sections -type f ! -name '.gitkeep' -delete
	rm -f output/web_search_log.md
	rm -f output/facts.md
	rm -f output/company_facets.md
	rm -f output/manifest.json
	find output/audits -type f ! -name '.gitkeep' -delete
	rm -f output/research_report.md
	rm -f output/research_report.docx
	@echo "已清理所有生成文件"

clean-audits: ## 仅清理 output/audits/ 目录
	find output/audits -type f ! -name '.gitkeep' -delete
	@echo "已清理审计中间产物"
