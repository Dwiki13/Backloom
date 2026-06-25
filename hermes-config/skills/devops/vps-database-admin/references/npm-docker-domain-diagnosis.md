# NPM + Docker Domain Diagnosis Sequence

When a domain pointing to a VPS with Nginx Proxy Manager + Docker containers isn't working, follow this exact diagnostic order:

## 1. DNS Resolution Check
```bash
# From client machine (PowerShell):
nslookup your-domain.com
# or
dig your-domain.com
```
- **NXDOMAIN** → DNS record missing. Add A record at your DNS provider.
- **Resolves to wrong IP** → Check if Cloudflare proxy (orange) is enabled — that gives Cloudflare IPs, not your VPS IP. Use DNS-only (gray) for self-hosted backends.

### ⚠️ Indonesian ISP DNS Intercept
If `nslookup` returns NXDOMAIN on **all** DNS servers (Google 8.8.8.8, Cloudflare 1.1.1.1, OpenDNS) simultaneously — the record may still exist. Some Indonesian ISPs (IndiHome, etc.) hijack DNS and return NXDOMAIN for any domain they don't recognize, regardless of the authoritative NS.
- **Confirm**: Use a VPN or check from a different country. If the domain resolves there, it's ISP intercept.
- **Quick fix**: hosts file override (see section "Quick Local Test" below) — this bypasses ISP DNS entirely.

## 2. NPM Config Check
```bash
# From VPS — list proxy host configs:
docker exec npm_npm_1 find /data/nginx/proxy_host -name "*.conf" -exec echo "=== {} ===" \; -exec cat {} \;
n```
Verify:
- `server_name` matches the domain exactly
- `$server` is a **container name** (not `localhost`) from a Docker network shared with NPM
- `$port` matches the container's internal port (not the host-mapped port)
- SSL cert path exists and is valid

## 3. Docker Network Topology
```bash
# Check which networks each container is on:
docker inspect <container> --format '{{json .NetworkSettings.Networks}}' | python3 -m json.tool
```
- NPM and the API container **must share a Docker network** for container name resolution to work.
- If they're on different networks, either connect the container to NPM's network or use the IP from the shared network.
- `localhost` from a container = that container itself, NOT the host VPS.

## 4. Container Health
```bash
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
docker logs <container> --tail 30
```
- Verify container is `Up` and the expected port is mapped.
- Check logs for errors (connection refused, upstream not found, etc.).

## 5. NPM Error Logs
```bash
docker exec npm_npm_1 tail -20 /data/logs/proxy-host-<ID>_error.log
```
Common errors:
- `localhost could not be resolved` → NPM config has `localhost` instead of container name
- `connect() failed (111: Connection refused)` → Container name resolves but port is wrong or container is down
- `502 Bad Gateway` → NPM can't reach the upstream (wrong container name, wrong port, or container down)

## 6. SSL Certificate
```bash
docker exec npm_npm_1 openssl x509 -in /etc/letsencrypt/live/npm-<ID>/fullchain.pem -noout -dates -subject
```
- Check cert is not expired
- Check `Subject` matches the domain name exactly

## 7. End-to-End Test
```bash
# From client machine:
curl.exe -I https://your-domain.com    # PowerShell
curl -I https://your-domain.com       # Linux/Mac
```
- **403/401** → API is working (auth required)
- **502** → NPM can't reach upstream
- **000/timeout** → DNS or firewall issue

## Quick Local Test (hosts File Override)
When DNS hasn't propagated yet but you need to test from a specific machine:
- **Windows**: Add `<VPS_IP> your.domain.id` to `C:\\Windows\\System32\\drivers\\etc\\hosts` (open Notepad as Admin)
- **Linux/Mac**: Add `<VPS_IP> your.domain.id` to `/etc/hosts` (`sudo nano /etc/hosts`)
- This bypasses DNS entirely — useful for development while waiting for Cloudflare propagation
- Only works on the machine where it's added; does NOT affect other devices (phones, other PCs)
- Remove the line when DNS is live to avoid stale entries

## Direct Config Edit (Without NPM UI)

When the NPM web UI is inaccessible or you need a fast fix, edit the proxy host config directly via sed:

```bash
# List proxy host configs to find the file number:
docker exec npm_npm_1 find /data/nginx/proxy_host -name "*.conf" -exec echo {} \;

# Edit the config (e.g., change port from 8002 to 8000):
docker exec npm_npm_1 sed -i 's/set $port           8002;/set $port           8000;/' /data/nginx/proxy_host/3.conf

# Validate and reload:
docker exec npm_npm_1 nginx -t
docker exec npm_npm_1 nginx -s reload
```

Config files are in `/data/nginx/proxy_host/` (**underscore**, not hyphen). The `server_name`, `$server` (container name), and `$port` (container-internal port) are the three values most commonly wrong.

## PowerShell curl Gotcha

PowerShell aliases `curl` to `Invoke-WebRequest` — different syntax, different flags. When instructing Windows users to test from PowerShell:
- Use `curl.exe` (not `curl`) for Linux-compatible syntax: `curl.exe -I https://domain.com`
- Or use `Invoke-WebRequest -Uri "https://domain.com" -UseBasicParsing | Select-Object StatusCode`
- `nslookup` works the same in both PowerShell and cmd
- After DNS changes, run `ipconfig /flushdns` to clear the local DNS cache
- To query a specific DNS server: `nslookup domain.com 1.1.1.1` (Cloudflare) or `nslookup domain.com 8.8.8.8` (Google)

## ⚠️ NPM Container Crash — The "All Sites Down" Pattern

When the NPM container crashes or is removed, **ALL sites behind it become inaccessible simultaneously** — even though the individual API containers are healthy.

**Symptoms:**
- Multiple domains (e.g., `devlokal.id`, `api.subtrack.devlokal.id`, `secondbrain.devlokal.id`) all return timeout or "Unable to access"
- API services internally are healthy (`docker logs api-name` shows 200 OK responses)
- `https://domain` fails but `http://<VPS_IP>:<host_port>` works directly
- `docker ps | grep npm` shows NPM container missing or recently restarted

**Root Cause:** NPM is the single entry point for HTTPS. Backend containers can run fine but are unreachable without NPM's proxy layer.

**Recovery — Restart NPM:**
```bash
# 1. Verify NPM is actually down:
docker ps -a --format "table {{.Names}}\t{{.Status}}" | grep npm
# If missing or "Exited", restart it:

# 2. Start NPM with existing volumes (preserves configs + DB):
docker run -d \
  --name npm_npm_1 \
  -p 80:80 \
  -p 443:443 \
  -p 81:81 \
  -v /root/.hermes/volumes/npm/data:/data \
  -v /root/.hermes/volumes/npm/letsencrypt:/etc/letsencrypt \
  --restart unless-stopped \
  jc21/nginx-proxy-manager:latest

# 3. Verify NPM is running:
docker ps | grep npm_npm_1

# 4. Check if proxy configs + SSL were preserved (volume mount):
docker exec npm_npm_1 find /data/nginx/proxy_host -name "*.conf"
docker exec npm_npm_1 openssl x509 -in /etc/letsencrypt/live/npm-*/fullchain.pem -noout -subject 2>/dev/null

# 5. If Let's Encrypt volume is empty (fresh start), re-issue SSL via npm UI at http://<VPS-IP>:81
```

**⚠️ NPM Volume Backup:**
The NPM data volume at `/root/.hermes/volumes/npm/data/` contains:
- `database.sqlite` — proxy host configurations, users, SSL keys
- `letsencrypt/` — SSL certificates (may not persist in `/etc/letsencrypt` path)

**⚠️ Volume Mount — Lost When Container Dies:**
If `docker run` was used without `-v` volumes (e.g., plain `docker-compose down -v`), ALL proxy host configs and SSL certs are lost. You must reconfigure from scratch via `http://<VPS-IP>:81`.

**Prevention:**
- Use `--restart unless-stopped` on NPM container
- Never use `docker-compose down -v` on a stack containing NPM
- Consider backing up `/root/.hermes/volumes/npm/` periodically

## ⚠️ Different Docker Networks = 502 Even When Everything Else Looks Correct

**The most missed cause of 502 in NPM+Docker setups:** The proxy host database has `forward_host = "devlokal"`, SSL is issued, DNS resolves, the backend container is healthy — but NPM still returns 502.

**Root cause:** The backend container and NPM are on **different Docker bridge networks**. NPM can't resolve the container hostname because Docker DNS only works within the same network.

**Diagnostic signature:**
```
docker logs npm ... "devlokal could not be resolved (3: Host not found)"
docker exec npm_npm_1 node -e "require('http').get('http://devlokal:80', ...)" → ENOTFOUND
docker exec devlokal wget http://localhost:80 → OK  (container itself is fine)
```

**How to confirm — check networks:**
```bash
docker inspect devlokal --format '{{range .NetworkSettings.Networks}}{{.NetworkID}}{{end}}'
docker inspect npm_npm_1 --format '{{range .NetworkSettings.Networks}}{{.NetworkID}}{{end}}'
```
If the NetworkIDs differ → containers can't resolve each other by name.

**Fix — two options:**

**Option A (preferred — same network):** Connect the backend container to NPM's network:
```bash
docker network connect npm_default devlokal
```
Then restart NPM: `docker restart npm_npm_1`
Note: If the backend is on `bridge` (default), it won't have NPM's network. Use `docker run --net=` or `docker-compose` with a shared network.

**Option B (fallback — direct IP):** Get the backend container's IP from a shared network, then sed the nginx config:
```bash
# Get IP from the backend container's bridge network:
docker inspect devlokal --format '{{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}' | awk '{print $1}'

# Edit nginx config directly (NPM regenerates from DB but caches in memory):
docker exec npm_npm_1 sed -i 's/set $server         "devlokal"/set $server         "172.17.0.3"/' /data/nginx/proxy_host/2.conf
docker exec npm_npm_1 nginx -s reload
```

**⚠️ NPM config regeneration issue:** When you UPDATE the `proxy_host` table in NPM's SQLite DB (e.g., change `forward_host`), the nginx config file in `/data/nginx/proxy_host/` does NOT automatically regenerate. You must either:
1. Edit via NPM web UI (triggers regen), or
2. Edit the nginx `.conf` file directly via sed + `nginx -s reload`

**Pro tip — verify the fix applied:**
```bash
docker exec npm_npm_1 cat /data/nginx/proxy_host/2.conf | grep "set \$server"
```

## ⚠️ NPM Restart Loop from Let's Encrypt Failures

When Let's Encrypt fails repeatedly (e.g., rate limit, DNS not pointing to VPS, domain typo), NPM enters a **restart loop**:
1. NPM starts → detects SSL cert needed → tries to issue → fails
2. NPM process crashes (SIGTERM) → Docker restarts → repeat
3. Each attempt logs "PID received SIGTERM" every ~2 minutes
4. Let's Encrypt rate limit: 5 failed authorizations per domain per hour

**Diagnostic signature:**
```bash
docker logs npm_npm_1 --tail 20
# Shows: "PID NNN received SIGTERM" repeating every ~2 min
# Plus in letsencrypt.log:
#   "too many failed authorizations (5) for \"domain\" in the last 1h0m0s"
```

**Root cause:** NPM tries to auto-renew/issue SSL on startup. If it fails (DNS, rate limit, typo in domain), the process exits. Docker restarts (due to `--restart unless-stopped`), creating an infinite loop.

**Fix sequence:**
```bash
# 1. Stop the restarting container
docker stop npm_npm_1

# 2. Fix DNS / Cloudflare first — MUST point to VPS IP
#    Cloudflare: DNS only (grey cloud) for backend APIs
#    DNS record: A record → <VPS_IP>

# 3. Remove failed proxy hosts and certs from DB
docker start npm_npm_1 && sleep 5
docker exec npm_npm_1 node -e "
const Database = require('better-sqlite3');
const db = new Database('/data/database.sqlite');
db.prepare('DELETE FROM proxy_host WHERE domain_names LIKE ?').run('%problem-domain%');
db.prepare('DELETE FROM certificate WHERE domain_names LIKE ?').run('%problem-domain%');
db.close();
"

# 4. Remove stale nginx configs
docker exec npm_npm_1 rm -f /data/nginx/proxy_host/*.conf

# 5. Restart cleanly
docker restart npm_npm_1

# 6. Re-add proxy host via NPM UI (http://<VPS-IP>:81)
# 7. Issue SSL only AFTER DNS resolves correctly
```

**Rate limit cooldown:** Let's Encrypt tracks per-domain failures. Wait 1-2 hours after 5 failures before retrying. There is no way to reset it early.

**⚠️ Critical: Do NOT add SSL cert to proxy host in NPM UI if DNS doesn't resolve.** Delete the proxy host entry, fix DNS first, then re-add.

## ⚠️ NPM Without Volumes = Total Data Loss on Every Restart

When NPM is started via `docker run` **without `-v` volume mounts**, ALL data lives in the container's writable layer. On ANY restart or recreate:
- Database re-initializes from scratch (`Current database version: none`)
- All proxy hosts disappear
- All SSL certs disappear
- Admin user must be recreated
- `http://<VPS-IP>:81` shows the setup screen

**Symptoms after unexpected restart:**- `http://<VPS-IP>:81` shows "Create Admin" setup screen- All domains behind NPM return 502 or timeout
- `docker exec npm_npm_1 find /data/nginx/proxy_host -name "*.conf"` → empty- `docker logs npm_npm_1` shows migration creating tables from scratch

**Prevention — always use volume mounts:**
```bash
docker volume create npm_data 2>/dev/null
docker volume create *** 2>/dev/null

docker run -d --name npm_npm_1 \
  -p 80:80 -p 443:443 -p 81:81 \
  -v npm_data:/data \
  -v /root/.hermes/volumes/npm/letsencrypt:/etc/letsencrypt \
  --restart unless-stopped \
  jc21/nginx-proxy-manager:latest
```

**Recovery when data is lost:**1. Stop and remove old container: `docker rm -f npm_npm_1`
2. Create with proper volumes (above)
3. Access `http://<VPS-IP>:81` — create admin4. Re-add all proxy hosts
5. Re-issue SSL for each

**⚠️ ALSO CONNECT TO SHARED NETWORK:**NPM and backend containers must share a Docker network for hostname resolution```bash
docker network connect npm_default devlokaldocker network connect npm_default subtrack-api```Or use a shared network in docker-compose.yml with `networks:` section.## ⚠️ Nginx Fails to Start After Partial Config Edit

When editing `/data/nginx/proxy_host/N.conf` directly via sed, partial edits can corrupt the config and prevent nginx from starting entirely:```bash
docker exec npm_npm_1 ps aux | grep nginx
# Returns nothing — nginx process missing# But container keeps running
```

**Common corruption patterns:**
- Incomplete sed replacement leaving broken lines like `npm-9/npm-9/fullchain.pem;`
- Missing `listen 443 ssl;` after commenting it out
- Duplicate `ssl_certificate` directives

**Diagnostic:**```bash
docker exec npm_npm_1 nginx -t
# Shows syntax error with line number# Check the error log:
docker exec npm_npm_1 cat /var/log/nginx/error.log | tail -10
```

**Fix — clean slate regeneration:**
```bash
# Remove corrupted config — NPM will regenerate from DB on next restart
docker exec npm_npm_1 rm -f /data/nginx/proxy_host/*.conf# Ensure DB has correct settings
docker exec npm_npm_1 node -e "
const Database = require('better-sqlite3');
const db = new Database('/data/database.sqlite');
db.prepare('DELETE FROM certificate WHERE domain_names LIKE ?').run('%domain%');
db.close();
"
# Restart
docker restart npm_npm_1
```

**⚠️ NPM regenerates config from DB on startup** — if config file exists but doesn't match DB, either delete the file (NPM regen) or ensure DB matches what you want.

## Key Pitfalls
- **Cloudflare Proxied vs DNS-only**: For self-hosted backends, use DNS-only (gray cloud). Proxied adds Cloudflare IPs and can cause 502 if NPM doesn't recognize the domain.
- **Container name vs localhost**: NPM is a Docker container. `localhost` inside NPM = NPM itself. Always use the API container name.
- **Different Docker networks**: If NPM and your backend are on different networks, hostname resolution fails. Use `docker network connect` or fall back to IP.
- **NPM DB update doesn't regenerate nginx config**: Updating `proxy_host.forward_host` in SQLite only changes the DB. The actual nginx config at `/data/nginx/proxy_host/N.conf` doesn't auto-regenerate. Edit via NPM UI or sed the conf file directly.
- **Port mapping**: Docker maps `host_port:container_port`. NPM needs the **container port** (the one the app listens on inside the container), not the host-mapped port. E.g., if `docker run -p 8002:8000`, use port `8000` in NPM's forward config.
- **Domain mismatch**: The domain in Cloudflare DNS must exactly match the `server_name` in NPM's proxy host config.
- **NPM crash takes down ALL sites**: One container failure = every domain behind it goes down. Always check `docker ps | grep npm` before debugging individual services.
- **Nginx won't start after config corruption**: If `ps aux | grep nginx` shows no process but container is running, a corrupted `.conf` file is preventing nginx from starting. Delete configs to let NPM regenerate.
- **SSL before DNS ready = rate limit trap**: Adding SSL cert in NPM UI before DNS resolves to VPS IP = guaranteed failure. Each failure counts against Let's Encrypt's rate limit (5/hour). Always verify DNS first: `dig +short your-domain.com` should return `<VPS_IP>`.

## Quick Local Test (hosts File Override)
When DNS hasn't propagated yet but you need to test from a specific machine:
- **Windows**: Add `<VPS_IP> your.domain.id` to `C:\\Windows\\System32\\drivers\\etc\\hosts` (open Notepad as Admin)
- **Linux/Mac**: Add `<VPS_IP> your.domain.id` to `/etc/hosts` (`sudo nano /etc/hosts`)
- This bypasses DNS entirely — useful for development while waiting for Cloudflare propagation
- Only works on the machine where it's added; does NOT affect other devices (phones, other PCs)
- Remove the line when DNS is live to avoid stale entries

## Direct Config Edit (Without NPM UI)

When the NPM web UI is inaccessible or you need a fast fix, edit the proxy host config directly via sed:

```bash
# List proxy host configs to find the file number:
docker exec npm_npm_1 find /data/nginx/proxy_host -name "*.conf" -exec echo {} \;

# Edit the config (e.g., change port from 8002 to 8000):
docker exec npm_npm_1 sed -i 's/set $port           8002;/set $port           8000;/' /data/nginx/proxy_host/3.conf

# Validate and reload:
docker exec npm_npm_1 nginx -t
docker exec npm_npm_1 nginx -s reload
```

Config files are in `/data/nginx/proxy_host/` (**underscore**, not hyphen). The `server_name`, `$server` (container name), and `$port` (container-internal port) are the three values most commonly wrong.

## PowerShell curl Gotcha

PowerShell aliases `curl` to `Invoke-WebRequest` — different syntax, different flags. When instructing Windows users to test from PowerShell:
- Use `curl.exe` (not `curl`) for Linux-compatible syntax: `curl.exe -I https://domain.com`
- Or use `Invoke-WebRequest -Uri "https://domain.com" -UseBasicParsing | Select-Object StatusCode`
- `nslookup` works the same in both PowerShell and cmd
- After DNS changes, run `ipconfig /flushdns` to clear the local DNS cache
- To query a specific DNS server: `nslookup domain.com 1.1.1.1` (Cloudflare) or `nslookup domain.com 8.8.8.8` (Google)
