#!/bin/bash

set -euo pipefail

# === Настройки ===
BUILD_GUI="${BUILD_GUI:-false}"   # true — сборка с GUI (только для Windows)
BUILD_NOGUI="${BUILD_NOGUI:-true}" # true — сборка без GUI
ARCHS="${ARCHS:-amd64,win64}"      # поддерживаемые: amd64, i686, arm64, armhf, win64, win32

OUTPUT_DIR="bin/deb"
BINARY_DIR="bin"
ZIP_DIR="bin/win"

# === Пути ===
ROOT_DIR=$(git rev-parse --show-toplevel)
cd "$ROOT_DIR"
SCRIPT_DIR="$(dirname "$0")"
GENERATE_SH="$SCRIPT_DIR/generate.sh"

if [ ! -f "$GENERATE_SH" ]; then
  echo "❌ Ошибка: не найден скрипт $GENERATE_SH"
  exit 1
fi

# === Цветные сообщения ===
print_green() { echo -e "\033[32m✅ $1\033[0m"; }
print_yellow() { echo -e "\033[33m⚠️  $1\033[0m"; }
print_red() { echo -e "\033[31m❌ $1\033[0m"; }

# === Проверка команд ===
check_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    print_red "Не хватает: $2"
    exit 1
  fi
}

echo "🔍 Проверка зависимостей..."
check_command "cargo" "Rust (https://rustup.rs)"
check_command "cross" "cargo install cross --git https://github.com/cross-rs/cross"
check_command "docker" "Docker (https://docs.docker.com/get-docker/)"
check_command "upx" "UPX (sudo apt install upx) — опционально"

# === Получение версии из Cargo.toml ===
PKGNAME=$(grep '^name' Cargo.toml | head -n1 | cut -d '"' -f2)
PKGVERSION=$(grep '^version' Cargo.toml | head -n1 | cut -d '"' -f2)

if [ -z "$PKGNAME" ] || [ -z "$PKGVERSION" ]; then
  print_red "Не удалось определить имя или версию из Cargo.toml"
  exit 1
fi

print_green "Проект: $PKGNAME v$PKGVERSION"

# === Маппинг архитектур → таргеты ===
declare -A TARGET_MAP
TARGET_MAP[amd64]="x86_64-unknown-linux-musl"
TARGET_MAP[i686]="i686-unknown-linux-musl"
TARGET_MAP[arm64]="aarch64-unknown-linux-musl"
TARGET_MAP[armhf]="armv7-unknown-linux-musleabihf"
TARGET_MAP[win64]="x86_64-pc-windows-gnu"
TARGET_MAP[win32]="i686-pc-windows-gnu"

# === Подготовка папок ===
mkdir -p "$OUTPUT_DIR" "$BINARY_DIR" "$ZIP_DIR"
rm -f "$BINARY_DIR"/ruvname-* 2>/dev/null || true

# === Сборка для каждой архитектуры ===
for arch in ${ARCHS//,/ }; do
  if [ -z "${TARGET_MAP[$arch]+isset}" ]; then
    print_red "Неподдерживаемая архитектура: $arch"
    continue
  fi

  TARGET="${TARGET_MAP[$arch]}"
  print_green "🛠  Сборка для $arch ($TARGET)"

  # --- Определяем имя бинарника и суффикс ---
  if [[ "$arch" == win* ]]; then
    BINARY_NAME="ruvname.exe"
    SUFFIX_ARCH="win64"
    [[ "$arch" == "win32" ]] && SUFFIX_ARCH="win32"
  else
    BINARY_NAME="ruvname"
    case "$arch" in
      "amd64") SUFFIX_ARCH="amd64" ;;
      "i686")  SUFFIX_ARCH="i686"  ;;
      "arm64") SUFFIX_ARCH="arm64" ;;
      "armhf") SUFFIX_ARCH="armhf" ;;
      *)       SUFFIX_ARCH="$arch" ;;
    esac
  fi

  # --- NoGUI сборка ---
  if [ "$BUILD_NOGUI" = "true" ]; then
    FEATURES=""
    if [[ "$arch" != win* ]]; then
      FEATURES="doh"
    fi

    print_yellow "  → Собираем nogui..."
    cross build --release \
      --target "$TARGET" \
      --no-default-features \
      --features="$FEATURES"

    BINARY="target/$TARGET/release/$BINARY_NAME"
    if [ ! -f "$BINARY" ]; then
      print_red "Бинарник не создан: $BINARY"
      exit 1
    fi

    cp "$BINARY" "$BINARY_DIR/ruvname-${SUFFIX_ARCH}-v${PKGVERSION}-nogui"
    upx --best --lzma "$BINARY_DIR/ruvname-${SUFFIX_ARCH}-v${PKGVERSION}-nogui" 2>/dev/null || \
      print_yellow "UPX: не удалось сжать (игнорируется)"

    # Только для Linux — генерируем .deb
    if [[ "$arch" != win* ]]; then
      PKGFILE="$OUTPUT_DIR/${PKGNAME}-${SUFFIX_ARCH}-v${PKGVERSION}-nogui.deb"
      PKGARCH="$SUFFIX_ARCH" \
      PKGVERSION="$PKGVERSION" \
      PKGNAME="$PKGNAME" \
      PKGFILE="$PKGFILE" \
      SUFFIX="nogui" \
      sh "$GENERATE_SH"
      print_green "  → .deb создан: $PKGFILE"
    fi
  fi

  # --- GUI сборка (только для Windows) ---
  if [ "$BUILD_GUI" = "true" ] && [[ "$arch" == win* ]]; then
    print_yellow "  → Собираем gui (Windows)..."
    cross build --release \
      --target "$TARGET" \
      --features="webgui"

    BINARY="target/$TARGET/release/ruvname.exe"
    if [ ! -f "$BINARY" ]; then
      print_red "GUI бинарник не создан: $BINARY"
      exit 1
    fi

    cp "$BINARY" "$BINARY_DIR/ruvname-${SUFFIX_ARCH}-v${PKGVERSION}-gui.exe"
    upx --best --lzma "$BINARY_DIR/ruvname-${SUFFIX_ARCH}-v${PKGVERSION}-gui.exe" 2>/dev/null || \
      print_yellow "UPX: не удалось сжать (игнорируется)"
  fi
done

# === Генерация .zip для Windows GUI ===
if [ "$BUILD_GUI" = "true" ]; then
  for arch in win64 win32; do
    if [[ "$ARCHS" == *"$arch"* ]]; then
      if [ -f "bin/ruvname-${arch}-v${PKGVERSION}-gui.exe" ]; then
        (
          cd bin
          zip -j "../$ZIP_DIR/ruvname-${arch}-v${PKGVERSION}-gui.zip" \
            "ruvname-${arch}-v${PKGVERSION}-gui.exe" \
            ../ruvname.toml \
            ../README.md \
            ../LICENSE \
            ../adblock.txt
        )
        print_green "📦 GUI архив: $ZIP_DIR/ruvname-${arch}-v${PKGVERSION}-gui.zip"
      fi
    fi
  done
fi

# === Генерация .zip для Windows NoGUI ===
if [ "$BUILD_NOGUI" = "true" ]; then
  for arch in win64 win32; do
    if [[ "$ARCHS" == *"$arch"* ]]; then
      if [ -f "bin/ruvname-${arch}-v${PKGVERSION}-nogui.exe" ]; then
        (
          cd bin
          zip -j "../$ZIP_DIR/ruvname-${arch}-v${PKGVERSION}-nogui.zip" \
            "ruvname-${arch}-v${PKGVERSION}-nogui.exe" \
            ../ruvname.toml \
            ../README.md \
            ../LICENSE \
            ../adblock.txt
        )
        print_green "📦 NoGUI архив: $ZIP_DIR/ruvname-${arch}-v${PKGVERSION}-nogui.zip"
      fi
    fi
  done
fi

print_green "🎉 Сборка завершена!"
echo
echo "📦 .deb пакеты: $OUTPUT_DIR/"
ls -1 "$OUTPUT_DIR/" || echo "  (нет)"
echo
echo "📦 Windows .zip: $ZIP_DIR/"
ls -1 "$ZIP_DIR/" || echo "  (нет)"
