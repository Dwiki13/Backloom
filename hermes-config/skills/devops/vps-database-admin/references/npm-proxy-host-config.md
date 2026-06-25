# NPM Proxy Host Configuration on VPS

## Problem
Setting up `api.subtrack.devlokal.id` to proxy to a Docker container behind Nginx Proxy Manager (NPM).

## Critical: Correct Directory Name

NPM proxy host config files go in `/data/nginx/proxy_host/` (**underscore**), NOT `/data/nginx/proxy-hosts/` (hyphen).

```bash
# CORRECT
/data/nginx/proxy_host/3.conf          # loaded by nginx
/data/nginx/proxy_host/my-domain.conf  # loaded by nginx

# WRONG — nginx does NOT include this directory
/data/nginx/proxy-hosts/my-domain.conf  # silently ignored
```

Nginx include directive in `/etc/nginx/nginx.conf`:
```
include /data/nginx/proxy_host/*.conf;
```

Always verify after placing a file:
```bash
docker exec npm_npm_1 nginx -T | grep "server_name your-domain"
```

## Config File Pattern

Copy an existing working config (e.g., `3.conf`) and modify only:
- `server_name your-domain.com;`
- Three `ssl_certificate*` lines (or keep self-signed/npm-8 for testing)

**CRITICAL**: When editing, ensure:
- `ssl_certificate` appears exactly ONCE
- `ssl_certificate_key` is present (required, nginx will refuse to start without it)

### Broken Pattern (DO NOT):
```nginx
ssl_certificate /path/to/fullchain.pem;
ssl_certificate /path/to/fullchain.pem;   # DUPLICATE
# ssl_certificate_key is MISSING
```

### Correct Pattern:
```nginx
ssl_certificate     /path/to/fullchain.pem;
ssl_certificate_key /path/to/privkey.pem;
```

## ⚠️ Critical: Container Port vs Host Port in NPM Forward Config

When NPM forwards to a Docker container, it must use the **container-internal port**, NOT the host-mapped port.

Example: `docker run -p 8002:8000` means:
- Host port 8002 → Container port 8000
- From NPM (another container on the same Docker network), use **port 8000**
- Using port 8002 in NPM config causes `connect() failed (111: Connection refused)`

```bash
# Check port mapping:
docker inspect subtrack-api --format '{{json .NetworkSettings.Ports}}' | python3 -m json.tool
# Output: {"8000/tcp": [{"HostIp": "0.0.0.0", "HostPort": "8002"}]}
#         ^^^^^^^
#         Use THIS port in NPM (container-internal), NOT 8002

# Test from NPM container to verify:
docker exec npm_npm_1 curl -s -o /dev/null -w "%{http_code}" http://subtrack-api:8000/
# 404 = success (container reachable)
docker exec npm_npm_1 curl -s -o /dev/null -w "%{http_code}" http://subtrack-api:8002/
# 000 = connection refused (wrong port from container network)
```

## Debugging Flow

```bash
# 0. Is NPM even running? (If ALL sites are down simultaneously, NPM is the suspect)
docker ps | grep npm
# If npm container is missing or restarted recently, restart it first:
# docker run -d --name npm_npm_1 -p 80:80 -p 443:443 -p 81:81 \
#   -v /root/.hermes/volumes/npm/data:/data \
#   -v /root/.hermes/volumes/npm/letsencrypt:/etc/letsencrypt \
#   --restart unless-stopped jc21/nginx-proxy-manager:latest

# 1. Config syntax OK?
docker exec npm_npm_1 nginx -t

# 2. Server block loaded?
docker exec npm_npm_1 nginx -T | grep "server_name your-domain"

# 3. DNS resolving?
dig +short your-domain @8.8.8.8

# 4. Backend reachable from NPM?
docker exec npm_npm_1 curl -s http://container-name:port/health

# 5. Full path test
curl -s http://your-domain/health
curl -s -k https://your-domain/health
```
