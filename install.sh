#!/bin/bash
# ================================================================
# Backloom v1.0 — Installer
# AI Agent Backup & Restore for self-hosted VPS setups
# ================================================================
# Usage: curl -sSL https://get.backloom.io | bash
#    or: bash install.sh

set -eo pipefail

# ---- Colors ----
R='\033[0;31m' G='\033[0;32m' Y='\033[1;33m'
B='\033[0;34m' C='\033[0;36m' W='\033[1m' D='\033[2m' N='\033[0m'

# ---- Paths ----
BACKLOOM_DIR="${HOME}/.backloom"
BACKUP_SCRIPT="${HOME}/backloom-backup.sh"
RESTORE_SCRIPT="${HOME}/backloom-restore.sh"
BACKUP_DIR="${HOME}/backloom-backups"

# ---- Global state ----
RCLONE_REMOTE=""
RCLONE_FOLDER=""
CRON_EXPR=""
DETECTED_DIRS=()
DETECTED_DBS=()
DETECTED_COMPOSE_DIRS=()
HAS_TODOS=false

# ---- Helpers ----
info()    { echo -e "${B}[•]${N} $*"; }
ok()      { echo -e "${G}[✓]${N} $*"; }
warn()    { echo -e "${Y}[!]${N} $*"; }
die()     { echo -e "${R}[✗]${N} $*" >&2; exit 1; }
ask()     { echo -en "${C}[?]${N} $* "; }
rule()    { echo -e "${D}──────────────────────────────────────────────${N}"; }
section() { echo ""; echo -e "${W}$*${N}"; rule; }

# ================================================================
# BANNER
# ================================================================
banner() {
  echo ""
  echo -e "  ${W}${C}╔══════════════════════════════════════════╗${N}"
  echo -e "  ${W}${C}║  ⚡ BACKLOOM  v1.0                       ║${N}"
  echo -e "  ${W}${C}║  AI Agent Backup & Restore               ║${N}"
  echo -e "  ${W}${C}╚══════════════════════════════════════════╝${N}"
  echo ""
  echo "  Backup your AI agent's knowledge, skills, databases"
  echo "  & configs — then restore anywhere with 1 command."
  echo ""
}

# ================================================================
# PREREQUISITES
# ================================================================
check_prereqs() {
  section "Checking prerequisites"

  [[ $EUID -eq 0 ]] || die "Run as root: sudo bash install.sh"
  ok "Running as root"

  command -v docker &>/dev/null \
    || die "Docker not found. Install: https://docs.docker.com/engine/install/"
  ok "Docker: $(docker --version | awk '{print $3}' | tr -d ',')"

  command -v curl &>/dev/null || command -v wget &>/dev/null \
    || die "curl or wget required"
  ok "curl/wget: available"

  if command -v rclone &>/dev/null; then
    ok "rclone: $(rclone --version 2>/dev/null | head -1 | awk '{print $2}')"
    RCLONE_INSTALLED=true
  else
    warn "rclone not installed yet — will install during setup"
    RCLONE_INSTALLED=false
  fi
}

# ================================================================
# AUTO-DETECT
# ================================================================
detect_agent_folders() {
  section "Scanning agent folders"

  local PATTERNS=(
    knowledge skills playbooks secondbrain second-brain
    memory rag-index notes brain agent hermes
    projects core-stack npm pgadmin bin
    xauusd-bot trading subtrack-id
  )

  for p in "${PATTERNS[@]}"; do
    if [[ -d "${HOME}/${p}" ]]; then
      DETECTED_DIRS+=("$p")
      info "Found: ~/${p}"
    fi
  done

  local todo_count
  todo_count=$(find "${HOME}" -maxdepth 1 -name "todo-*.md" 2>/dev/null | wc -l || echo 0)
  if (( todo_count > 0 )); then
    HAS_TODOS=true
    info "Found: ${todo_count} todo-*.md + carryover scripts"
  fi

  [[ ${#DETECTED_DIRS[@]} -gt 0 ]] || warn "No standard agent folders found"
}

detect_databases() {
  section "Scanning database containers"

  docker info &>/dev/null || { warn "Docker daemon not accessible"; return; }

  while IFS=$'\t' read -r name image; do
    local db_type=""
    echo "$image" | grep -qi "postgres\|pgvector" && db_type="postgres"
    echo "$image" | grep -qi "mysql\|mariadb"     && db_type="mysql"
    echo "$image" | grep -qi "^mongo"             && db_type="mongo"
    [[ -z "$db_type" ]] && continue

    local envs user="" pass="" dbname=""
    envs=$(docker inspect "$name" --format '{{range .Config.Env}}{{println .}}{{end}}' 2>/dev/null || true)

    case "$db_type" in
      postgres)
        user=$(echo "$envs"   | grep '^POSTGRES_USER='     | head -1 | cut -d= -f2-)
        pass=$(echo "$envs"   | grep '^POSTGRES_PASSWORD=' | head -1 | cut -d= -f2-)
        dbname=$(echo "$envs" | grep '^POSTGRES_DB='       | head -1 | cut -d= -f2-)
        user="${user:-postgres}"
        ;;
      mysql)
        user="root"
        pass=$(echo "$envs"   | grep '^MYSQL_ROOT_PASSWORD=' | head -1 | cut -d= -f2-)
        dbname=$(echo "$envs" | grep '^MYSQL_DATABASE='      | head -1 | cut -d= -f2-)
        ;;
      mongo)
        user=$(echo "$envs"   | grep '^MONGO_INITDB_ROOT_USERNAME=' | head -1 | cut -d= -f2-)
        pass=$(echo "$envs"   | grep '^MONGO_INITDB_ROOT_PASSWORD=' | head -1 | cut -d= -f2-)
        ;;
    esac

    DETECTED_DBS+=("${name}|${db_type}|${user}|${pass}|${dbname}")
    info "Found DB: ${name} (${db_type}${dbname:+, db=$dbname})"

  done < <(docker ps --format $'{{.Names}}\t{{.Image}}')

  [[ ${#DETECTED_DBS[@]} -gt 0 ]] || warn "No database containers found"
}

detect_compose_files() {
  section "Scanning docker-compose files"

  while IFS= read -r f; do
    local d; d=$(dirname "$f")
    DETECTED_COMPOSE_DIRS+=("$d")
    info "Found: ${d#$HOME/}"
  done < <(find "${HOME}" -maxdepth 5 -name "docker-compose*.yml" \
    ! -path '*/.git/*' 2>/dev/null || true)
}

# ================================================================
# SUMMARY & CONFIRM
# ================================================================
show_summary() {
  section "Detection Summary"

  echo -e "  ${W}Agent Folders:${N}"
  if [[ ${#DETECTED_DIRS[@]} -gt 0 ]]; then
    printf '    • %s\n' "${DETECTED_DIRS[@]}"
  else
    echo "    (none detected)"
  fi

  echo -e "\n  ${W}Databases:${N}"
  if [[ ${#DETECTED_DBS[@]} -gt 0 ]]; then
    for db in "${DETECTED_DBS[@]}"; do
      IFS='|' read -r n t _ _ dn <<< "$db"
      echo "    • $n ($t${dn:+, db=$dn})"
    done
  else
    echo "    (none detected)"
  fi

  echo -e "\n  ${W}Docker Compose Services:${N}"
  if [[ ${#DETECTED_COMPOSE_DIRS[@]} -gt 0 ]]; then
    for d in "${DETECTED_COMPOSE_DIRS[@]}"; do
      echo "    • ${d#$HOME/}"
    done
  else
    echo "    (none detected)"
  fi

  echo ""
  ask "Proceed with this configuration? [Y/n]"
  read -r confirm
  [[ "$confirm" =~ ^[Nn] ]] && { echo "Cancelled."; exit 0; }
}

# ================================================================
# RCLONE / CLOUD STORAGE
# ================================================================
setup_rclone() {
  section "Cloud Storage Setup"

  # Install rclone if missing
  if [[ "$RCLONE_INSTALLED" == "false" ]]; then
    info "Installing rclone..."
    curl -sSL https://rclone.org/install.sh | bash
    ok "rclone installed"
  fi

  # If gdrive already configured
  if rclone listremotes 2>/dev/null | grep -q "^gdrive:$"; then
    ok "Remote 'gdrive' already configured — reusing it"
    RCLONE_REMOTE="gdrive"
    ask "Drive folder for backups [BackloomBackups]:"
    read -r RCLONE_FOLDER
    RCLONE_FOLDER="${RCLONE_FOLDER:-BackloomBackups}"
    return
  fi

  echo "  Choose where to store backups:"
  echo ""
  echo "  1) Google Drive        (free 15 GB)"
  echo "  2) Backblaze B2        (cheap, \$0.006/GB/mo)"
  echo "  3) AWS S3"
  echo "  4) Local only          (no cloud upload)"
  echo ""
  ask "Choice [1]:"
  read -r ch; ch="${ch:-1}"

  case "$ch" in
    1)
      RCLONE_REMOTE="gdrive"
      echo ""
      warn "Setup wizard will open. When asked 'Use auto config?' → answer N"
      warn "Then run the shown command on your laptop, paste the token back here."
      echo ""
      rclone config
      ask "Drive folder name [BackloomBackups]:"
      read -r RCLONE_FOLDER
      RCLONE_FOLDER="${RCLONE_FOLDER:-BackloomBackups}"
      ;;
    2)
      RCLONE_REMOTE="b2"
      ask "Backblaze Account ID:"; read -r b2a
      ask "Backblaze App Key:"; read -r b2k
      ask "Bucket name:"; read -r RCLONE_FOLDER
      rclone config create b2 b2 account "$b2a" key "$b2k"
      ;;
    3)
      RCLONE_REMOTE="s3"
      ask "AWS Access Key ID:"; read -r ak
      ask "AWS Secret Access Key:"; read -r as
      ask "Region [ap-southeast-1]:"; read -r ar; ar="${ar:-ap-southeast-1}"
      ask "S3 Bucket name:"; read -r RCLONE_FOLDER
      rclone config create s3 s3 provider AWS \
        access_key_id "$ak" secret_access_key "$as" region "$ar"
      ;;
    4)
      RCLONE_REMOTE=""
      warn "Local-only mode — move backup files offsite manually!"
      ;;
  esac

  [[ -n "$RCLONE_REMOTE" ]] && ok "Cloud: ${RCLONE_REMOTE}:${RCLONE_FOLDER}/"
}

# ================================================================
# SCHEDULE
# ================================================================
setup_schedule() {
  section "Backup Schedule"

  echo "  How often should Backloom run?"
  echo ""
  echo "  1) Daily at 3:00 AM    (recommended)"
  echo "  2) Daily at custom hour"
  echo "  3) Weekly — Sunday 3 AM"
  echo "  4) Manual only"
  echo ""
  ask "Choice [1]:"
  read -r ch; ch="${ch:-1}"

  case "$ch" in
    1) CRON_EXPR="0 3 * * *" ;;
    2) ask "Hour (0-23):"; read -r h; CRON_EXPR="0 ${h} * * *" ;;
    3) CRON_EXPR="0 3 * * 0" ;;
    4) CRON_EXPR="" ;;
  esac

  [[ -n "$CRON_EXPR" ]] && ok "Schedule: ${CRON_EXPR}" \
    || warn "No schedule — run backloom-backup.sh manually"
}

# ================================================================
# GENERATE SCRIPTS
# ================================================================
generate_scripts() {
  section "Generating scripts"
  mkdir -p "$BACKLOOM_DIR" "$BACKUP_DIR"

  # ---------------------------------------------------------------
  # backloom-backup.sh
  # Part 1: installer-time config (expanded)
  # ---------------------------------------------------------------
  cat > "$BACKUP_SCRIPT" << EOF
#!/bin/bash
# ================================================================
# Backloom v1.0 — Backup Script
# Auto-generated by install.sh — reconfigure by re-running installer
# ================================================================

# ---- Config (edit here if needed) ----
BACKUP_ROOT="${BACKUP_DIR}"
RCLONE_REMOTE="${RCLONE_REMOTE}"
RCLONE_FOLDER="${RCLONE_FOLDER}"
LOCAL_KEEP=7           # keep N most recent local backups
CLOUD_KEEP_DAYS=30     # delete cloud backups older than N days

# ---- Folders to backup (add new top-level ~/folders here) ----
INCLUDE_DIRS=(
$(printf '  "%s"\n' "${DETECTED_DIRS[@]:-}")
)

# ---- Databases (format: "container|type|user|pass|dbname") ----
# type: postgres | mysql | mongo
# Add new DB containers here
DB_CONTAINERS=(
$(printf '  "%s"\n' "${DETECTED_DBS[@]:-}")
)
EOF

  # Part 2: runtime logic (single-quote EOF — no expansion)
  cat >> "$BACKUP_SCRIPT" << 'RUNTIME'

# ---- Runtime ----
set -e
shopt -s nullglob

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
WORK_DIR="${BACKUP_ROOT}/backup_${TIMESTAMP}"
mkdir -p "${WORK_DIR}/db"

echo "==> [1/5] Dumping databases..."
for entry in "${DB_CONTAINERS[@]}"; do
  IFS='|' read -r container db_type user pass dbname <<< "$entry"
  echo "    - ${container} (${db_type})"
  case "$db_type" in
    postgres)
      docker exec -e PGPASSWORD="$pass" "$container" \
        pg_dumpall -U "$user" > "${WORK_DIR}/db/${container}.sql"
      ;;
    mysql)
      docker exec -e MYSQL_PWD="$pass" "$container" \
        mysqldump -u "$user" --all-databases > "${WORK_DIR}/db/${container}.sql"
      ;;
    mongo)
      docker exec "$container" mongodump --archive > "${WORK_DIR}/db/${container}.archive"
      ;;
  esac
done

echo "==> [2/5] Archiving agent files..."
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
  todo-*.md todo-carryover.sh todo-template.md *.log 2>/dev/null

docker ps -a --format '{{.Names}}\t{{.Image}}\t{{.Status}}' > "${WORK_DIR}/containers.txt"

echo "==> [3/5] Packaging..."
FINAL_FILE="${BACKUP_ROOT}/backloom-${TIMESTAMP}.tar.gz"
tar -czf "$FINAL_FILE" -C "$BACKUP_ROOT" "backup_${TIMESTAMP}"
rm -rf "$WORK_DIR"

echo "==> [4/5] Uploading to cloud..."
if [[ -n "$RCLONE_REMOTE" ]]; then
  rclone copy "$FINAL_FILE" "${RCLONE_REMOTE}:${RCLONE_FOLDER}/"
  rclone delete "${RCLONE_REMOTE}:${RCLONE_FOLDER}/" \
    --min-age "${CLOUD_KEEP_DAYS}d" 2>/dev/null || true
  echo "    Uploaded: ${RCLONE_REMOTE}:${RCLONE_FOLDER}/$(basename "$FINAL_FILE")"
else
  echo "    [SKIP] No cloud remote configured"
fi

echo "==> [5/5] Cleanup local (keep ${LOCAL_KEEP})..."
ls -t "${BACKUP_ROOT}"/backloom-*.tar.gz 2>/dev/null \
  | tail -n +$((LOCAL_KEEP + 1)) | xargs -r rm -f

echo ""
echo "Done ✓  $(du -sh "$FINAL_FILE" | cut -f1)  →  $FINAL_FILE"
RUNTIME

  chmod +x "$BACKUP_SCRIPT"
  ok "Generated: $BACKUP_SCRIPT"

  # ---------------------------------------------------------------
  # backloom-restore.sh
  # Part 1: installer-time config
  # ---------------------------------------------------------------
  cat > "$RESTORE_SCRIPT" << EOF
#!/bin/bash
# ================================================================
# Backloom v1.0 — Restore Script
# Usage: bash backloom-restore.sh /path/to/backloom-TIMESTAMP.tar.gz
#
# Run on a new VPS/laptop after downloading backup from cloud:
#   rclone copy ${RCLONE_REMOTE:-gdrive}:${RCLONE_FOLDER:-BackloomBackups}/<file>.tar.gz .
# ================================================================

# ---- Same as backup config ----
DB_CONTAINERS=(
$(printf '  "%s"\n' "${DETECTED_DBS[@]:-}")
)

COMPOSE_DIRS=(
$(printf '  "%s"\n' "${DETECTED_COMPOSE_DIRS[@]:-}")
)
EOF

  # Part 2: runtime logic
  cat >> "$RESTORE_SCRIPT" << 'RUNTIME'

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

echo "==> [5/6] Starting all services..."
find ~ -maxdepth 5 -name "docker-compose*.yml" ! -path '*/.git/*' 2>/dev/null \
| while read -r f; do
  dir=$(dirname "$f")
  echo "    - ${dir#$HOME/}"
  (cd "$dir" && docker compose up -d) || echo "      [WARN] failed: $dir"
done

echo "==> [6/6] All done."
echo ""
docker ps --format '  {{.Names}}  →  {{.Status}}'
echo ""
echo "Note: Containers run via 'docker run' (not compose) need manual restart."
echo "Ref:  cat ${INNER}/containers.txt"
RUNTIME

  chmod +x "$RESTORE_SCRIPT"
  ok "Generated: $RESTORE_SCRIPT"
}

# ================================================================
# CRON
# ================================================================
setup_cron() {
  [[ -z "$CRON_EXPR" ]] && return
  section "Setting up cron"

  # Remove old backloom entry if exists, add new one
  (crontab -l 2>/dev/null | grep -v "backloom-backup" || true; \
    echo "${CRON_EXPR} ${BACKUP_SCRIPT} >> ${BACKUP_DIR}/backloom.log 2>&1") | crontab -

  ok "Cron installed: ${CRON_EXPR}"
}

# ================================================================
# FINISH
# ================================================================
finish() {
  echo ""
  rule
  echo -e "  ${G}${W}✓ Backloom is ready!${N}"
  rule
  echo ""
  echo -e "  ${W}Backup script:${N}   ${BACKUP_SCRIPT}"
  echo -e "  ${W}Restore script:${N}  ${RESTORE_SCRIPT}"
  echo -e "  ${W}Backup folder:${N}   ${BACKUP_DIR}/"
  [[ -n "$RCLONE_REMOTE" ]] && \
    echo -e "  ${W}Cloud storage:${N}   ${RCLONE_REMOTE}:${RCLONE_FOLDER}/"
  echo ""
  echo -e "  ${W}To run a backup manually:${N}"
  echo -e "    ${C}bash ${BACKUP_SCRIPT}${N}"
  echo ""
  echo -e "  ${W}To restore on a new machine:${N}"
  echo -e "    ${C}bash backloom-restore.sh <backup-file>.tar.gz${N}"
  echo ""

  ask "Run first backup now? [Y/n]"
  read -r r
  [[ "$r" =~ ^[Nn] ]] || bash "$BACKUP_SCRIPT"
}

# ================================================================
# MAIN
# ================================================================
main() {
  banner
  check_prereqs
  detect_agent_folders
  detect_databases
  detect_compose_files
  show_summary
  setup_rclone
  setup_schedule
  generate_scripts
  setup_cron
  finish
}

main "$@"
