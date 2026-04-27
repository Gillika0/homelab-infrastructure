#!/bin/bash
# =============================================================
# backup.sh — Automated backup from Oracle VPS to on-premise
# Runs via cron on Node04, transfers over Tailscale
# Usage: ./backup.sh [service_name]
# =============================================================

set -euo pipefail

# ── Config (loaded from environment) ─────────────────────
BACKUP_SOURCE="${BACKUP_SOURCE:-/var/lib/docker/volumes}"
BACKUP_DEST_HOST="${BACKUP_DEST_HOST:-NODE01_TAILSCALE_IP}"
BACKUP_DEST_PATH="${BACKUP_DEST_PATH:-/mnt/personal_data/backups}"
BACKUP_USER="${BACKUP_USER:-YOUR_SSH_USER}"
DATE=$(date +%Y%m%d_%H%M%S)
LOG_FILE="/var/log/homelab-backup.log"

# ── Colors ───────────────────────────────────────────────
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# ── Check Tailscale connectivity ─────────────────────────
check_tailscale() {
    log "${YELLOW}Checking Tailscale connectivity to $BACKUP_DEST_HOST...${NC}"
    if ping -c 1 "$BACKUP_DEST_HOST" &>/dev/null; then
        log "${GREEN}✓ Tailscale connection OK${NC}"
    else
        log "${RED}✗ Cannot reach $BACKUP_DEST_HOST via Tailscale — aborting${NC}"
        exit 1
    fi
}

# ── Backup PostgreSQL databases ──────────────────────────
backup_postgres() {
    local container_name="${1:-postgres}"
    local db_name="${2:-app}"
    local backup_file="postgres_${db_name}_${DATE}.sql.gz"

    log "Backing up PostgreSQL database: $db_name"

    docker exec "$container_name" pg_dump -U postgres "$db_name" \
        | gzip \
        | ssh "${BACKUP_USER}@${BACKUP_DEST_HOST}" \
            "cat > ${BACKUP_DEST_PATH}/db/${backup_file}"

    log "${GREEN}✓ Database backup: $backup_file${NC}"
}

# ── Backup volume data ────────────────────────────────────
backup_volume() {
    local volume_name="$1"
    local backup_file="volume_${volume_name}_${DATE}.tar.gz"

    log "Backing up volume: $volume_name"

    tar -czf - -C "$BACKUP_SOURCE" "$volume_name" \
        | ssh "${BACKUP_USER}@${BACKUP_DEST_HOST}" \
            "cat > ${BACKUP_DEST_PATH}/volumes/${backup_file}"

    log "${GREEN}✓ Volume backup: $backup_file${NC}"
}

# ── Cleanup old backups (keep last 7 days) ────────────────
cleanup_old_backups() {
    log "Cleaning up backups older than 7 days on remote..."
    ssh "${BACKUP_USER}@${BACKUP_DEST_HOST}" \
        "find ${BACKUP_DEST_PATH} -name '*.gz' -mtime +7 -delete"
    log "${GREEN}✓ Cleanup complete${NC}"
}

# ── Main ─────────────────────────────────────────────────
main() {
    log "=== Starting homelab backup ==="
    check_tailscale

    # Create remote directories if they don't exist
    ssh "${BACKUP_USER}@${BACKUP_DEST_HOST}" \
        "mkdir -p ${BACKUP_DEST_PATH}/{db,volumes}"

    # Backup services — add your services here
    # backup_postgres "immich_postgres" "immich"
    # backup_volume "n8n_data"
    # backup_volume "homeassistant_config"

    cleanup_old_backups
    log "${GREEN}=== Backup completed successfully ===${NC}"
}

main "$@"
