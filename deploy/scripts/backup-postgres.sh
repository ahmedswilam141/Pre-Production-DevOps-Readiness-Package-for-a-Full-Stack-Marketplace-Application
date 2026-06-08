#!/bin/bash
# TradeSpace — PostgreSQL Backup Script
# Usage: ./deploy/scripts/backup-postgres.sh
#
# Schedule via crontab (daily at 2 AM):
#   0 2 * * * /var/www/tradespace/deploy/scripts/backup-postgres.sh >> /var/log/tradespace-backup.log 2>&1

set -euo pipefail

# ─── Configuration ─────────────────────────────────────────────
# Load environment variables from .env if available
if [ -f .env ]; then
    # shellcheck disable=SC2046
    export $(grep -v '^#' .env | grep -v '^$' | xargs)
fi

# Container name — override via environment variable or falls back to default
DB_CONTAINER="${DB_CONTAINER:-tradespace-db}"
DB_USER="${DB_USER:-postgres}"
DB_NAME="${DB_NAME:-tradespace}"
BACKUP_DIR="${BACKUP_DIR:-./backups}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/tradespace_db_${TIMESTAMP}.sql.gz"
RETENTION_DAYS="${RETENTION_DAYS:-7}"

# ─── Pre-flight ────────────────────────────────────────────────
# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

# Verify the container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${DB_CONTAINER}$"; then
    echo "ERROR: Container '${DB_CONTAINER}' is not running."
    echo "Start it with: docker compose up -d"
    exit 1
fi

# ─── Backup ────────────────────────────────────────────────────
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting backup of database '${DB_NAME}'..."

docker exec "${DB_CONTAINER}" pg_dump -U "${DB_USER}" "${DB_NAME}" | gzip > "${BACKUP_FILE}"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Backup created: ${BACKUP_FILE} ($(du -sh "${BACKUP_FILE}" | cut -f1))"

# ─── Retention ─────────────────────────────────────────────────
# Remove backups older than RETENTION_DAYS days
find "${BACKUP_DIR}" -name "tradespace_db_*.sql.gz" -mtime +"${RETENTION_DAYS}" -delete
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Retention clean-up done (kept last ${RETENTION_DAYS} days)."
