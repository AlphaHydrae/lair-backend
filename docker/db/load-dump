#!/usr/bin/env bash
set -e

export PGPASSWORD="$LAIR_DATABASE_PASSWORD"
until psql -h lair_db -U "$LAIR_DATABASE_USERNAME" -c '\l'; do
  >&2 echo "Postgres is unavailable - waiting"
  sleep 1
done

>&2 echo "Postgres is up"

PGPASSWORD="$LAIR_DATABASE_PASSWORD" psql -h "$LAIR_DATABASE_HOST" -U "$LAIR_DATABASE_USERNAME" -f "$1" "$LAIR_DATABASE_NAME"
