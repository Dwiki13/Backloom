# NPM network_mode: host Fix — Docker Proxy Port Conflict

## Problem

When NPM is started with port mapping (`-p 80:80 -p 443:443 -p 81:81`), Docker creates `docker-proxy` processes that bind to those ports on the host. When nginx inside the NPM container tries to bind to the same ports, it fails with:

```
nginx: [emerg] bind() to 0.0.0.0:80 failed (98: Address already in use)
```

This happens repeatedly during startup — nginx can't bind, s6-supervise restarts it, creating an infinite crash loop.

## Root Cause

Docker's port mapping uses `docker-proxy` (a userspace proxy process) that binds the host port BEFORE the container process starts. The container's nginx then can't bind to the same port because `docker-proxy` already owns it.

**Key insight:** `docker-proxy` is different from regular nginx bind. Even `ss -tlnp` shows `docker-proxy` as the owner, NOT nginx. Killing nginx doesn't free the port — docker-proxy still holds it.

## Solution: network_mode: host

Remove port mapping from docker-compose and use `network_mode: host`:

```yaml
version: '3'

services:
  npm:
    image: 'jc21/nginx-proxy-manager:latest'
    restart: unless-stopped
    network_mode: host
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt
```

**Why this works:** With `network_mode: host`, the container shares the host's network stack directly. No docker-proxy is created. Nginx binds directly to host ports.

### Side Effects

- Ports 80, 443, 81 are now directly bound by the container's nginx
- Other services cannot bind to those ports on the same host
- `docker port npm_npm_1` no longer shows port mappings (expected)

## s6-Supervise Restart Loop

### Problem

NPM uses s6-svscan (PID 1) → s6-supervise (per-service supervisor) → nginx. When nginx can't bind due to port conflict:
1. s6-supervise detects nginx exited
2. s6-supervise restarts nginx
3. nginx can't bind again → crash → restart
4. Infinite loop, ~2 minutes per cycle

### Killing the Loop

**Standard `kill` doesn't work** — s6-supervise immediately restarts nginx.

**Fix sequence:**
```bash
# 1. STOP the supervisor first (prevents restart)
kill -STOP $(pgrep -f "s6-supervise nginx") 2>/dev/null

# 2. Kill nginx and all workers
pkill -9 nginx
sleep 2

# 3. Verify ports are free
ss -tlnp | grep -E ":80|:443|:81" || echo "PORTS FREE"

# 4. If npm-proxy still holding ports (from old port mapping setup):
killall docker-proxy 2>/dev/null
# Note: docker-proxy PID persists even after container restart if using port mapping

# 5. Start clean container with network_mode: host
cd /root/npm
docker-compose down
docker-compose up -d   # uses network_mode: host, no docker-proxy

# 6. Ensure NO other nginx on host
ps aux | grep nginx | grep -v grep
# If host-level nginx exists (e.g., from another project), kill it first
```

## Direct SQLite DB Manipulation for Proxy Hosts

When NPM UI is inaccessible (nginx down, no port 81), you can directly modify the SQLite database:

```bash
# Get proxy host details
docker exec npm_npm_1 python3 -c "
import sqlite3, json
conn = sqlite3.connect('/data/database.sqlite')
c = conn.cursor()
c.execute('SELECT id, domain_names, forward_host, forward_port, ssl_forced FROM proxy_host')
for row in c.fetchall():
    print(f'ID:{row[0]} Domains:{row[1]} Host:{row[2]} Port:{row[3]} SSL:{row[4]}')
conn.close()
"

# Update forward_host to IP (use IP when hostname doesn't resolve across networks)
docker exec npm_npm_1 python3 -c "
import sqlite3
conn = sqlite3.connect('/data/database.sqlite')
c = conn.cursor()
c.execute('UPDATE proxy_host SET forward_host=?, forward_port=?, ssl_forced=1 WHERE domain_names LIKE ?',
          ('172.18.0.5', 8000, '%api.subtrack%'))
conn.commit()
conn.close()
print('Updated')
"
```

**⚠️ Important:** Updating DB does NOT auto-regenerate nginx config. You must either:
1. Use NPM web UI (triggers regen), or
2. Edit/create the nginx `.conf` file directly, or
3. Delete old config files and restart NPM (regenerates from DB)

## Manual Nginx Config for Proxy Host (Direct File)

When DB update + restart doesn't regenerate, write the config directly in the container:

```bash
# Write to /etc/nginx/conf.d/ inside container (for network_mode: host)
docker exec npm_npm_1 tee /etc/nginx/conf.d/api.subtrack.conf > /dev/null << 'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name api.subtrack.devlokal.id;
    include /etc/nginx/conf.d/include/letsencrypt-acme-challenge.conf;
    location / { return 301 https://$host$request_uri; }
}
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name api.subtrack.devlokal.id;
    ssl_certificate /root/.hermes/volumes/npm/letsencrypt/live/npm-*/fullchain.pem;
    ssl_certificate_key /root/.hermes/volumes/npm/letsencrypt/live/npm-*/privkey.pem;
    include /etc/nginx/conf.d/include/ssl-ciphers.conf;
    include /etc/nginx/conf.d/include/proxy.conf;
    location / {
        proxy_pass http://172.18.0.5:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF
```

**Note:** Adjust the cert path `npm-*` to match the actual certificate ID (check `ls /root/.hermes/volumes/npm/letsencrypt/live/`).

### Config Path Difference

- **Port mapping mode:** NPM generates configs to `/data/nginx/proxy_host/` (on volume)
- **network_mode: host mode:** NPM may generate to `/etc/nginx/conf.d/` (inside container, ephemeral)

After writing config:
```bash
docker exec npm_npm_1 nginx -t   # validate syntax
docker exec npm_npm_1 nginx -s reload  # or kill + start nginx
```

## Cloudflare SSL/TLS Mode for NPM

For self-hosted backends behind NPM:

| Cloudflare Mode | NPM Compatible? | Why |
|----------------|-----------------|-----|
| DNS only (gray cloud) | ✅ Yes | Traffic goes directly to VPS, Let's Encrypt HTTP challenge works |
| Proxied (orange cloud) | ⚠️ Issues | Cloudflare proxies traffic, may break Let's Encrypt HTTP challenge, SSL handshake may fail |
| Full (strict) | ✅ Yes (with SSL on VPS) | End-to-end HTTPS, requires valid cert on origin |
| Flexible | ❌ No | Cloudflare→origin is HTTP, but browser→Cloudflare is SSL — causes mixed content |

**Recommendation for API subdomains:** Use **DNS only** (gray cloud) for Let's Encrypt HTTP challenge, or **Full** after SSL cert is issued.

## Verification Checklist

```bash
# 1. Container running with network_mode: host
docker inspect npm_npm_1 --format '{{.HostConfig.NetworkMode}}'
# Expected: "host"

# 2. No docker-proxy blocking ports
ss -tlnp | grep docker-proxy | grep -E ":80|:443|:81"
# Expected: empty (no docker-proxy for NPM)

# 3. Nginx bound to ports
ss -tlnp | grep nginx | grep -E ":80 |:443 |:81 "
# Expected: nginx master process listed

# 4. HTTP test
curl -s -o /dev/null -w "%{http_code}" http://api.subtrack.devlokal.id
# Expected: 301 (redirect to HTTPS) or 200

# 5. HTTPS test
curl -s -o /dev/null -w "%{http_code}" -k https://api.subtrack.devlokal.id
# Expected: 200 or 401/403 (API responds)

# 6. SSL cert valid
openssl s_client -connect api.subtrack.devlokal.id:443 -servername api.subtrack.devlokal.id </dev/null 2>/dev/null | openssl x509 -noout -dates -subject
```
