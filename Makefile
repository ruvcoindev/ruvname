# =============================================================================
# Makefile для ruvname
# Упрощённое управление: сборка, запуск, установка, документация, CI
# =============================================================================

# === Пути и настройки ===
BINARY = ruvname
CONFIG = ruvname.toml
LOG = ruvname.log
INSTALL_DIR = /usr/local/bin
CONFIG_DIR = /etc
SYSTEMD_DIR = /etc/systemd/system

# === Цели ===
.PHONY: help

help:
	@echo ""
	@echo "=== Makefile для ruvname ==="
	@echo ""
	@echo "Доступные команды:"
	@echo "  make build             - Собрать с GUI"
	@echo "  make build-nogui       - Собрать без GUI"
	@echo "  make build-gui         - Собрать с GUI (явно)"
	@echo ""
	@echo "  make run               - Запустить"
	@echo "  make run-nogui         - Запустить без GUI"
	@echo "  make run-gui           - Запустить с GUI"
	@echo ""
	@echo "  make install           - Установить в систему"
	@echo "  make uninstall         - Удалить из системы"
	@echo "  make generate-config   - Сгенерировать ruvname.toml"
	@echo "  make test              - Запустить тесты"
	@echo "  make clean             - Очистить target/"
	@echo "  make format            - Проверить форматирование (rustfmt)"
	@echo "  make format-fix        - Применить форматирование"
	@echo "  make ci                - Запустить локальный CI"
	@echo "  make release           - Собрать .deb, .zip, .dmg"
	@echo "  make docs              - Собрать документацию (mdbook)"
	@echo "  make serve             - Запустить локальный сервер документации"
	@echo "  make docs-publish      - Опубликовать документацию на GitHub Pages"
	@echo "  make check-deps        - Проверить зависимости"
	@echo "  make python-deps       - Установить Python зависимости"
	@echo "  make run-python-example - Запустить Python-пример"
	@echo "  make help              - Показать эту справку"
	@echo ""

# === Сборка ===
.PHONY: build build-nogui build-gui

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
.PHONY: run run-nogui run-gui

run: build
	@echo "🚀 Запуск ruvname..."
	./target/release/$(BINARY)

run-nogui: build-nogui
	@echo "🚀 Запуск ruvname (nogui)..."
	./target/release/$(BINARY) -nogui

run-gui: build-gui
	@echo "🚀 Запуск ruvname (GUI)..."
	./target/release/$(BINARY)

# === Установка / Удаление ===
.PHONY: install uninstall

install: build
	@echo "📦 Установка в /usr/local/bin..."
	@echo "   → $(INSTALL_DIR)/$(BINARY)"
	@echo "   → $(CONFIG_DIR)/$(CONFIG)"
	sudo cp target/release/$(BINARY) $(INSTALL_DIR)/
	sudo mkdir -p $(CONFIG_DIR)
	sudo cp $(CONFIG) $(CONFIG_DIR)/$(CONFIG) || echo "⚠️  Конфиг не найден, сгенерируйте: make generate-config"
	sudo cp contrib/systemd/ruvname.service $(SYSTEMD_DIR)/
	sudo cp contrib/systemd/ruvname-default-config.service $(SYSTEMD_DIR)/
	sudo systemctl daemon-reload
	sudo systemctl enable ruvname || true
	sudo systemctl start ruvname || true
	@echo "✅ Установлено. Управление: sudo systemctl {start|stop|status} ruvname"

uninstall:
	@echo "🗑️  Удаление RUVNAME..."
	sudo systemctl stop ruvname || true
	sudo systemctl disable ruvname || true
	sudo rm -f $(INSTALL_DIR)/$(BINARY)
	sudo rm -f $(CONFIG_DIR)/$(CONFIG)
	sudo rm -f $(SYSTEMD_DIR)/ruvname.service
	sudo rm -f $(SYSTEMD_DIR)/ruvname-default-config.service
	sudo systemctl daemon-reload
	@echo "✅ Удалено"

# === Тесты и очистка ===
.PHONY: test clean

test:
	@echo "🧪 Запуск тестов..."
	cargo test --all-features

clean:
	@echo "🧹 Очистка..."
	cargo clean
	rm -f $(LOG) 2>/dev/null || true
	rm -f $(CONFIG).backup.* 2>/dev/null || true

# === Форматирование кода ===
.PHONY: format format-fix

format:
	@echo "🎨 Проверка форматирования (cargo fmt --check)..."
	@if cargo fmt --check; then \
		@echo "✅ Форматирование корректно"; \
	else \
		@echo "❌ Нарушено форматирование. Исправьте: make format-fix"; \
		exit 1; \
	fi

format-fix:
	@echo "🎨 Применение форматирования..."
	cargo fmt
	@echo "✅ Код отформатирован"

# === CI (локальный тест) ===
.PHONY: ci

ci:
	@echo "🔧 Запуск локального CI..."
	make check-deps
	make format
	make test
	make build-nogui
	make build-gui
	make docs
	@echo "✅ CI: Все проверки пройдены"

# === Релиз (мультиархитектура) ===
.PHONY: release

release:
	@echo "📦 Запуск мультиархитектурной сборки..."
	@echo "   Требуется: cross, docker, upx"
	bash contrib/deb/build-multiarch.sh

# === Документация ===
.PHONY: docs serve docs-check docs-publish

docs: docs-check
	@echo "📚 Сборка документации через mdbook..."
	cd book && mdbook build
	@echo "✅ Документация готова: book/book/html/index.html"

serve: docs
	@echo "🚀 Запуск локального сервера документации..."
	cd book && mdbook serve

docs-check:
	@echo "🔍 Проверка: установлен ли mdbook..."
	@if ! command -v mdbook >/dev/null; then \
		echo "❌ mdbook не установлен. Установите: cargo install mdbook"; \
		exit 1; \
	fi

docs-publish: docs
	@echo "🌍 Публикация документации на GitHub Pages..."
	@if ! command -v git >/dev/null; then \
		echo "❌ git не установлен"; \
		exit 1; \
	fi
	@if ! git remote -v | grep -q 'github.com'; then \
		echo "⚠️  Репозиторий не привязан к GitHub. Публикация отменена."; \
		exit 1; \
	fi
	@CURRENT_BRANCH=$$(git branch --show-current); \
	echo "📦 Текущая ветка: $$CURRENT_BRANCH"
	@git fetch origin gh-pages || echo "gh-pages ветка не существует"
	@git checkout gh-pages 2>/dev/null || \
		(git checkout --orphan gh-pages && git rm -rf . && echo "Создана новая ветка gh-pages")
	@echo "🧹 Очистка старых файлов..."
	@git rm -rf . || true
	@rm -rf .gitignore || true
	@echo "📦 Копируем book/book/html/ -> корень..."
	@cp -r book/book/html/* . || (echo "❌ Ошибка копирования"; exit 1)
	@echo "" > .nojekyll
	@echo "💾 Коммит изменений..."
	@git add .
	@git config user.name "Automated CI" || true
	@git config user.email "ci@ruv.name" || true
	@git commit -m "docs: обновлено на $(shell date '+%Y-%m-%d %H:%M:%S') из $$CURRENT_BRANCH"
	@echo "🚀 Публикация на GitHub Pages..."
	@git push origin gh-pages --force
	@git checkout "$$CURRENT_BRANCH" 2>/dev/null || true
	@echo "✅ Документация опубликована!"
	@echo "   Откройте: https://$(shell git config --get remote.origin.url | sed -E 's/.*github.com[/:]([^/]+)\\/(.+).git/\\1.github.io\\/\\2/' | sed 's/\\.git$$//')"

# === Дополнительно ===
.PHONY: generate-config check-deps

generate-config:
	@echo "⚙️  Генерация конфига: $(CONFIG)"
	./target/release/$(BINARY) -g > $(CONFIG)
	@echo "✅ Конфиг сохранён: $(CONFIG)"

check-deps:
	@echo "🔍 Проверка зависимостей..."
	@for cmd in cargo make bash docker upx mdbook git; do \
		if ! command -v $$cmd >/dev/null; then \
			echo "❌ $$cmd не установлен"; \
			exit 1; \
		fi; \
	done
	@echo "✅ Все зависимости установлены"

# === Python примеры ===
.PHONY: python-deps run-python-example

python-deps:
	@echo "📦 Создание виртуального окружения..."
	python3 -m venv venv
	@echo "📦 Установка зависимостей..."
	venv/bin/pip install -r requirements.txt
	@echo "✅ Готово. Активируйте: source venv/bin/activate"

run-python-example: python-deps
	@echo "🚀 Запуск Python-примера..."
	venv/bin/python book/src/examples/python_client.py
