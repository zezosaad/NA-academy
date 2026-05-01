# NA-Academy task runner.
# Usage: `make help` for the full list.

SHELL          := /bin/bash
.SHELLFLAGS    := -eu -o pipefail -c
MAKEFLAGS      += --no-print-directory

COMPOSE          ?= docker compose
BACKEND_SERVICE  ?= backend
ADMIN_SERVICE    ?= admin
DB_SERVICE       ?= mongodb
BACK_DIR         := back
ADMIN_DIR        := admin-dashboard

# Default target: show help.
.DEFAULT_GOAL := help

# ──────────────────────────────────────────────────────────────────────
# Help
# ──────────────────────────────────────────────────────────────────────
.PHONY: help
help: ## Show this help.
	@awk 'BEGIN {FS = ":.*?## "; printf "\nTargets:\n"} \
	      /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2} \
	      /^##@/ {printf "\n\033[1m%s\033[0m\n", substr($$0, 5)}' $(MAKEFILE_LIST)

##@ Docker (split stack: backend + admin + mongodb)

.PHONY: up
up: ## Start the full stack in the background.
	$(COMPOSE) up -d

.PHONY: up-fg
up-fg: ## Start the stack in the foreground (Ctrl-C to stop).
	$(COMPOSE) up

.PHONY: build
build: ## Build all images (backend + admin).
	$(COMPOSE) build

.PHONY: build-backend
build-backend: ## Build only the backend image.
	$(COMPOSE) build $(BACKEND_SERVICE)

.PHONY: build-admin
build-admin: ## Build only the admin image.
	$(COMPOSE) build $(ADMIN_SERVICE)

.PHONY: rebuild
rebuild: ## Rebuild all images without cache.
	$(COMPOSE) build --no-cache

.PHONY: down
down: ## Stop and remove containers (data volumes kept).
	$(COMPOSE) down

.PHONY: nuke
nuke: ## Stop containers AND drop the mongo_data volume. DESTROYS DATA.
	$(COMPOSE) down -v

.PHONY: restart
restart: ## Restart all app containers (backend + admin).
	$(COMPOSE) restart $(BACKEND_SERVICE) $(ADMIN_SERVICE)

.PHONY: restart-backend
restart-backend: ## Restart only the backend container.
	$(COMPOSE) restart $(BACKEND_SERVICE)

.PHONY: restart-admin
restart-admin: ## Restart only the admin container.
	$(COMPOSE) restart $(ADMIN_SERVICE)

.PHONY: ps
ps: ## Show container status.
	$(COMPOSE) ps

.PHONY: logs
logs: ## Tail logs for all services.
	$(COMPOSE) logs -f --tail=200

.PHONY: logs-backend
logs-backend: ## Tail logs for the backend container only.
	$(COMPOSE) logs -f --tail=200 $(BACKEND_SERVICE)

.PHONY: logs-admin
logs-admin: ## Tail logs for the admin container only.
	$(COMPOSE) logs -f --tail=200 $(ADMIN_SERVICE)

.PHONY: logs-db
logs-db: ## Tail logs for mongodb only.
	$(COMPOSE) logs -f --tail=200 $(DB_SERVICE)

.PHONY: shell-backend
shell-backend: ## Open a shell inside the backend container.
	$(COMPOSE) exec $(BACKEND_SERVICE) sh

.PHONY: shell-admin
shell-admin: ## Open a shell inside the admin (nginx) container.
	$(COMPOSE) exec $(ADMIN_SERVICE) sh

.PHONY: mongo
mongo: ## Open mongosh against the mongodb container.
	$(COMPOSE) exec $(DB_SERVICE) mongosh na_academy

##@ Backend (NestJS @ back/)

.PHONY: install-back
install-back: ## Install backend deps (npm ci).
	cd $(BACK_DIR) && npm ci

.PHONY: dev
dev: ## Run backend in watch mode (npm run start:dev).
	cd $(BACK_DIR) && npm run start:dev

.PHONY: back-build
back-build: ## Compile the backend (nest build).
	cd $(BACK_DIR) && npm run build

.PHONY: back-start
back-start: ## Run the compiled backend (node dist/main).
	cd $(BACK_DIR) && npm run start:prod

.PHONY: back-lint
back-lint: ## Lint backend sources.
	cd $(BACK_DIR) && npm run lint

.PHONY: back-test
back-test: ## Run backend unit tests.
	cd $(BACK_DIR) && npm test

.PHONY: back-test-e2e
back-test-e2e: ## Run backend e2e tests.
	cd $(BACK_DIR) && npm run test:e2e

.PHONY: seed-admin
seed-admin: ## Seed the initial admin user against your local backend (host npm).
	cd $(BACK_DIR) && npm run seed:admin

.PHONY: docker-seed-admin
docker-seed-admin: ## Seed the admin user inside the running backend container.
	$(COMPOSE) exec $(BACKEND_SERVICE) node dist/scripts/seed-admin.js

##@ Admin dashboard (Vite SPA @ admin-dashboard/)

.PHONY: install-admin
install-admin: ## Install admin deps (npm ci).
	cd $(ADMIN_DIR) && npm ci

.PHONY: admin-dev
admin-dev: ## Run the admin dashboard dev server (vite).
	cd $(ADMIN_DIR) && npm run dev

.PHONY: admin-build
admin-build: ## Build admin static bundle (tsc + vite build).
	cd $(ADMIN_DIR) && npm run build

.PHONY: admin-preview
admin-preview: ## Preview the production admin bundle.
	cd $(ADMIN_DIR) && npm run preview

.PHONY: admin-lint
admin-lint: ## Lint admin sources.
	cd $(ADMIN_DIR) && npm run lint

##@ Combined

.PHONY: install
install: install-back install-admin ## Install deps for both backend and admin.

.PHONY: lint
lint: back-lint admin-lint ## Lint both projects.

.PHONY: build-all
build-all: back-build admin-build ## Build both projects locally (no Docker).

.PHONY: dev-all
dev-all: ## Run backend (start:dev) + admin (vite) in parallel. Use Ctrl-C to stop both.
	$(MAKE) -j2 dev admin-dev
