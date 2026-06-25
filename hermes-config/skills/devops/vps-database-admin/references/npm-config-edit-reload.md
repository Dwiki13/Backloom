# NPM Config Edit & Reload Pattern

## Editing NPM Proxy Host Config Directly

When the NPM UI is unavailable or you need to fix a config quickly:

```bash
# 1. Find the config file for your domain
docker exec npm_npm_1 grep -l "your-domain.com" /data/nginx/proxy_host/*.conf

# 2. Edit the port (e.g., change 8002 to 8000)
docker exec npm_npm_1 sed -i 's/set $port           8002;/set $port           8000;/' /data/nginx/proxy_host/3.conf

# 3. Edit the upstream server name if needed
docker exec npm_npm_1 sed -i 's/set $server         "localhost";/set $server         "subtrack-api";/' /data/nginx/proxy_host/3.conf

# 4. Validate config
docker exec npm_npm_1 nginx -t

# 5. Reload nginx (no downtime)
docker exec npm_npm_1 nginx -s reload

# 6. Verify the change took effect
docker exec npm_npm_1 nginx -T | grep -A5 "server_name your-domain"
```

## After Reload: Verify End-to-End

```bash
# From NPM container to API container
docker exec npm_npm_1 curl -s -o /dev/null -w "%{http_code}" http://subtrack-api:8000/api/v1/subscriptions
# Expected: 403 or 401 (means API is reachable and responding)

# From host VPS via HTTPS
curl -s -o /dev/null -w "%{http_code}" -k https://api.subtrack.devlokal.id/api/v1/subscriptions
# Expected: 403 or 401

# From client PC (PowerShell)
curl.exe -I https://api.subtrack.devlokal.id
# Expected: 403 or 401
```

## Common Config Values

| Field | Wrong Value | Correct Value | Why |
|-------|-------------|---------------|-----|
| set $port | 8002 (host-mapped) | 8000 (container-internal) | NPM is a container; it connects via Docker network, not host |
| set $server | localhost or 127.0.0.1 | subtrack-api (container name) | localhost inside NPM container = NPM itself, not the host |
