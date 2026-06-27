.PHONY: help dev stop deploy deploy-full deploy-setup deploy-status deploy-logs deploy-console deploy-rollback deploy-migrate deploy-seed

help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ── Local Development ─────────────────────────────────────────────

dev: ## Start development server (Docker)
	npm run dev

stop: ## Stop all services
	npm run stop

logs: ## View backend logs
	npm run logs

console: ## Open Rails console
	npm run console

# ── Deployment (Kamal) ───────────────────────────────────────────

deploy: ## Deploy to production
	cd backend && bin/deploy deploy

deploy-full: ## Full deployment (Rails + Storefront + Nginx)
	cd backend && bin/deploy-full

deploy-setup: ## First-time server setup (boot all accessories)
	cd backend && bin/deploy setup

deploy-status: ## Check deployment status
	cd backend && bin/deploy status

deploy-logs: ## Stream production logs
	cd backend && bin/deploy logs

deploy-console: ## Open production Rails console
	cd backend && bin/deploy console

deploy-rollback: ## Rollback to previous version
	cd backend && bin/deploy rollback

deploy-migrate: ## Run database migrations in production
	cd backend && bin/deploy db:migrate

deploy-seed: ## Seed the production database
	cd backend && bin/deploy seed

deploy-rebuild: ## Full rebuild and deploy
	cd backend && bin/deploy rebuild
