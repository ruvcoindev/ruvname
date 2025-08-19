#!/opt/bin/bash

# RUVNAME upgrade script for Keenetic routers with Entware

json=$(curl -s "https://api.github.com/repos/ruvcoindev/Ruvname/releases/latest")
upstreamver=$(echo "$json" | jq -r ".tag_name")

curver=$(ruvname -v | cut -c7-25)

changed=$(diff <(echo "$curver") <(echo "$upstreamver"))

if [ "$changed" != "" ]
then
  echo "Upgrading from $curver to $upstreamver"
  /opt/etc/init.d/S98ruvname stop
  wget https://github.com/ruvcoindev/Ruvname/releases/download/$upstreamver/ruvname-linux-mipsel-$upstreamver-nogui -O /opt/bin/ruvname
  chmod +x /opt/bin/ruvname
  /opt/etc/init.d/S98ruvname start
else
  echo "No need to upgrade, $curver is the current version"
fi