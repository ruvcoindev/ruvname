#!/bin/bash

set -e

# Получаем версию
VERSION=${VERSION:-$(cargo read-manifest | jq -r .version)}

# Создаём папку для сборки
rm -rf target/deb
mkdir -p target/deb

# Собираем бинарник через cross
cross build --target x86_64-unknown-linux-musl --release

# Упаковываем
cp target/x86_64-unknown-linux-musl/release/ruvname target/deb/

# UPX (опционально)
upx target/deb/ruvname || echo "UPX не установлен, пропускаем"

# Создаём структуру пакета
PKGDIR=ruvname-${PKGARCH}
rm -rf $PKGDIR
mkdir -p $PKGDIR/DEBIAN
mkdir -p $PKGDIR/usr/sbin
mkdir -p $PKGDIR/etc/ruvname
mkdir -p $PKGDIR/etc/init.d

# Копируем файлы
cp target/deb/ruvname $PKGDIR/usr/sbin/
cp ../init.d/ruvname $PKGDIR/etc/init.d/
cp ../ruvname.toml $PKGDIR/etc/ruvname/

# Создаём control
cat > $PKGDIR/DEBIAN/control << EOF
Package: ruvname
Version: $VERSION
Section: net
Priority: optional
Architecture: $PKGARCH
Depends: libc6
Maintainer: ruvcoindev <admin@ruvcha.in>
Description: Ruvname — децентрализованный DNS и сеть
 Сеть ruvchain, майнинг доменов, DEX
EOF

# Права
chmod +x $PKGDIR/etc/init.d/ruvname
chmod 755 $PKGDIR/DEBIAN
chmod 755 $PKGDIR/usr/sbin/ruvname

# Собираем DEB
dpkg-deb --build $PKGDIR

# Перемещаем
mv ${PKGDIR}.deb ruvname-${PKGARCH}-${VERSION}.deb
echo "Сборка завершена: ruvname-${PKGARCH}-${VERSION}.deb"