SHELL := /bin/bash
HOME_DIR := $(or $(DETERMINATOR_HOME),$(HOME)/.local/share/determinator)

.PHONY: install uninstall verify doctor update help

help:
	@echo "determinator make targets:"
	@echo "  make install     install (idempotent): deps, shell wiring, MCP, commands, permissions"
	@echo "  make uninstall   reverse every step (leaves Ollama/models intact)"
	@echo "  make doctor      full per-tier end-to-end verification"
	@echo "  make verify      fast structural checks (no network/model calls)"
	@echo "  make update      git pull, then re-run install"

install:
	@./install.sh

uninstall:
	@if [ -x "$(HOME_DIR)/scripts/uninstall.sh" ]; then bash "$(HOME_DIR)/scripts/uninstall.sh"; else bash scripts/uninstall.sh; fi

doctor:
	@if [ -x "$(HOME_DIR)/scripts/doctor.sh" ]; then bash "$(HOME_DIR)/scripts/doctor.sh"; else bash scripts/doctor.sh; fi

verify:
	@bash scripts/doctor.sh --quick

update:
	@git pull --ff-only && ./install.sh
