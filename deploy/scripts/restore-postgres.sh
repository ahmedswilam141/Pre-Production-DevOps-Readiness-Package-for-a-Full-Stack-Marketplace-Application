#!/bin/bash
# TradeSpace — PostgreSQL Restore Script
# Usage: ./deploy/scripts/restore-postgres.sh <backup_file>
# Example: ./deploy/scripts/restore-postgres.sh backups/tradespace_db_20240101_020000.sql.gz
#
# ⚠️  WARNING: This will OVERWRITE the current database. Back up first if needed.

set -euo pipefail

# ─── Configuration ─────────────────────────────────────────────
if [ -f .env ]; then
    # shellcheck disable=SC2046
    export $(grep -v '^#' .env | grep -v '^$' | xargs)
fi

DB_CONTAINER="${DB_CONTAINER:-tradespace-db}"
DB_USER="${DB_USER:-postgres}"
DB_NAME="${DB_NAME:-tradespace}"

# ─── Input validation ──────────────────────────────────────────
if [ -z "${1:-}" ]; then
    echo "Usage: $0 <backup_file>"
    echo "Example: $0 backups/tradespace_db_20240101_020000.sql.gz"
    exit 1
fi

BACKUP_FILE="$1"

if [ ! -f "$BACKUP_FILE" ]; then
    echo "ERROR: Backup file not found: $BACKUP_FILE"
    exit 1
fi

# ─── Pre-flight ────────────────────────────────────────────────
if ! docker ps --format '{{.Names}}' | grep -q "^${DB_CONTAINER}$"; then
    echo "ERROR: Container '${DB_CONTAINER}' is not running."
    echo "Start it with: docker compose up -d"
    exit 1
fi

# ─── Confirmation ──────────────────────────────────────────────
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "  WARNING: This will OVERWRITE the '${DB_NAME}' database!"
echo "  Container : ${DB_CONTAINER}"
echo "  Backup    : ${BACKUP_FILE}"
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo ""
echo "Are you absolutely sure you want to proceed? (yes/N)"
read -r response

if [ "$response" != "yes" ]; then
    echo "Restore cancelled. No changes were made."
    exit 0
fi

# ─── Restore ───────────────────────────────────────────────────
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Restoring database from ${BACKUP_FILE}..."

if [[ "$BACKUP_FILE" == *.gz ]]; then
    gunzip -c "$BACKUP_FILE" | docker exec -i "${DB_CONTAINER}" psql -U "${DB_USER}" "${DB_NAME}"
else
    cat "$BACKUP_FILE" | docker exec -i "${DB_CONTAINER}" psql -U "${DB_USER}" "${DB_NAME}"
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Database restored successfully from ${BACKUP_FILE}."
