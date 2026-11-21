.PHONY: install start dev test clean health package

PORT ?= 3000
NPM := npm
NODE := node
URL := http://localhost:$(PORT)

install: node_modules

start: node_modules
	PORT=$(PORT) $(NPM) start

dev: node_modules
	PORT=$(PORT) $(NPM) run dev

test: node_modules
	$(NPM) test

clean:
	rm -rf dist *.log

health:
	@curl -fsS $(URL)/health || (echo "ArtiShop ne répond pas sur $(URL)" && exit 1)

node_modules: package.json package-lock.json
	$(NPM) install
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

package: $(ARCHIVE)