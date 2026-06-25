# VPS + Docker Debugging Checklist

When a VPS-deployed app returns 502/503 or can't connect, follow this order:

## 1. DNS Resolution

```bash
# From the VPS itself:
dig api.yourdomain.id +short
nslookup api.yourdomain.id

# From outside (local PC PowerShell):
nslookup api.yourdomain.id
curl.exe -I https://api.yourdomain.id
```

**NXDOMAIN** → DNS record not registered at registrar. Add A record pointing to VPS IP.

## 2. Port Listening on Host

```bash
ss -tlnp | grep -E '443|80|YOUR_PORT'
```

If not listening → container may not be running or port not exposed in docker-compose.

## 3. Backend from Host

```bash
# Must return SOMETHING (404/403/401 = alive)
curl -s -o /dev/null -w "%{http_code}" http://localhost:PORT/
```

**Connection refused** → container down or port mapping wrong.

## 4. Proxy Container Reachability (THE 502 CULPRIT)

```bash
# Check networks
docker inspect <proxy-container> --format '{{json .NetworkSettings.Networks}}'
docker inspect <backend-container> --format '{{json .NetworkSettings.Networks}}'

# Check IPs in shared networks
docker inspect <backend-container> --format '{{range .NetworkSettings.Networks}}{{.IPAddress}} {{.NetworkName}}{{end}}'
```

**502 despite backend alive** = proxy and backend on different Docker networks.

**Fix:** Add backend to proxy's network in docker-compose, or use the container's IP on the shared network as the proxy destination (NOT `localhost` — localhost inside a container is itself, not the host).

## 5. SSL/Cert Issues

```bash
# Check cert files exist in NPM UI
# If using Let's Encrypt through NPM, verify:
#   - Domain resolves first (step 1)
#   - Port 80 is open (for ACME challenge)
```

## NPM Nginx Config Regeneration (When UI Inaccessible)

When NPM container is running but the web UI (port 81) is unreachable, you must manually write nginx config and reload:

```bash
# 1. Get proxy host configs from NPM database (inside container)
docker exec <npm_container> cat /data/database.sqlite3 | sqlite3 | select id, domain_names, forward_host, forward_port, certificate_id, ssl_forced from proxy_hosts;

# 2. Find which cert ID maps to which domain
docker exec <npm_container> openssl x509 -in /etc/letsencrypt/live/npm-1/cert.pem -noout -subject

# 3. Write nginx config to /etc/nginx/conf.d/<domain>.conf
# 4. Test & reload
docker exec <npm_container> nginx -t
docker exec <npm_container> nginx -s reload
```

**Note:** After changing `forward_host` or `forward_port` in the database, nginx config is NOT auto-regenerated. You must manually write the server block and reload.

## Cloudflare SSL Mode Issues

| Error | Cause | Fix |
|-------|-------|-----|
| **HTTP 525** | Cloudflare SSL=Flexible but origin has no cert (or cert invalid) | Set Cloudflare SSL=Flexible, or fix origin cert |
| **SSL handshake failed** | Cloudflare SSL=Full but origin has no cert | Either set Flexible, or install valid cert on origin |
| **Too many redirects** | Cloudflare SSL=Full + origin forces HTTP→HTTPS loop | Set Cloudflare SSL=Flexible, or remove origin redirect |

**For domains with valid Let's Encrypt cert on origin:** Use **Full** mode.
**For domains without cert on origin:** Use **Flexible** mode (shows 🔓 in browser).

## Common Architecture Pattern on VPS

```
Internet → Cloudflare DNS → VPS (port 443 open)
  → Docker: nginx-proxy-manager (network_mode: host, binds port 80/443/81 directly)
    → Forward to container IP on Docker network (e.g., 172.18.0.5:8000)
    → SSL: Let's Encrypt via NPM
```

**Key rules:**
1. NPM uses `network_mode: host` to avoid port binding conflicts with `docker-proxy`
2. `forward_host` must be container **IP** (not hostname) — NPM doesn't resolve Docker container names across networks
3. `forward_port` must be **container port** (not host-mapped port) when NPM uses `network_mode: host`
4. Cloudflare subdomains for API must be **DNS-only (grey cloud)** for Let's Encrypt HTTP-01 challenge

## Mobile App Google Sign-In Debugging

If Google Sign-In popup doesn't appear in Flutter mobile app (but works on web):

1. **SHA-1 fingerprint missing** — Most common cause. Add to Firebase Console:
   - Debug: `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep SHA1`
   - Release: same with release keystore path
2. **Google Sign-In not enabled** — Firebase Console → Authentication → Sign-in method → Google → Enable
3. **Package name mismatch** — Must match exactly between Firebase Console and `android/app/build.gradle`
4. **google-services.json outdated** — Re-download after adding SHA-1, place in `android/app/`
5. **Rebuild required** — `flutter clean && flutter pub get && flutter build apk --release`
