#!/bin/sh

# This is a lazy script to create a .deb for Debian/Ubuntu. It installs
# RUVNAME and enables it in systemd. You can give it the PKGARCH= argument
# i.e. PKGARCH=i386 sh contrib/deb/generate.sh

if [ `pwd` != `git rev-parse --show-toplevel` ]
then
  echo "You should run this script from the top-level directory of the git repo"
  exit 1
fi



#PKGBRANCH=$(basename `git name-rev --name-only HEAD`)
PKGNAME=$(sh contrib/semver/name.sh)
PKGVERSION=$(sh contrib/semver/version.sh --bare)
PKGARCH=${PKGARCH-amd64}
PKGFILE=$PKGNAME-$PKGARCH-v$PKGVERSION-nogui.deb
PKGREPLACES=ruvname

#if [ $PKGBRANCH = "master" ]; then
#  PKGREPLACES=ruvname-develop
#fi

mkdir -p bin

FEATURES="doh"
if [ $PKGARCH = "mipsel" ]; then FEATURES=''
elif [ $PKGARCH = "mips" ]; then FEATURES=''
fi

TARGET=""
# Building nogui versions only
if [ $PKGARCH = "amd64" ]; then TARGET='x86_64-unknown-linux-musl'
elif [ $PKGARCH = "i686" ]; then TARGET='i686-unknown-linux-musl'
elif [ $PKGARCH = "mipsel" ]; then TARGET='mipsel-unknown-linux-musl'
elif [ $PKGARCH = "mips" ]; then TARGET='mips-unknown-linux-musl'
elif [ $PKGARCH = "armhf" ]; then TARGET='armv7-unknown-linux-musleabihf'
elif [ $PKGARCH = "armlf" ]; then TARGET='arm-unknown-linux-musleabi'
elif [ $PKGARCH = "arm64" ]; then TARGET='aarch64-unknown-linux-musl'
else
  echo "Specify PKGARCH=amd64,i686,mips,mipsel,armhf,armlf,arm64"
  exit 1
fi

cross build --release --no-default-features --features=$FEATURES --target $TARGET
upx target/$TARGET/release/ruvname
cp target/$TARGET/release/ruvname ./ruvname
cp target/$TARGET/release/ruvname ./bin/ruvname-linux-$PKGARCH-v$PKGVERSION-nogui

echo "Building $PKGFILE"

mkdir -p /tmp/$PKGNAME/
mkdir -p /tmp/$PKGNAME/debian/
mkdir -p /tmp/$PKGNAME/usr/bin/
mkdir -p /tmp/$PKGNAME/etc/systemd/system/

cat > /tmp/$PKGNAME/debian/changelog << EOF
Please see https://github.com/ruvcoindev/ruvname/
EOF
echo 9 > /tmp/$PKGNAME/debian/compat
cat > /tmp/$PKGNAME/debian/control << EOF
Package: $PKGNAME
Version: $PKGVERSION
Section: contrib/net
Priority: extra
Architecture: $PKGARCH
Replaces: $PKGREPLACES
Conflicts: $PKGREPLACES
Maintainer: ruvcoindev <admin@ruvcha.in>
Description: RUVNAME
 RUVNAME is an implementation of a Domain Name System
 based on a small, slowly growing blockchain. It is lightweight, self-contained,
 supported on multiple platforms and contains DNS-resolver on its own to resolve domain records
 contained in blockchain and forward DNS requests of ordinary domain zones to upstream forwarders.
EOF
cat > /tmp/$PKGNAME/debian/copyright << EOF
Please see https://github.com/ruvcoindev/ruvname/
EOF
cat > /tmp/$PKGNAME/debian/docs << EOF
Please see https://github.com/ruvcoindev/ruvname/
EOF
cat > /tmp/$PKGNAME/debian/install << EOF
usr/bin/ruvname usr/bin
etc/systemd/system/*.service etc/systemd/system
EOF
cat > /tmp/$PKGNAME/debian/postinst << EOF
#!/bin/sh -e

if ! getent group ruvname 2>&1 > /dev/null; then
  groupadd --system --force ruvname || echo "Failed to create group 'ruvname' - please create it manually and reinstall"
fi

if ! getent passwd ruvname >/dev/null 2>&1; then
    adduser --system --ingroup ruvname --disabled-password --home /var/lib/ruvname ruvname
fi

mkdir -p /var/lib/ruvname
chown ruvname:ruvname /var/lib/ruvname

if [ -f /etc/ruvname.conf ];
then
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
cat > /tmp/$PKGNAME/debian/prerm << EOF
#!/bin/sh
if command -v systemctl >/dev/null; then
  if systemctl is-active --quiet ruvname; then
    systemctl stop ruvname || true
  fi
  systemctl disable ruvname || true
fi
EOF

sudo cp ruvname /tmp/$PKGNAME/usr/bin/
cp contrib/systemd/*.service /tmp/$PKGNAME/etc/systemd/system/

tar -czvf /tmp/$PKGNAME/data.tar.gz -C /tmp/$PKGNAME/ \
  usr/bin/ruvname \
  etc/systemd/system/ruvname.service \
  etc/systemd/system/ruvname-default-config.service
tar -czvf /tmp/$PKGNAME/control.tar.gz -C /tmp/$PKGNAME/debian .
echo 2.0 > /tmp/$PKGNAME/debian-binary

ar -r $PKGFILE \
  /tmp/$PKGNAME/debian-binary \
  /tmp/$PKGNAME/control.tar.gz \
  /tmp/$PKGNAME/data.tar.gz

rm -rf /tmp/$PKGNAME
