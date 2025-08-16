#!/bin/bash

# Генерация .deb пакета для RUVNAME
# Поддерживает: amd64, i686, arm64, armhf, mips, mipsel
# Использует cross и fakeroot

set -euo pipefail

# === Проверка, что скрипт запущен из корня репозитория ===
if [ "$(pwd)" != "$(git rev-parse --show-toplevel)" ]; then
  echo "❌ Ошибка: запускайте скрипт из корня репозитория"
  exit 1
fi

# === Настройки по умолчанию ===
PKGNAME=${PKGNAME:-ruvname}
PKGVERSION=${PKGVERSION:-$(grep '^version' Cargo.toml | head -n1 | cut -d '"' -f2)}
PKGARCH=${PKGARCH:-amd64}
SUFFIX=${SUFFIX:-nogui}  # nogui или gui
TARGET=${TARGET:-}
FEATURES=${FEATURES:-doh}
OUTPUT_DIR=${OUTPUT_DIR:-bin/deb}

# === Маппинг архитектур → target ===
case "$PKGARCH" in
  "amd64")
    TARGET="x86_64-unknown-linux-musl"
    ;;
  "i686")
    TARGET="i686-unknown-linux-musl"
    ;;
  "arm64")
    TARGET="aarch64-unknown-linux-musl"
    ;;
  "armhf")
    TARGET="armv7-unknown-linux-musleabihf"
    ;;
  "mips")
    TARGET="mips-unknown-linux-musl"
    ;;
  "mipsel")
    TARGET="mipsel-unknown-linux-musl"
    ;;
  *)
    echo "❌ Укажите PKGARCH: amd64, i686, arm64, armhf, mips, mipsel"
    exit 1
    ;;
esac

# === Проверка зависимостей ===
if ! command -v cross >/dev/null; then
  echo "❌ cross не установлен. Установите: cargo install cross"
  exit 1
fi

if ! command -v fakeroot >/dev/null; then
  echo "❌ fakeroot не установлен. Установите: sudo apt install fakeroot"
  exit 1
fi

if ! command -v upx >/dev/null; then
  echo "⚠️  UPX не установлен — сжатие пропущено"
  COMPRESS=false
else
  COMPRESS=true
fi

# === Подготовка ===
echo "📦 Сборка .deb пакета: $PKGNAME-$PKGARCH-v$PKGVERSION-$SUFFIX.deb"
echo "   Архитектура: $PKGARCH → $TARGET"
echo "   Флаги: --no-default-features --features=$FEATURES"

# Создаём временную директорию
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# Папка для артефактов
mkdir -p "$OUTPUT_DIR"

# === Сборка бинарника ===
echo "🛠 Сборка бинарника..."
cross build --target "$TARGET" --release --no-default-features --features="$FEATURES"

# Копируем и сжимаем
cp "target/$TARGET/release/ruvname" "$TEMP_DIR/usr/bin/ruvname"
if [ "$COMPRESS" = "true" ]; then
  upx --best --lzma "$TEMP_DIR/usr/bin/ruvname"
fi

# === Структура пакета ===
mkdir -p "$TEMP_DIR/DEBIAN"
mkdir -p "$TEMP_DIR/etc/systemd/system"
mkdir -p "$TEMP_DIR/var/lib/ruvname"

# Копируем systemd-сервисы
cp contrib/systemd/ruvname.service "$TEMP_DIR/etc/systemd/system/"
cp contrib/systemd/ruvname-default-config.service "$TEMP_DIR/etc/systemd/system/"

# === Создание control файла ===
cat > "$TEMP_DIR/DEBIAN/control" << EOF
Package: $PKGNAME
Version: $PKGVERSION
Section: contrib/net
Priority: extra
Architecture: $PKGARCH
Replaces: ruvname-develop, ruvname
Conflicts: ruvname-develop, ruvname
Maintainer: ruvcoindev <admin@ruvcha.in>
Description: RUVNAME — Decentralized DNS on Blockchain
 RUVNAME (RUVchain NAMEspace) is an implementation of a Domain Name System
 based on a small, slowly growing blockchain. It is lightweight, self-contained,
 supported on multiple platforms and contains DNS-resolver on its own to resolve domain records
 contained in blockchain and forward DNS requests of ordinary domain zones to upstream forwarders.
 .
 Supports zones: .ruv, .mesh, .node, .p2p, .tamb, .tmb, .dweb, .dht, .hub
EOF

# === postinst — post-install script ===
cat > "$TEMP_DIR/DEBIAN/postinst" << 'EOF'
#!/bin/sh -e

if ! getent group ruvname 2>&1 > /dev/null; then
  groupadd --system --force ruvname || echo "Failed to create group 'ruvname' - please create it manually and reinstall"
fi

if ! getent passwd ruvname >/dev/null 2>&1; then
    adduser --system --ingroup ruvname --disabled-password --home /var/lib/ruvname ruvname
fi

mkdir -p /var/lib/ruvname
chown ruvname:ruvname /var/lib/ruvname

if [ -f /etc/ruvname.conf ]; then
  mkdir -p /var/backups
  echo "Backing up configuration file to /var/backups/ruvname.conf.`date +%Y%m%d`"
  cp /etc/ruvname.conf /var/backups/ruvname.conf.`date +%Y%m%d`
  echo "Updating /etc/ruvname.conf"
  /usr/bin/ruvname -u /var/backups/ruvname.conf.`date +%Y%m%d` > /etc/ruvname.conf
  chgrp ruvname /etc/ruvname.conf

  if command -v systemctl >/dev/null; then
    systemctl daemon-reload >/dev/null || true
    systemctl enable ruvname || true
    systemctl start ruvname || true
  fi
else
  echo "Generating initial configuration file /etc/ruvname.conf"
  echo "Please familiarise yourself with this file before starting RUVNAME"
  sh -c 'umask 0027 && /usr/bin/ruvname -g > /etc/ruvname.conf'
  chgrp ruvname /etc/ruvname.conf
fi
EOF

# === prerm — pre-remove script ===
cat > "$TEMP_DIR/DEBIAN/prerm" << 'EOF'
#!/bin/sh
if command -v systemctl >/dev/null; then
  if systemctl is-active --quiet ruvname; then
    systemctl stop ruvname || true
  fi
  systemctl disable ruvname || true
fi
EOF

# === Права ===
chmod 755 "$TEMP_DIR/DEBIAN"
chmod 755 "$TEMP_DIR/DEBIAN/postinst"
chmod 755 "$TEMP_DIR/DEBIAN/prerm"
chmod 755 "$TEMP_DIR/usr/bin/ruvname"

# === Имя выходного файла ===
PKGFILE="$OUTPUT_DIR/${PKGNAME}-linux-${PKGARCH}-v${PKGVERSION}-${SUFFIX}.deb"

# === Сборка .deb ===
echo "📦 Создание пакета: $PKGFILE"
fakeroot dpkg-deb --build "$TEMP_DIR" "$PKGFILE"

# === Проверка ===
if [ -f "$PKGFILE" ]; then
  echo "✅ .deb успешно создан: $PKGFILE"
  echo "   Размер: $(du -h "$PKGFILE" | cut -f1)"
else
  echo "❌ Ошибка: файл $PKGFILE не создан"
  exit 1
fi

# === Информация о пакете ===
echo "📋 Информация о пакете:"
dpkg-deb --info "$PKGFILE" || echo "dpkg-deb --info недоступен"

# === Очистка (уже через trap) ===
