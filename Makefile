# =============================================================================
# Makefile для ruvname
# Универсальное управление: сборка, установка, релиз, документация, CI
# =============================================================================

# === Пути и настройки ===
BINARY = ruvname
CONFIG = ruvname.toml
LOG = ruvname.log
PKGNAME = $(shell grep '^name' Cargo.toml | head -n1 | cut -d '"' -f2)
PKGVERSION = $(shell grep '^version' Cargo.toml | head -n1 | cut -d '"' -f2)

# === Папки ===
BINARY_DIR = bin
DEB_DIR = $(BINARY_DIR)/deb
ZIP_DIR = $(BINARY_DIR)/win
DMG_DIR = $(BINARY_DIR)/macos
MSI_DIR = $(BINARY_DIR)/msi
APPIMAGE_DIR = $(BINARY_DIR)/appimage

# === Цели ===
.PHONY: help

help:
	@echo ""
	@echo "=== Makefile для ruvname ==="
	@echo ""
	@echo "  make build             - Собрать с GUI"
	@echo "  make build-nogui       - Собрать без GUI"
	@echo "  make run               - Запустить"
	@echo "  make install           - Установить в систему"
	@echo "  make uninstall         - Удалить из системы"
	@echo "  make test              - Запустить тесты"
	@echo "  make clean             - Очистить"
	@echo "  make format            - Проверить форматирование"
	@echo "  make ci                - Локальный CI"
	@echo "  make release           - Собрать .deb, .zip, .dmg"
	@echo "  make release-verbose   - Собрать все платформы с GUI"
	@echo "  make msi               - Собрать .msi (требует Windows)"
	@echo "  make appimage          - Собрать .AppImage"
	@echo "  make docs              - Собрать документацию"
	@echo "  make docs-publish      - Опубликовать на GitHub Pages"
	@echo "  make sign-msi          - Подписать .msi (если есть сертификат)"
	@echo "  make help              - Показать справку"
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
.PHONY: run

run: build
	@echo "🚀 Запуск ruvname..."
	./target/release/$(BINARY)

# === Установка / Удаление ===
.PHONY: install uninstall

install: build
	@echo "📦 Установка в /usr/local/bin..."
	sudo cp target/release/$(BINARY) /usr/local/bin/
	sudo mkdir -p /etc
	sudo cp $(CONFIG) /etc/$(CONFIG) || echo "⚠️ Конфиг не найден"
	sudo cp contrib/systemd/ruvname.service /etc/systemd/system/
	sudo cp contrib/systemd/ruvname-default-config.service /etc/systemd/system/
	sudo systemctl daemon-reload
	sudo systemctl enable ruvname || true
	sudo systemctl start ruvname || true
	@echo "✅ Установлено"

uninstall:
	@echo "🗑️ Удаление из системы..."
	sudo systemctl stop ruvname || true
	sudo systemctl disable ruvname || true
	sudo rm -f /usr/local/bin/$(BINARY)
	sudo rm -f /etc/$(CONFIG)
	sudo rm -f /etc/systemd/system/ruvname.service
	sudo rm -f /etc/systemd/system/ruvname-default-config.service
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
	rm -rf $(BINARY_DIR)/*
	rm -rf tmp/

# === Форматирование ===
.PHONY: format

format:
	@if cargo fmt --check; then \
		echo "✅ Форматирование корректно"; \
	else \
		echo "❌ Нарушено форматирование. Исправьте: cargo fmt"; \
		exit 1; \
	fi

# === CI ===
.PHONY: ci

ci:
	@echo "🔧 Запуск CI..."
	make check-deps
	make format
	make test
	make build-gui
	make release
	make docs
	@echo "✅ CI: Все проверки пройдены"

# === Релиз ===
.PHONY: release release-verbose

release:
	@echo "📦 Запуск мультиархитектурной сборки (основные платформы)..."
	@ARCHS="linux-amd64,windows-x64" \
	 BUILD_GUI=false \
	 BUILD_NOGUI=true \
	 bash contrib/deb/build-multiarch.sh

release-verbose:
	@echo "📦 Запуск полной сборки (все платформы, GUI)..."
	@ARCHS="linux-amd64,linux-i686,linux-arm64,linux-armhf,windows-x64,windows-x86,macos-x64,macos-arm64" \
	 BUILD_GUI=true \
	 BUILD_NOGUI=true \
	 VERBOSE=1 \
	 bash contrib/deb/build-multiarch.sh

# === Подпись .msi ===
.PHONY: sign-msi

sign-msi: msi
	@if [ -n "$(CERT_PFX)" ] && [ -n "$(CERT_PASS)" ]; then \
		echo "🔐 Подпись .msi..."; \
		osslsigncode sign \
			-pkcs12 "$(CERT_PFX)" \
			-pass "$(CERT_PASS)" \
			-n "RUVNAME Installer" \
			-i "https://ruv.name" \
			-t http://timestamp.digicert.com \
			-in "$(MSI_DIR)/ruvname-windows-v$(PKGVERSION).msi" \
			-out "$(MSI_DIR)/ruvname-signed.msi" && \
		mv "$(MSI_DIR)/ruvname-signed.msi" "$(MSI_DIR)/ruvname-windows-v$(PKGVERSION).msi"; \
	else \
		echo "⚠️ CERT_PFX и CERT_PASS не заданы. Подпись пропущена."; \
	fi

# === Сборка .msi ===
.PHONY: msi

msi: release
	@echo "📦 Сборка .msi установщика..."
	@mkdir -p $(MSI_DIR) tmp/msi/x64 tmp/msi/x86

	@if ! command -v candle >/dev/null || ! command -v light >/dev/null; then \
		echo "❌ WiX Toolset не установлен (candle, light)"; \
		exit 1; \
	fi

	cp "$(BINARY_DIR)/ruvname-windows-x64-v$(PKGVERSION)-gui.exe" tmp/msi/x64/ruvname.exe
	cp "$(BINARY_DIR)/ruvname-windows-x86-v$(PKGVERSION)-gui.exe" tmp/msi/x86/ruvname.exe
	cp $(CONFIG) tmp/msi/x64/
	cp $(CONFIG) tmp/msi/x86/
	cp LICENSE README.md adblock.txt tmp/msi/x64/
	cp LICENSE README.md adblock.txt tmp/msi/x86/

	cat > tmp/msi/product.wxs << EOF
<?xml version="1.0" encoding="UTF-8"?>
<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi">
  <Product Id="*" Name="RUVNAME" Language="1033" Version="$(PKGVERSION)" Manufacturer="ruvcoindev" UpgradeCode="a1b2c3d4-e5f6-7890-1234-567890abcdef">
    <Package InstallerVersion="200" Compressed="yes" InstallScope="perMachine" />
    <MajorUpgrade DowngradeErrorMessage="Уже установлена новая версия." />
    <MediaTemplate />

    <Feature Id="ProductFeature" Title="RUVNAME" Level="1">
      <ComponentGroupRef Id="ProductComponents" />
    </Feature>

    <Directory Id="TARGETDIR" Name="SourceDir">
      <Directory Id="ProgramFilesFolder">
        <Directory Id="INSTALLFOLDER" Name="RUVNAME" />
      </Directory>
    </Directory>

    <ComponentGroup Id="ProductComponents" Directory="INSTALLFOLDER">
      <Component Id="x64App" Guid="*">
        <File Source="x64/ruvname.exe" KeyPath="yes" />
        <File Source="x64/$(CONFIG)" />
        <File Source="x64/LICENSE" />
        <File Source="x64/README.md" />
        <File Source="x64/adblock.txt" />
      </Component>
      <Component Id="x86App" Guid="*">
        <File Source="x86/ruvname.exe" />
        <File Source="x86/$(CONFIG)" />
        <File Source="x86/LICENSE" />
        <File Source="x86/README.md" />
        <File Source="x86/adblock.txt" />
      </Component>
    </ComponentGroup>

    <Property Id="ARPPRODUCTICON" Value="icon.ico" />
    <Property Id="ALLUSERS" Value="1" />
    <Icon Id="icon.ico" SourceFile="img/logo/ruvname.ico" />
  </Product>
</Wix>
EOF

	cd tmp/msi && candle product.wxs -out product.wixobj
	cd tmp/msi && light product.wixobj -o "$(CURDIR)/$(MSI_DIR)/ruvname-windows-v$(PKGVERSION).msi"
	@rm -rf tmp/msi
	@echo "✅ .msi создан: $(MSI_DIR)/ruvname-windows-v$(PKGVERSION).msi"

# === Сборка .AppImage ===
.PHONY: appimage

appimage: build-nogui
	@echo "📦 Сборка .AppImage..."
	@mkdir -p $(APPIMAGE_DIR)/ruvname.AppDir

	cp target/x86_64-unknown-linux-musl/release/$(BINARY) $(APPIMAGE_DIR)/ruvname.AppDir/
	cp $(CONFIG) $(APPIMAGE_DIR)/ruvname.AppDir/
	cp img/logo/ruvname.png $(APPIMAGE_DIR)/ruvname.AppDir/ruvname.png
	cp contrib/appimage/ruvname.desktop $(APPIMAGE_DIR)/ruvname.AppDir/

	echo '#!/bin/sh' > $(APPIMAGE_DIR)/ruvname.AppDir/AppRun
	echo 'HERE="$$(dirname "$$(readlink -f "$${0}")")"' >> $(APPIMAGE_DIR)/ruvname.AppDir/AppRun
	echo 'export PATH="$$HERE:$$PATH"' >> $(APPIMAGE_DIR)/ruvname.AppDir/AppRun
	echo 'exec "$$HERE/ruvname" "$$@"' >> $(APPIMAGE_DIR)/ruvname.AppDir/AppRun

	chmod +x $(APPIMAGE_DIR)/ruvname.AppDir/AppRun
	chmod +x $(APPIMAGE_DIR)/ruvname.AppDir/ruvname

	@if [ ! -f "appimagetool" ]; then \
		wget -O appimagetool "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage" && \
		chmod +x appimagetool; \
	fi

	./appimagetool $(APPIMAGE_DIR)/ruvname.AppDir $(APPIMAGE_DIR)/ruvname-linux-x86_64-v$(PKGVERSION).AppImage
	@echo "✅ .AppImage создан: $(APPIMAGE_DIR)/ruvname-linux-x86_64-v$(PKGVERSION).AppImage"

# === Документация ===
.PHONY: docs docs-publish

docs:
	@echo "📚 Сборка документации..."
	cd book && mdbook build

docs-publish: docs
	@echo "🌍 Публикация документации на GitHub Pages..."
	@if ! command -v git >/dev/null; then \
		echo "❌ git не установлен"; \
		exit 1; \
	fi
	@if ! git remote -v | grep -q 'github.com'; then \
		echo "⚠️ Репозиторий не привязан к GitHub"; \
		exit 1; \
	fi
	@CURRENT_BRANCH=$$(git branch --show-current); \
	@git fetch origin gh-pages || echo "gh-pages не существует"
	@git checkout gh-pages 2>/dev/null || \
		(git checkout --orphan gh-pages && git rm -rf . && echo "Создана новая ветка gh-pages")
	@echo "🧹 Очистка..."
	@git rm -rf . || true
	@rm -rf .gitignore || true
	@echo "📦 Копируем book/book/html/ -> корень..."
	@cp -r book/book/html/* . || exit 1
	@echo "" > .nojekyll
	@echo "💾 Коммит..."
	@git add .
	@git config user.name "Automated CI" || true
	@git config user.email "ci@ruv.name" || true
	@git commit -m "docs: обновлено на $$(date '+%Y-%m-%d %H:%M:%S') из $$CURRENT_BRANCH"
	@echo "🚀 Публикация..."
	@git push origin gh-pages --force
	@git checkout "$$CURRENT_BRANCH" 2>/dev/null || true
	@echo "✅ Опубликовано: https://$(shell git config --get remote.origin.url | sed -E 's/.*github.com[/:]([^/]+)\\/(.+).git/\\1.github.io\\/\\2/' | sed 's/\\.git$$//')"

# === Проверка зависимостей ===
.PHONY: check-deps

check-deps:
	@for cmd in cargo make docker upx cross mdbook wix candle light appimagetool osslsigncode hdiutil; do \
		if ! command -v $$cmd >/dev/null; then \
			echo "❌ $$cmd не установлен"; \
		fi; \
	done
	@echo "✅ Зависимости проверены"
