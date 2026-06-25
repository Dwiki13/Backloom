# Nginx Proxy Manager (NPM) — Operations & Troubleshooting

## Adding a Proxy Host via UI

1. Open NPM (usually `http://<vps-ip>:81`)
2. Login → Proxy Hosts → Add Proxy Host
3. Fill in:
   - **Domain Names**: e.g. `api.subtrack.devlokal.id`
   - **Scheme**: `http`
   - **Forward Hostname/IP**: Docker container name (e.g. `subtrack-api`) — NOT localhost
   - **Forward Port**: Internal container port (e.g. `8000`) — NOT host-mapped port
   - Block Common Exploits: enabled
   - Websockets Support: enabled
4. **SSL tab** → Request Let's Encrypt cert
   - Email: your email
   - Agree to ToS → Save

## Docker Networking for NPM

When NPM and target containers are on the same Docker network:

- Use **container name** as forward hostname (Docker DNS resolves it)
- Use **internal container port** (the EXPOSEd port), NOT the host-mapped port
- Example: `subtrack-api:8000` works; `localhost:8002` does NOT work from inside NPM container

If containers are on different networks, add both to a shared network or use container IP.

## Verifying Connectivity from NPM Container

```bash
docker exec npm_npm_1 curl -s -o /dev/null -w "%{http_code}" http://subtrack-api:8000/health
docker exec npm_npm_1 curl -s http://subtrack-api:8000/health
```

If 200, NPM can reach the service. If timeout, check Docker networking.

## SSL Certificate Troubleshooting

### Check certificate status in DB

```bash
docker exec npm_npm_1 node -e "
const Database = require('better-sqlite3')('/data/database.sqlite');
const rows = Database.prepare('SELECT id, domain_names, certificate_id, ssl_forced FROM proxy_host WHERE is_deleted=0').all();
console.log(JSON.stringify(rows, null, 2));
"
```

- `certificate_id: 0` = SSL cert NOT yet requested
- `certificate_id: N` (N>0) = cert exists with that ID

### SSL cert request fails with "Internal Error"

**Root cause is almost always DNS.** Let's Encrypt must resolve the domain.

```bash
dig +short api.subtrack.devlokal.id
```

If empty: add A record pointing domain to VPS IP. Wait 1-5 min for propagation.

### Check existing SSL certs

```bash
docker exec npm_npm_1 ls /etc/letsencrypt/live/
```

## NPM DB Schema — proxy_host table

Key columns: `id`, `domain_names` (JSON array), `forward_host`, `forward_port`, `forward_scheme`, `certificate_id`, `ssl_forced`, `enabled`, `is_deleted`

**Important**: Column is `forward_host` (not `forward_ip`). Wrong column name causes `SqliteError: no such column`.

## Common NPM Pitfalls

- **"Internal Error" on save**: Usually DNS not resolving. Check `dig +short domain.com`.
- **Default credentials changed**: Default is `admin@example.com` / `changeme`. Reset via DB if forgotten.
- **Port confusion**: Forward port = container internal port, not host port.
- **Config not regenerating**: After DB changes: `docker restart npm_npm_1`
- **sqlite3 CLI not available in container**: Use Node.js: `docker exec npm_npm_1 node -e "const Database = require('better-sqlite3')('/data/database.sqlite'); ..."`
