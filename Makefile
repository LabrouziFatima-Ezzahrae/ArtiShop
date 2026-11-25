.PHONY: help install start dev test clean health package start-bg stop status restart ci

help: ## Affiche cette aide
	@grep -E '^[a-zA-Z_-]+:.*## ' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*## "}; {printf "  make %-10s %s\n", $$1, $$2}'
PORT ?= 3000
NPM := npm
NODE := node
URL := http://localhost:$(PORT)

ifeq ($(CI), true)
  INSTALL_CMD := $(NPM) ci
else
  INSTALL_CMD := $(NPM) install
endif

install: node_modules ## Installe les dépendances

start: node_modules   ## Démarre le serveur
	PORT=$(PORT) $(NPM) start

dev: node_modules     ## Lance le serveur en mode développement
	PORT=$(PORT) $(NPM) run dev

test: node_modules    ## Lance les tests
	$(NPM) test

clean:                ## Nettoie les fichiers générés et logs
	rm -rf dist *.log

health:               ## Vérifie l'état de santé de l'application
	@curl -fsS $(URL)/health || (echo "ArtiShop ne répond pas sur $(URL)" && exit 1)

node_modules: package.json package-lock.json
	$(INSTALL_CMD)
	@touch $@

APP     := artishop
VERSION := $(shell $(NODE) -p "require('./package.json').version")
DIST    := dist
ARCHIVE := $(DIST)/$(APP)-$(VERSION).tar.gz
SRC := $(wildcard src/*.js src/data/*.js public/*)

$(ARCHIVE): $(SRC) package.json package-lock.json README.md | $(DIST)
	tar -czf $@ src public package.json package-lock.json README.md

$(DIST):
	mkdir -p $@

package: $(ARCHIVE)    ## Génère l'archive livrable

start-bg: node_modules ## Démarre le serveur en arrière-plan
	@if [ -f .artishop.pid ] && kill -0 $$(cat .artishop.pid) 2>/dev/null; then \
		echo "Le serveur tourne déjà (PID $$(cat .artishop.pid))"; \
	else \
		PORT=$(PORT) $(NODE) src/server.js > artishop.log 2>&1 & \
		echo $$! > .artishop.pid; \
		echo "Serveur démarré (PID $$(cat .artishop.pid))"; \
	fi

stop: ## Arrête le serveur en arrière-plan
	@if [ -f .artishop.pid ]; then \
		PID=$$(cat .artishop.pid); \
		kill "$$PID" 2>/dev/null || true; \
		rm -f .artishop.pid; \
		echo "Serveur arrêté (PID $$PID)"; \
	else \
		echo "Aucun fichier PID trouvé"; \
	fi

status: ## Affiche l'état du serveur en arrière-plan
	@if [ -f .artishop.pid ] && kill -0 $$(cat .artishop.pid) 2>/dev/null; then \
		echo "Serveur actif (PID $$(cat .artishop.pid))"; \
	else \
		echo "Serveur arrêté"; \
	fi

restart: ## Redémarre le serveur en arrière-plan
	$(MAKE) stop
	$(MAKE) start-bg

ci: ## Exécute la pipeline CI (install, test, package)
	$(MAKE) CI=true install test package