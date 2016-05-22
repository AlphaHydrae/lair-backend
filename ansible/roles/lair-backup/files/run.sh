#!/usr/bin/env bash
cd /var/lib/lair
/usr/local/bin/docker-compose -p lair run --rm --no-deps backup
