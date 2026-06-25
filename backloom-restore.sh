#!/bin/bash
# ================================================================
# Backloom v1.0 — Restore Script
# Usage: bash backloom-restore.sh /path/to/backloom-TIMESTAMP.tar.gz
#
# Run on a new VPS/laptop after downloading backup from cloud:
#   rclone copy gdrive:BackloomBackupsHermes/<file>.tar.gz .
# ================================================================

# ---- Same as backup config ----
DB_CONTAINERS=(
  "postgres|postgres|hermes|***|hermesdb"
  "secondbrain-db|postgres|secondbrain|sb123456|secondbrain"
)

COMPOSE_DIRS=(
  "/root/projects/secondbrain"
  "/root/projects/secondbrain-old"
  "/root/projects/subtrack-id/backend"
  "/root/pgadmin"
  "/root/npm"
  "/root/subtrack-id/backend"
  "/root/core-stack"
)

set -e

if [[ -z "$1" ]]; then
  echo "Usage: bash backloom-restore.sh /path/to/backloom-TIMESTAMP.tar.gz"
  exit 1
fi

BACKUP_FILE="$1"
TMP_DIR="/tmp/backloom-restore"
rm -rf "$TMP_DIR" && mkdir -p "$TMP_DIR"

echo "==> [1/6] Extracting backup..."
tar -xzf "$BACKUP_FILE" -C "$TMP_DIR"
INNER=$(find "$TMP_DIR" -maxdepth 1 -type d -name "backup_*" | head -1)

echo "==> [2/6] Restoring agent files to ~/ ..."
tar -xzf "${INNER}/agent-files.tar.gz" -C ~

echo "==> [3/6] Starting database containers..."
for d in "${COMPOSE_DIRS[@]}"; do
  [[ -f "${d}/docker-compose.yml" ]] || continue
  echo "    - ${d#$HOME/}"
  (cd "$d" && docker compose up -d 2>/dev/null) || true
done
echo "    Waiting 10s for databases to be ready..."
sleep 10

echo "==> [4/6] Restoring database data..."
for entry in "${DB_CONTAINERS[@]}"; do
  IFS='|' read -r container db_type user pass dbname <<< "$entry"
  echo "    - ${container} (${db_type})"
  case "$db_type" in
    postgres)
      f="${INNER}/db/${container}.sql"
      if [[ -f "$f" ]]; then
        docker exec -i -e PGPASSWORD="$pass" "$container" psql -U "$user" < "$f"
      else
        echo "      [SKIP] dump not found"
      fi
      ;;
    mysql)
      f="${INNER}/db/${container}.sql"
      if [[ -f "$f" ]]; then
        docker exec -i -e MYSQL_PWD="$pass" "$container" mysql -u "$user" < "$f"
      else
        echo "      [SKIP] dump not found"
      fi
      ;;
    mongo)
      f="${INNER}/db/${container}.archive"
      if [[ -f "$f" ]]; then
        docker exec -i "$container" mongorestore --archive < "$f"
      else
        echo "      [SKIP] dump not found"
      fi
      ;;
  esac
done

echo "==> [5/6] Loading Docker images..."
if [[ -d "${INNER}/images" ]]; then
  for img in "${INNER}/images/"*.tar; do
    [[ -f "$img" ]] || continue
    echo "    - $(basename "$img")"
    docker load -i "$img" 2>/dev/null || echo "      [WARN] Failed to load $img"
  done
else
  echo "    [SKIP] No images in backup (pull from Docker Hub)"
fi

echo "==> [5.5/6] Starting all services..."
find ~ -maxdepth 5 -name "docker-compose*.yml" ! -path '*/.git/*' 2>/dev/null \
| while read -r f; do dirname "$f"; done | sort -u \
| while read -r dir; do
  echo "    - ${dir#$HOME/}"
  (cd "$dir" && docker compose up -d) || echo "      [WARN] failed: $dir"
done

echo "==> [6/6] All done."
echo ""
docker ps --format '  {{.Names}}  →  {{.Status}}'
echo ""
echo "Note: Containers run via 'docker run' (not compose) need manual restart."
echo "Ref:  cat ${INNER}/containers.txt"
