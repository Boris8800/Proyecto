install:
	chmod +x src/main.sh
	sudo ./src/main.sh

test:
	./tests/test_suite.sh

lint:
	shellcheck src/*.sh src/**/*.sh

docs:
	./docs/generator.sh

clean:
	./scripts/uninstall.sh

docker-build:
	docker build -t taxi-system .

.PHONY: install test lint docs clean docker-build
