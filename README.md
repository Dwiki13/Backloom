<div align="center">

```
╔══════════════════════════════════════════╗
║  ⚡ BACKLOOM  v1.0                        ║
║  AI Agent Backup & Restore               ║
╚══════════════════════════════════════════╝
```

**One command to back up your entire self-hosted AI agent.**  
Knowledge base · Skills · Vector DB · Databases · Configs · Services

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Shell](https://img.shields.io/badge/Shell-Bash-green.svg)](install.sh)
[![Platform](https://img.shields.io/badge/Platform-Ubuntu%2022.04%2B-blue.svg)](#requirements)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

</div>

---

## What is Backloom?

You spent weeks building your self-hosted AI agent — knowledge base, skills, playbooks, RAG index, vector DB, second brain, automations.

Then your VPS dies. Or you want to migrate. Or your subscription runs out.

**Backloom is a one-command installer** that auto-detects your entire agent setup, backs it all up (files + databases), uploads to Google Drive / Backblaze B2 / S3, and gives you a restore script that brings everything back on a fresh machine.

```bash
bash install.sh
```

That's it. Backloom handles the rest.

---

## Demo

```
  ╔══════════════════════════════════════════╗
  ║  ⚡ BACKLOOM  v1.0                        ║
  ║  AI Agent Backup & Restore Installer     ║
  ╚══════════════════════════════════════════╝

[✓] Running as root
[✓] Docker: 26.1.4
[✓] rclone: v1.67.0

Scanning agent folders
──────────────────────────────────────────────
[•] Found: ~/knowledge
[•] Found: ~/projects
[•] Found: ~/skills
[•] Found: ~/secondbrain
[•] Found: 12 todo-*.md + carryover scripts

Scanning database containers
──────────────────────────────────────────────
[•] Found DB: app-db (postgres, db=app)
[•] Found DB: vector-db (postgres, db=embeddings)

Scanning docker-compose files
──────────────────────────────────────────────
[•] Found: core-stack
[•] Found: projects/agent-api
[•] Found: projects/web-dashboard
[•] Found: npm

  Agent Folders:    knowledge, projects, skills, secondbrain ...
  Databases:        app-db (app), vector-db (embeddings)
  Services:         4 docker-compose services

[?] Proceed? [Y/n] Y

==> [1/5] Dumping databases...
    - app-db (postgres)
    - vector-db (postgres)
==> [2/5] Archiving agent files...
==> [3/5] Packaging...
==> [4/5] Uploading to cloud...
    Uploaded: gdrive:BackloomBackups/backloom-20260617_030001.tar.gz
==> [5/5] Cleanup local...

Done ✓  73M  →  ~/backloom-backups/backloom-20260617_030001.tar.gz
```

> Tested end-to-end on a real production self-hosted AI agent setup (12+ services, 2 databases, multiple projects).

---

## Features

- **Auto-detect** agent folders, databases, and docker-compose services — no manual config needed
- **Multi-database** support: PostgreSQL, pgvector, MySQL/MariaDB, MongoDB
- **Multi-cloud** upload: Google Drive, Backblaze B2, AWS S3 (via rclone)
- **Smart exclusions** — skips `node_modules`, `venv`, `__pycache__`, `dist`, build artifacts
- **Automatic retention** — keeps 7 local backups, 30 days in cloud (configurable)
- **One-command restore** — bring everything back on any fresh Ubuntu machine
- **Cron scheduling** — daily, weekly, or custom schedule
- **Extensible** — add new folders or DB containers by editing 2 lines in the generated script

---

## Requirements

| Requirement | Notes |
|-------------|-------|
| Ubuntu 22.04+ / Debian 12+ | Other distros may work, untested |
| Docker + Docker Compose v2 | `docker compose` (not `docker-compose`) |
| Root / sudo access | Needed for cron and system-wide rclone |
| curl | For rclone install if not present |
| rclone | Auto-installed if missing |

---

## Quick Start

**1. Clone or download:**
```bash
git clone https://github.com/YOUR_USERNAME/backloom.git
cd backloom
```

**2. Run installer:**
```bash
sudo bash install.sh
```

**3. Follow the wizard** — it will:
- Scan your VPS for agent folders, databases, and services
- Walk you through connecting cloud storage
- Set a backup schedule
- Generate `~/backloom-backup.sh` and `~/backloom-restore.sh`
- Optionally run your first backup immediately

---

## Restoring on a New Machine

**Step 1 — Install prerequisites on the new machine:**
```bash
# Install Docker
curl -fsSL https://get.docker.com | bash

# Install rclone
curl https://rclone.org/install.sh | sudo bash

# Configure rclone (connect to your cloud storage)
rclone config
```

**Step 2 — Download your latest backup:**
```bash
rclone copy gdrive:BackloomBackups/backloom-<TIMESTAMP>.tar.gz .
```

**Step 3 — Restore:**
```bash
bash backloom-restore.sh backloom-<TIMESTAMP>.tar.gz
```

The restore script will:
- Extract all agent files back to `~/`
- Start database containers
- Restore all database dumps
- Start all docker-compose services

---

## What Gets Backed Up

| Component | Method |
|-----------|--------|
| Agent folders (`~/knowledge`, `~/skills`, `~/projects`, etc.) | `tar` archive |
| PostgreSQL / pgvector databases | `pg_dumpall` |
| MySQL / MariaDB databases | `mysqldump --all-databases` |
| MongoDB | `mongodump --archive` |
| Reverse proxy config (e.g. Nginx Proxy Manager — proxy rules + SSL certs) | `tar` archive |
| Todo files & scripts (`todo-*.md`, `todo-carryover.sh`) | `tar` archive |
| Docker state snapshot (container list) | `docker ps -a` |

**Intentionally excluded** (safe to skip — easy to reinstall):
- Language package caches (Go modules, pip cache, etc. — often 1+ GB)
- `node_modules`, `venv`, `.venv`, `.next`, `dist`, `build`

---

## Adding New Projects / Databases

Any new folder inside `~/projects/` is **automatically included** — no config change needed.

To add a new top-level folder, edit `INCLUDE_DIRS` in `~/backloom-backup.sh`:
```bash
INCLUDE_DIRS=(
  "knowledge"
  "projects"
  "my-new-agent"   # <-- add here
)
```

To add a new database container, edit `DB_CONTAINERS`:
```bash
DB_CONTAINERS=(
  "app-db|postgres|appuser|apppassword|appdb"
  "my-new-db|postgres|admin|password123|mydb"   # <-- add here
)
```

Format: `"container_name|type|user|password|dbname"`  
Supported types: `postgres`, `mysql`, `mongo`

---

## Retention Policy (default)

| Location | Policy |
|----------|--------|
| Local (`~/backloom-backups/`) | 7 most recent files |
| Cloud | 30 days |

Change by editing `LOCAL_KEEP` and `CLOUD_KEEP_DAYS` in `~/backloom-backup.sh`.

---

## Roadmap

- [ ] Web dashboard to view backup history & status
- [ ] Slack / Telegram notification on backup success/failure
- [ ] n8n workflow detection & backup
- [ ] Encrypted backups (rclone crypt)
- [ ] Dry-run mode (`--dry-run` flag)
- [ ] Docker volume backup (for non-compose setups)
- [ ] `.backloom.yml` config file for version-controlled setup

---

## Contributing

Pull requests welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

Found a bug? [Open an issue](https://github.com/YOUR_USERNAME/backloom/issues).

---

## License

MIT — see [LICENSE](LICENSE).

---

<div align="center">

Built for AI agent builders who self-host. 🤖  
If Backloom saved your setup, drop a ⭐

</div>
