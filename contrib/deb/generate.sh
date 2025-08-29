#!/bin/bash

set -e
set -u

echo "=== Сборка .deb пакета для RUVNAME ==="

# === Определение путей ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../" && pwd)"
BUILD_DIR="$ROOT_DIR/target/deb-build"
TMP_DIR="/tmp/ruvname-deb-$$"

# === Получение версии ===
if [ ! -f "$ROOT_DIR/Cargo.toml" ]; then
    echo "❌ Не найден Cargo.toml"
    exit 1
fi

VERSION=$(grep -m1 '^\s*version\s*=' "$ROOT_DIR/Cargo.toml" | sed -E 's/.*"([^"]+)".*/\1/')
if [ -z "$VERSION" ]; then
    echo "❌ Не удалось извлечь версию"
    exit 1
fi

echo "📦 Версия: $VERSION"

# === Параметры ===
PKGARCH=${PKGARCH:-amd64}
PKGNAME=ruvname
PKGFILE_SUFFIX=""
TARGET=""

# === Сопоставление архитектур и target ===
case "$PKGARCH" in
    amd64)
        TARGET=x86_64-unknown-linux-musl
        ;;
    i686)
        TARGET=i686-unknown-linux-musl
        ;;
    armhf)
        TARGET=armv7-unknown-linux-musleabihf
        ;;
    armlf)
        TARGET=arm-unknown-linux-musleabi
        ;;
    arm64)
        TARGET=aarch64-unknown-linux-musl
        ;;
    mips)
        TARGET=mips-unknown-linux-musl
        ;;
    mipsel)
        TARGET=mipsel-unknown-linux-musl
        ;;
    *)
        echo "❌ Неверная архитектура: $PKGARCH"
        echo "   Допустимые: amd64, i686, armhf, armlf, arm64, mips, mipsel"
        exit 1
        ;;
esac

# === Флаги сборки ===
FEATURES=${FEATURES:-doh}
if [[ "$PKGARCH" == "mips" || "$PKGARCH" == "mipsel" ]]; then
    FEATURES=""
fi

# === Определяем, с GUI или без ===
if [[ "$FEATURES" == *"webgui"* ]]; then
    PKGFILE_SUFFIX=""
    echo "🖼️  Сборка с GUI (webgui)"
else
    PKGFILE_SUFFIX="-nogui"
    echo "🔧 Сборка без GUI"
fi

# === Имя пакета — без "heads/" ===
PKGFILE="${PKGNAME}-${PKGARCH}-v${VERSION}${PKGFILE_SUFFIX}.deb"
echo "📁 Имя пакета: $PKGFILE"

# === Проверка зависимостей ===
if ! command -v cross &> /dev/null; then
    echo "❌ Установите cross: cargo install cross"
    exit 1
fi

if ! command -v dpkg-deb &> /dev/null; then
    echo "❌ Установите dpkg-dev: sudo apt install dpkg-dev"
    exit 1
fi

# === Сборка бинарника ===
echo "🔧 Собираем для $TARGET..."
cross build --target "$TARGET" --release --no-default-features --features="$FEATURES"

# === Подготовка временной папки ===
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR/DEBIAN"
mkdir -p "$TMP_DIR/usr/bin"
mkdir -p "$TMP_DIR/etc/systemd/system"
mkdir -p "$TMP_DIR/etc"

# === Копирование файлов ===
cp "$ROOT_DIR/target/$TARGET/release/ruvname" "$TMP_DIR/usr/bin/ruvname"

# UPX сжатие (максимальное)
if command -v upx &> /dev/null; then
    echo "📦 Сжимаем бинарник с UPX (--best --lzma)..."
    upx --best --lzma "$TMP_DIR/usr/bin/ruvname" || echo "UPX: пропущено"
fi

# systemd юниты
cp "$ROOT_DIR/contrib/systemd/ruvname.service" "$TMP_DIR/etc/systemd/system/"
cp "$ROOT_DIR/contrib/systemd/ruvname-default-config.service" "$TMP_DIR/etc/systemd/system/"

# Конфиг (если есть)
if [ -f "$ROOT_DIR/contrib/deb/files/etc/ruvname.conf" ]; then
    cp "$ROOT_DIR/contrib/deb/files/etc/ruvname.conf" "$TMP_DIR/etc/ruvname.conf"
fi

# === DEBIAN/control ===
cat > "$TMP_DIR/DEBIAN/control" << EOF
Package: ruvname
Version: $VERSION
Section: net
Priority: optional
Architecture: $PKGARCH
Depends: libc6
Replaces: ruvname
Conflicts: ruvname
Maintainer: ruvcoindev <admin@ruvcha.in>
Homepage: https://ruv.name  
Description: RUVNAME - RUVchain NAMEspace
 Сеть ruvchain, майнинг доменов, DEX, децентрализованный DNS
EOF

# === Права ===
chmod 755 "$TMP_DIR/DEBIAN"
chmod 755 "$TMP_DIR/usr/bin/ruvname"
chmod 644 "$TMP_DIR/etc/systemd/system/"*.service
[ -f "$TMP_DIR/etc/ruvname.conf" ] && chmod 644 "$TMP_DIR/etc/ruvname.conf"

# === postinst ===
cat > "$TMP_DIR/DEBIAN/postinst" << 'EOF'
#!/bin/sh
set -e

add_group_and_user() {
    if ! getent group ruvname > /dev/null 2>&1; then
        addgroup --system ruvname || echo "⚠️ Не удалось создать группу ruvname"
    fi
    if ! getent passwd ruvname > /dev/null 2>&1; then
        adduser --system --ingroup ruvname --no-create-home --disabled-password ruvname || echo "⚠️ Не удалось создать пользователя ruvname"
    fi
}

setup_directories() {
    mkdir -p /var/lib/ruvname
    chown ruvname:ruvname /var/lib/ruvname
    chmod 755 /var/lib/ruvname
}

backup_config() {
    if [ -f /etc/ruvname.conf ]; then
        BACKUP="/var/backups/ruvname.conf.$(date +%Y%m%d)"
        mkdir -p /var/backups
        cp /etc/ruvname.conf "$BACKUP"
        echo "💾 Резервная копия: $BACKUP"
    fi
}

update_config() {
    if [ -f /etc/ruvname.conf ]; then
        echo "🔄 Обновление конфига..."
        /usr/bin/ruvname -u /etc/ruvname.conf > /tmp/ruvname.conf.new
        mv /tmp/ruvname.conf.new /etc/ruvname.conf
        chgrp ruvname /etc/ruvname.conf
    else
        echo "🆕 Создание конфига..."
        su -s /bin/sh -c '/usr/bin/ruvname -g > /etc/ruvname.conf' ruvname
        chgrp ruvname /etc/ruvname.conf
    fi
}

setup_systemd() {
    systemctl daemon-reload || true
    systemctl enable ruvname || true
    systemctl start ruvname || true
}

add_group_and_user
setup_directories
backup_config
update_config
setup_systemd

echo "✅ RUVNAME установлен. Проверьте: sudo systemctl status ruvname"
EOF

chmod 755 "$TMP_DIR/DEBIAN/postinst"

# === prerm ===
cat > "$TMP_DIR/DEBIAN/prerm" << 'EOF'
#!/bin/sh
set -e
if systemctl is-active --quiet ruvname; then
    systemctl stop ruvname || true
fi
systemctl disable ruvname || true
EOF

chmod 755 "$TMP_DIR/DEBIAN/prerm"

# === Сборка .deb ===
echo "📦 Собираем $PKGFILE..."
dpkg-deb --root-owner-group --build "$TMP_DIR" "$ROOT_DIR/$PKGFILE"

# === Очистка ===
rm -rf "$TMP_DIR"

echo "✅ Готово: $ROOT_DIR/$PKGFILE"
echo "➡️ Установка: sudo dpkg -i $PKGFILE"
