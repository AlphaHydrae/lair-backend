#!/usr/bin/env bash
if test -f /var/lib/lair/dump.sql; then
  PGPASSWORD="$LAIR_DATABASE_PASSWORD" psql -h "$LAIR_DATABASE_HOST" -U "$LAIR_DATABASE_USERNAME" -f "$1" "$LAIR_DATABASE_NAME"
fi
