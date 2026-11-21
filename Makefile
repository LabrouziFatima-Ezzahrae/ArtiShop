.PHONY: install start dev test clean health

PORT ?= 3000
NPM := npm
NODE := node
URL := http://localhost:$(PORT)

install:
	$(NPM) install

start:
	PORT=$(PORT) $(NPM) start

dev:
	PORT=$(PORT) $(NPM) run dev

test:
	$(NPM) test

clean:
	rm -rf dist *.log

health:
	@curl -fsS $(URL)/health || { echo "ArtiShop ne répond pas sur $(URL)"; exit 1; }