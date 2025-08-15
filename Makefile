# Makefile для ruvname

.PHONY: build build-nogui build-gui run run-nogui run-gui install clean release test

# Пути
BINARY=ruvname
CONFIG=ruvname.toml
LOG=ruvname.log

# === Сборка ===

build:
	@echo "🔧 Сборка с GUI..."
	cargo build --release

build-nogui:
	@echo "🔧 Сборка без GUI..."
	cargo build --release --no-default-features --features="doh"

build-gui:
	@echo "🔧 Сборка с GUI..."
	cargo build --release --features="webgui"

# === Запуск ===

run: build
	@echo "🚀 Запуск ruvname..."
	./target/release/$(BINARY)

run-nogui: build-nogui
	@echo "🚀 Запуск ruvname (nogui)..."
	./target/release/$(BINARY) -nogui

run-gui: build-gui
	@echo "🚀 Запуск ruvname (GUI)..."
	./target/release/$(BINARY)

# === Установка ===

install: build
	@echo "📦 Установка в /usr/local/bin..."
	sudo cp target/release/$(BINARY) /usr/local/bin/
	sudo cp $(CONFIG) /etc/$(CONFIG)
	@echo "✅ Установлено: /usr/local/bin/$(BINARY)"

# === Тесты ===

test:
	@echo "🧪 Запуск тестов..."
	cargo test --all-features

# === Очистка ===

clean:
	@echo "🧹 Очистка..."
	cargo clean
	rm -f $(LOG)

# === Релиз (мультиархитектура) ===

release:
	@echo "📦 Запуск мультиархитектурной сборки..."
	bash contrib/deb/build-multiarch.sh

# === Помощь ===

help:
	@echo ""
	@echo "=== Makefile для ruvname ==="
	@echo ""
	@echo "Доступные команды:"
	@echo "  make build        - Собрать с GUI"
	@echo "  make build-nogui  - Собрать без GUI"
	@echo "  make run          - Запустить"
	@echo "  make run-nogui    - Запустить без GUI"
	@echo "  make run-gui      - Запустить с GUI"
	@echo "  make install      - Установить в систему"
	@echo "  make test         - Запустить тесты"
	@echo "  make clean        - Очистить"
	@echo "  make release      - Собрать .deb, .zip, .dmg"
	@echo "  make help         - Показать эту справку"
	@echo ""
