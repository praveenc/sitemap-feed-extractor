# ── Sitemap Feed Extractor — Development Makefile ────────────────────────────
#
# Targets:
#   make lint       — Check code style (ruff → pylint fallback)
#   make format     — Auto-format code (ruff → autopep8 fallback)
#   make check      — Run lint + format check (CI-friendly, no modifications)
#   make precommit  — Format + lint (run before committing)
#   make clean      — Remove build/cache artifacts
#
# Prefers ruff; falls back to pylint/autopep8 if ruff is not installed.
# ─────────────────────────────────────────────────────────────────────────────

PYTHON_FILES := sitemap_feed_extractor.py

# Detect available tools
RUFF := $(shell command -v ruff 2>/dev/null)
PYLINT := $(shell command -v pylint 2>/dev/null)
AUTOPEP8 := $(shell command -v autopep8 2>/dev/null)

.PHONY: lint format check precommit clean help

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

# ── Lint ─────────────────────────────────────────────────────────────────────

lint: ## Check code for lint errors (no auto-fix)
ifdef RUFF
	@echo "🔍 Linting with ruff..."
	ruff check $(PYTHON_FILES)
else ifdef PYLINT
	@echo "🔍 Linting with pylint (ruff not found)..."
	pylint --disable=all --enable=E,W $(PYTHON_FILES)
else
	@echo "⚠️  No linter found. Install ruff (recommended) or pylint:"
	@echo "    uv tool install ruff"
	@exit 1
endif

# ── Format ───────────────────────────────────────────────────────────────────

format: ## Auto-format code in place
ifdef RUFF
	@echo "✨ Formatting with ruff..."
	ruff format $(PYTHON_FILES)
	ruff check --fix $(PYTHON_FILES)
else ifdef AUTOPEP8
	@echo "✨ Formatting with autopep8 (ruff not found)..."
	autopep8 --in-place --aggressive --aggressive $(PYTHON_FILES)
else
	@echo "⚠️  No formatter found. Install ruff (recommended) or autopep8:"
	@echo "    uv tool install ruff"
	@exit 1
endif

# ── Check (CI-friendly — no modifications) ──────────────────────────────────

check: ## Verify lint + format without modifying files
ifdef RUFF
	@echo "🔍 Checking format..."
	ruff format --check $(PYTHON_FILES)
	@echo "🔍 Checking lint..."
	ruff check $(PYTHON_FILES)
else ifdef PYLINT
	@echo "🔍 Checking lint with pylint (ruff not found)..."
	pylint --disable=all --enable=E,W $(PYTHON_FILES)
else
	@echo "⚠️  No linter found. Install ruff (recommended) or pylint:"
	@echo "    uv tool install ruff"
	@exit 1
endif

# ── Precommit (format + lint) ───────────────────────────────────────────────

precommit: format lint ## Format then lint — run before committing
	@echo ""
	@echo "✅ Ready to commit."

# ── Clean ────────────────────────────────────────────────────────────────────

clean: ## Remove cache and build artifacts
	rm -rf __pycache__ .ruff_cache .mypy_cache *.pyc
