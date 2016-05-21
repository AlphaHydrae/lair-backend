#!/usr/bin/with-contenv bash
set -e

TYPE="$LAIR_CONTAINER_TYPE"

if [ -z "$TYPE" ]; then
  >&2 echo "$LAIR_CONTAINER_TYPE must be set"
fi

cd "/usr/src/app/docker/${TYPE}"

if [ -d cont-finish.d ]; then
  echo "Copying cont-finish.d scripts..."
  cp cont-finish.d/* /etc/cont-finish.d
fi

if [ -d services.d ]; then
  echo "Copying services.d scripts..."
  cp -R services.d/* /etc/services.d
fi

if [ -f serf.conf ]; then
  echo "Copying serf.conf..."
  cp serf.conf /etc/serf.conf
fi

if [ -d cont-init.d ]; then
  echo "Sourcing cont-init.d scripts..."
  for FILE in $(ls -1 cont-init.d); do
    source cont-init.d/$FILE
  done
fi
