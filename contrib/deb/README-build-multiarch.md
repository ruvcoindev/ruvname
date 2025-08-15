# 🛠 Инструкция: `build-multiarch.sh`

Этот скрипт предназначен для **мультиархитектурной сборки** `ruvname` под различные операционные системы и архитектуры. Он автоматически генерирует установочные пакеты:

- `.deb` — для Debian/Ubuntu (Linux)
- `.zip` — для Windows
- `.dmg` — для macOS

Поддерживается сборка **с GUI и без GUI**.

---

## 📦 Поддерживаемые платформы

| Платформа | Архитектура | Формат | GUI |
|----------|------------|--------|-----|
| Linux | amd64, i686, arm64, armhf | `.deb` | ❌ Только `nogui` |
| Windows | x64, x86 | `.zip` | ✅ Да |
| macOS | Intel (x64), Apple Silicon (arm64) | `.dmg`, `.tar.gz` | ❌ (GUI не поддерживается) |

Имена файлов включают:

ruvname-{os}-{arch}-v{version}-{nogui|gui}.{ext}


Примеры:
- `ruvname-linux-amd64-v0.1.0-nogui.deb`
- `ruvname-windows-x64-v0.1.0-gui.zip`
- `ruvname-macos-universal-v0.1.0-nogui.dmg`

---

## ⚙️ Требования

### Общие:
- `bash` (не `sh`)
- `git`
- `cargo`
- `docker` (для кросс-компиляции)

### Linux (Debian/Ubuntu):
```bash
sudo apt install -y \
    pkg-config \
    musl-tools \
    upx \
    libglib2.0-dev \
    libcairo2-dev \
    libpango1.0-dev \
    libgtk-3-dev \
    libwebkit2gtk-4.0-dev \
    docker.io
    
    macOS:
Установленный brew
upx: brew install upx
hdiutil — встроен
Windows:
WSL2 (рекомендуется)
Или запуск через GitHub Actions

Установка cross
Скрипт использует cross для кросс-компиляции. Установите из main ветки:

cargo uninstall cross
cargo install cross --git https://github.com/cross-rs/cross --branch main

Как использовать
Запустите из корня репозитория:

bash contrib/deb/build-multiarch.sh

Примеры
1. Только Linux .deb (nogui)

bash contrib/deb/build-multiarch.sh

2. Linux + Windows (с GUI)

ARCHS="linux-amd64,windows-x64" BUILD_GUI=true BUILD_NOGUI=true bash contrib/deb/build-multiarch.sh

3. Полная сборка (все платформы)

ARCHS="linux-amd64,windows-x64,macos-x64,macos-arm64" BUILD_GUI=true BUILD_NOGUI=true bash contrib/deb/build-multiarch.sh

Выходные файлы
После сборки:

.deb → bin/deb/
.zip → bin/win/
.dmg → bin/macos/

Пример:

bin/
├── deb/
│   └── ruvname-linux-amd64-v0.1.0-nogui.deb
├── win/
│   ├── ruvname-windows-x64-v0.1.0-nogui.zip
│   └── ruvname-windows-x64-v0.1.0-gui.zip
└── macos/
    └── ruvname-macos-universal-v0.1.0-nogui.dmg

Особенности
GUI доступен только для Windows (через web-view)
macOS собирается локально (нельзя через cross)
UPX используется для сжатия бинарников
Автоматически определяет версию из Cargo.toml

Автоматизация
Рекомендуется использовать с GitHub Actions. Пример workflow:

on: [push]
jobs:
  release:
    runs-on: ubuntu-22.04
    steps:
      - uses: actions/checkout@v4
      - run: |
          ARCHS="linux-amd64" BUILD_NOGUI=true bash contrib/deb/build-multiarch.sh
      - uses: actions/upload-artifact@v3
        with:
          path: bin/deb/

Проблемы
GLIBC_2.28 not found
→ Убедитесь, что cross установлен из main, а не crates.io.

pkg-config: glib-2.0 not found
→ Установите libglib2.0-dev и другие -dev пакеты.

Не собирается macOS
→ Сборка macOS работает только на macOS.

Лицензия
Этот скрипт и инструкция распространяются под той же лицензией, что и ruvname.


---


