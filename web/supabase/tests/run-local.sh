#!/usr/bin/env bash
# Applies the migrations to a throwaway local Postgres database and runs the RLS checks.
# Needs a local Postgres you can reach with `psql` as a superuser (e.g. PGUSER=postgres).
set -euo pipefail
cd "$(dirname "$0")/.."
DB="fcr_rls_test_$$"
createdb "$DB"
trap 'dropdb --if-exists "$DB"' EXIT
psql -q -v ON_ERROR_STOP=1 -d "$DB" -f tests/auth_stub.sql
for f in migrations/*.sql; do psql -q -v ON_ERROR_STOP=1 -d "$DB" -f "$f"; done
psql -q -v ON_ERROR_STOP=1 -d "$DB" -f tests/rls_test.sql
