#!/bin/bash

set -e
set -u  # Запрещает использование неопределённых переменных

echo "=== Сборка .deb пакета для RUVNAME (tar + ar) ==="

# === Определение путей ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../" && pwd)"
BUILD_DIR="$ROOT_DIR/target/deb-build"
TMP_DIR="/tmp/ruvname-deb-$$"

# === Получение версии (только из основного пакета) ===
if [ ! -f "$ROOT_DIR/Cargo.toml" ]; then
    echo "❌ Не найден Cargo.toml в $ROOT_DIR"
    exit 1
fi

# Извлекаем первую строку version = "..." из [package]
VERSION=$(grep -m1 '^\s*version\s*=' "$ROOT_DIR/Cargo.toml" | sed -E 's/.*"([^"]+)".*/\1/')
if [ -z "$VERSION" ]; then
    echo "❌ Не удалось извлечь версию из Cargo.toml"
    exit 1
fi

echo "📦 Версия: $VERSION"

# === Параметры ===
PKGARCH=${PKGARCH:-amd64}
PKGNAME=ruvname
PKGFILE="${PKGNAME}-${PKGARCH}-v${VERSION}.deb"

# === Сопоставление архитектур и target ===
case "$PKGARCH" in
    amd64)
        TARGET=x86_64-unknown-linux-musl
        ;;
    i686)
        TARGET=i686-unknown-linux-musl
        ;;
    mips)
        TARGET=mips-unknown-linux-musl
        ;;
    mipsel)
        TARGET=mipsel-unknown-linux-musl
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
    *)
        echo "❌ Неверная архитектура: $PKGARCH"
        echo "   Допустимые: amd64, i686, mips, mipsel, armhf, armlf, arm64"
        exit 1
        ;;
esac

# === Флаги сборки ===
FEATURES="doh"
if [[ "$PKGARCH" == "mips" || "$PKGARCH" == "mipsel" ]]; then
    FEATURES=""
fi

# === Проверка зависимостей ===
if ! command -v cross &> /dev/null; then
    echo "❌ Установите cross: cargo install cross"
    exit 1
fi

if ! command -v upx &> /dev/null; then
    echo "📦 UPX не установлен — сжатие пропущено"
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

# UPX сжатие (опционально)
if command -v upx &> /dev/null; then
    echo "📦 Сжимаем бинарник с UPX..."
    upx --best --lzma "$TMP_DIR/usr/bin/ruvname" || echo "UPX: пропущено"
fi

# systemd юниты
if [ -f "$ROOT_DIR/contrib/systemd/ruvname.service" ]; then
    cp "$ROOT_DIR/contrib/systemd/ruvname.service" "$TMP_DIR/etc/systemd/system/"
else
    echo "⚠️ Не найден ruvname.service"
fi

if [ -f "$ROOT_DIR/contrib/systemd/ruvname-default-config.service" ]; then
    cp "$ROOT_DIR/contrib/systemd/ruvname-default-config.service" "$TMP_DIR/etc/systemd/system/"
fi

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

echo "✅ RUVNAME установлен. Проверьте: systemctl status ruvname"
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

# === Сборка .deb через tar + ar ===
echo "📦 Собираем $PKGFILE..."

cd "$TMP_DIR"

# Создаём архивы
tar -czf control.tar.gz DEBIAN/control DEBIAN/postinst DEBIAN/prerm
tar -czf data.tar.gz usr/ etc/

# Создаём debian-binary
echo "2.0" > debian-binary

# Собираем .deb
dpkg-deb --build "$TMP_DIR" "$ROOT_DIR/$PKGFILE"

# Возвращаемся
cd "$ROOT_DIR"

# Очистка
rm -rf "$TMP_DIR"

echo "✅ Готово: $PKGFILE"
echo "➡️ Установка: sudo dpkg -i $PKGFILE"
