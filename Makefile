# =============================================================================
# Makefile для ruvname
# Упрощённое управление: сборка, запуск, установка, документация, релиз
# =============================================================================

# === Пути и настройки ===
BINARY = ruvname
CONFIG = ruvname.toml
LOG = ruvname.log

# === Цели ===
.PHONY: build build-nogui build-gui run run-nogui run-gui install clean release test help

# === Сборка ===

## Собрать с GUI (по умолчанию)
build:
	@echo "🔧 Сборка с GUI..."
	cargo build --release

## Собрать без GUI
build-nogui:
	@echo "🔧 Сборка без GUI..."
	cargo build --release --no-default-features --features="doh"

## Собрать с GUI (явно)
build-gui:
	@echo "🔧 Сборка с GUI..."
	cargo build --release --features="webgui"

# === Запуск ===

## Запустить (сборка + запуск)
run: build
	@echo "🚀 Запуск ruvname..."
	./target/release/$(BINARY)

## Запустить без GUI
run-nogui: build-nogui
	@echo "🚀 Запуск ruvname (nogui)..."
	./target/release/$(BINARY) -nogui

## Запустить с GUI
run-gui: build-gui
	@echo "🚀 Запуск ruvname (GUI)..."
	./target/release/$(BINARY)

# === Установка ===

## Установить в систему
install: build
	@echo "📦 Установка в /usr/local/bin..."
	@echo "   → /usr/local/bin/$(BINARY)"
	@echo "   → /etc/$(CONFIG)"
	sudo cp target/release/$(BINARY) /usr/local/bin/
	sudo mkdir -p /etc
	sudo cp $(CONFIG) /etc/$(CONFIG) || echo "⚠️  Конфиг не найден, сгенерируйте: make generate-config"
	@echo "✅ Установлено: /usr/local/bin/$(BINARY)"

# === Тесты ===

## Запустить тесты
test:
	@echo "🧪 Запуск тестов..."
	cargo test --all-features

# === Очистка ===

## Очистить артефакты
clean:
	@echo "🧹 Очистка..."
	cargo clean
	rm -f $(LOG) 2>/dev/null || true
	rm -f $(CONFIG).backup.* 2>/dev/null || true

# === Релиз (мультиархитектура) ===

## Собрать .deb, .zip, .dmg для всех платформ
release:
	@echo "📦 Запуск мультиархитектурной сборки..."
	@echo "   Требуется: cross, docker, upx"
	bash contrib/deb/build-multiarch.sh

# === Документация ===

.PHONY: docs serve docs-check

## Сгенерировать документацию (mdbook)
docs: docs-check
	@echo "📚 Сборка документации через mdbook..."
	cd book && mdbook build
	@echo "✅ Документация готова: book/book/html/index.html"

## Запустить локальный сервер документации
serve: docs
	@echo "🚀 Запуск локального сервера документации..."
	cd book && mdbook serve

## Проверить наличие mdbook
docs-check:
	@echo "🔍 Проверка: установлен ли mdbook..."
	@if ! command -v mdbook >/dev/null; then \
		echo "❌ mdbook не установлен. Установите: cargo install mdbook"; \
		exit 1; \
	fi

# === Дополнительно ===

## Сгенерировать конфиг по умолчанию
generate-config:
	@echo "⚙️  Генерация конфига: $(CONFIG)"
	./target/release/$(BINARY) -g > $(CONFIG)
	@echo "✅ Конфиг сохранён: $(CONFIG)"

## Проверить зависимости
check-deps:
	@echo "🔍 Проверка зависимостей..."
	@for cmd in cargo bash docker upx; do \
		if ! command -v $$cmd >/dev/null; then \
			echo "❌ $$cmd не установлен"; \
			exit 1; \
		fi; \
	done
	@echo "✅ Все зависимости установлены"


# === Публикация документации ===

.PHONY: docs-publish

## Опубликовать документацию на GitHub Pages
docs-publish: docs
	@echo "🌍 Публикация документации на GitHub Pages..."
	@echo "   Убедитесь, что вы в репозитории с GitHub-репозиторием"

	# Проверка, установлен ли git
	@if ! command -v git >/dev/null; then \
		echo "❌ git не установлен"; \
		exit 1; \
	fi

	# Проверка, что это GitHub-репозиторий
	@if ! git remote -v | grep -q 'github.com'; then \
		echo "⚠️  Репозиторий не привязан к GitHub. Публикация отменена."; \
		exit 1; \
	fi

	# Сохраняем текущую ветку
	@CURRENT_BRANCH=$$(git branch --show-current); \
	echo "📦 Текущая ветка: $$CURRENT_BRANCH"

	# Создаём или переключаемся на gh-pages
	@git fetch origin gh-pages || echo "gh-pages ветка не существует, будет создана"
	@git checkout gh-pages 2>/dev/null || \
		(git checkout --orphan gh-pages && git rm -rf . && echo "Создана новая ветка gh-pages")

	# Копируем только HTML
	@echo "🧹 Очистка старых файлов..."
	@git rm -rf . || true
	@rm -rf .gitignore || true

	@echo "📦 Копируем book/book/html/ -> корень..."
	@cp -r book/book/html/* . || (echo "❌ Не удалось скопировать book/book/html/"; exit 1)

	# Добавляем .nojekyll (чтобы работали файлы с подчёркиванием, как _book)
	@echo "" > .nojekyll

	# Коммит и пуш
	@echo "💾 Коммит изменений..."
	@git add .
	@git config user.name "Automated CI" || true
	@git config user.email "ci@ruv.name" || true
	@git commit -m "docs: обновлено на $(shell date '+%Y-%m-%d %H:%M:%S') из $$CURRENT_BRANCH"

	@echo "🚀 Публикация на GitHub Pages..."
	@git push origin gh-pages --force

	# Возвращаемся на предыдущую ветку
	@git checkout "$$CURRENT_BRANCH" 2>/dev/null || true

	@echo ""
	@echo "✅ Документация опубликована!"
	@echo "   Откройте: https://$(shell git config --get remote.origin.url | sed -E 's/.*github.com[/:]([^/]+)\\/(.+).git/\\1.github.io\\/\\2/' | sed 's/\\.git$$//')"
	@echo ""



# === Помощь ===

## Показать справку
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
	@echo "  make install           - Установить в /usr/local/bin"
	@echo "  make generate-config   - Сгенерировать ruvname.toml"
	@echo "  make test              - Запустить тесты"
	@echo "  make clean             - Очистить"
	@echo "  make release           - Собрать .deb, .zip, .dmg"
	@echo "  make docs              - Собрать документацию (mdbook)"
	@echo "  make serve             - Запустить локальный сервер документации"
	@echo "  make check-deps        - Проверить зависимости"
	@echo "  make help              - Показать эту справку"
	@echo ""
