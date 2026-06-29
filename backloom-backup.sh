#!/bin/bash
# ================================================================
# Backloom v1.0 — Backup Script (updated: 2026-06-17)
# ================================================================

set -e
shopt -s nullglob

# ---- Config ----
BACKUP_ROOT="/root/backloom-backups"
RCLONE_REMOTE="gdrive"
RCLONE_FOLDER="BackloomBackupsHermes"
LOCAL_KEEP=7
CLOUD_KEEP_DAYS=30

# ---- Folders to backup ----
INCLUDE_DIRS=(
  "knowledge"
  "secondbrain"
  "projects"
  "core-stack"
  "npm"
  "pgadmin"
  "bin"
  "xauusd-bot"
  "subtrack-id"
  ".hermes"
  "wiki"
)

# ---- Databases ----
DB_CONTAINERS=(
  "db|postgres|hermes|hermespassword|subtrack"
  "secondbrain-db|postgres|secondbrain|secondbrainpassword|secondbrain"
)

# ---- Docker images to backup ----
DOCKER_IMAGES=(
  "subtrack-api"
  "nproxy"
  "pgadmin"
)

# ---- Runtime ----
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
WORK_DIR="${BACKUP_ROOT}/backup_${TIMESTAMP}"
mkdir -p "${WORK_DIR}/db"
mkdir -p "${WORK_DIR}/images"

echo "==> [1/6] Dumping databases..."
for entry in "${DB_CONTAINERS[@]}"; do
  IFS='|' read -r container db_type user pass dbname <<< "$entry"
  echo "    - ${container} (${db_type})"
  case "$db_type" in
    postgres)
      docker exec -e PGPASSWORD="$pass" "$container" \
        pg_dumpall -U "$user" > "${WORK_DIR}/db/${container}.sql" 2>/dev/null || echo "    [WARN] ${container} dump failed"
      ;;
  esac
done

echo "==> [2/6] Archiving agent files..."
cd ~
tar -czf "${WORK_DIR}/agent-files.tar.gz" \
  --exclude='node_modules' \
  --exclude='__pycache__' \
  --exclude='venv' \
  --exclude='.venv' \
  --exclude='dist' \
  --exclude='build' \
  --exclude='.next' \
  "${INCLUDE_DIRS[@]}" \
  todo-*.md todo-carryover.sh todo-template.md *.log 2>/dev/null || true

echo "==> [2b] Dumping ChromaDB vector store..."
mkdir -p "${WORK_DIR}/chroma"
cp -r ~/.hermes/chroma/* "${WORK_DIR}/chroma/" 2>/dev/null || echo "    [WARN] ChromaDB dump failed"

docker ps -a --format '{{.Names}}	{{.Image}}	{{.Status}}' > "${WORK_DIR}/containers.txt"

echo "==> [3/6] Saving Docker images..."
for img in "${DOCKER_IMAGES[@]}"; do
  if docker image inspect "$img" &>/dev/null; then
    echo "    - ${img}"
    docker save "$img" | gzip > "${WORK_DIR}/images/${img}.tar.gz" 2>/dev/null || echo "    [WARN] ${img} save failed"
  else
    echo "    [SKIP] ${img} not found"
  fi
done

echo "==> [3b] pgvector dump (embeddings table)..."
docker exec -e PGPASSWORD="hermespassword" postgres \
  pg_dump -U hermes -d subtrack -t embeddings --data-only \
  > "${WORK_DIR}/db/pgvector-embeddings.sql" 2>/dev/null || echo "    [WARN] pgvector dump failed"

echo "==> [4/6] Packaging..."
FINAL_FILE="${BACKUP_ROOT}/backloom-${TIMESTAMP}.tar.gz"
tar -czf "$FINAL_FILE" -C "$BACKUP_ROOT" "backup_${TIMESTAMP}"
rm -rf "$WORK_DIR"

echo "==> [5/6] Uploading to cloud..."
if [[ -n "$RCLONE_REMOTE" ]]; then
  rclone copy "$FINAL_FILE" "${RCLONE_REMOTE}:${RCLONE_FOLDER}/"
  rclone delete "${RCLONE_REMOTE}:${RCLONE_FOLDER}/" \
    --min-age "${CLOUD_KEEP_DAYS}d" 2>/dev/null || true
  echo "    Uploaded: ${RCLONE_REMOTE}:${RCLONE_FOLDER}/$(basename "$FINAL_FILE")"
else
  echo "    [SKIP] No cloud remote configured"
fi

echo "==> [6/6] Cleanup local (keep ${LOCAL_KEEP})..."
ls -t "${BACKUP_ROOT}"/backloom-*.tar.gz 2>/dev/null \
  | tail -n +$((LOCAL_KEEP + 1)) | xargs -r rm -f

echo ""
echo "Done ✓  $(du -sh "$FINAL_FILE" | cut -f1)  →  $FINAL_FILE"
