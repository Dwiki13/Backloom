# SSL Origin Setup for New Domains (Nginx Proxy Manager / Docker)

## When

Adding a new domain to NPM that needs HTTPS but currently only has HTTP origin (e.g., a web app running on port 80). Cloudflare returns **HTTP 525** when SSL mode is Full/Full (Strict) but origin has no SSL.

## Root Cause

Cloudflare 525 = "SSL handshake failed between Cloudflare and origin." This means:
- Cloudflare connects to your server on port 443
- Your server either doesn't have port 443 listening, OR
- Port 443 is listening but SSL handshake fails (wrong cert, expired, or no SSL configured)

For domains behind NPM, the issue is usually that **NPM only has an HTTP server block** in the proxy config.

## Fix Pattern: Add SSL Server Block to NPM Nginx Config

This is a template for adding HTTPS to a domain. Replace `DOMAIN`, `CERT_ID`, `CERT_PATH`, `ORIGIN_IP`, and `ORIGIN_PORT`:

```nginx
# HTTP → HTTPS redirect
server {
    listen 80;
    listen [::]:80;
    server_name DOMAIN www.DOMAIN;
    include /etc/nginx/conf.d/include/letsencrypt-acme-challenge.conf;
    location / { return 301 https://$host$request_uri; }
}

# HTTPS proxy
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name DOMAIN www.DOMAIN;
    ssl_certificate /etc/letsencrypt/live/CERT_ID/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/CERT_ID/privkey.pem;
    include /etc/nginx/conf.d/include/ssl-ciphers.conf;
    include /etc/nginx/conf.d/include/block-exploits.conf;
    location / {
        proxy_pass http://ORIGIN_IP:ORIGIN_PORT;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

**Note:** Do NOT include `/etc/nginx/conf.d/include/proxy.conf` inside a server block that already has `proxy_pass` — it contains `proxy_pass` which causes `nginx: [emerg] "proxy_pass" directive is not allowed here`.

## Finding the Right Cert ID

```bash
# List certs
ls /root/npm/letsencrypt/live/

# Check cert domain
openssl x509 -in /root/npm/letsencrypt/live/npm-N/cert.pem -noout -subject
# → subject=CN = your-domain.com
```

## Full Fix Sequence

```bash
# 1. Write the config (use heredoc carefully - $host gets swallowed by bash)
# Use Python/tee approach instead:
cat > /tmp/domain_ssl.conf << 'NGINXEOF'
... (template above) ...
NGINXEOF

# 2. Copy into container
docker cp /tmp/domain_ssl.conf npm_npm_1:/etc/nginx/conf.d/domain.conf

# 3. Validate
docker exec npm_npm_1 nginx -t

# 4. Reload
kill -HUP $(pgrep -f "nginx: master" | head -1)  # or kill + wait for s6 restart

# 5. Test
curl -sk --connect-timeout 10 https://DOMAIN
# Expected: HTML content (200) or API response (401/403/etc)

# 6. Test SSL cert
openssl s_client -connect DOMAIN:443 -servername DOMAIN </dev/null 2>/dev/null | openssl x509 -noout -dates -subject
```

## Common Pitfalls

| Pitfall | Cause | Fix |
|---------|-------|-----|
| `$host` becomes empty | Bash heredoc interpolates `$host` as env var | Use quoted heredoc `<< 'EOF'` or write via Python script |
| `proxy_pass is not allowed` | `include proxy.conf` inside server block that has proxy_pass | Remove that include, set proxy_set_header manually |
| Cloudflare 525 | Origin has no SSL cert on port 443 | Add the SSL server block as above |
| Cloudflare 502 | SSL cert mismatch (SNI issue) | Ensure server_name matches cert CN |
| nginx -t fails silently | Missing `ssl_certificate_key` directive | Both cert AND key must be specified |
| Config written but no effect | nginx didn't reload | `kill -HUP master_pid` or restart container |

## Cloudflare SSL/TLS Mode Recommendations

| Setup | Cloudflare SSL Mode |
|-------|---------------------|
| Origin has no cert | **Flexible** (quick, no SSL needed on origin) |
| Origin has self-signed cert | **Full** (not Flexible) |
| Origin has valid Let's Encrypt cert | **Full (Strict)** |
| API subdomain (needs security) | **Full** + DNS only (gray cloud) during LE issuance |

**⚠️ Important:** After issuing a new Let's Encrypt cert on NPM, switch Cloudflare from **Flexible → Full**. Flexible mode can cause redirect loops when origin already does HTTP→HTTPS redirect.

## SubTrack ID Example (devlokal.id)

```bash
# devlokal container: 172.17.0.3 (bridge network), port 80
# Let's Encrypt cert: npm-1 (issued Jun 3, expires Sep 1, 2026)

cat > /tmp/devlokal_ssl.conf << 'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name devlokal.id www.devlokal.id;
    include /etc/nginx/conf.d/include/letsencrypt-acme-challenge.conf;
    location / { return 301 https://$host$request_uri; }
}
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name devlokal.id www.devlokal.id;
    ssl_certificate /etc/letsencrypt/live/npm-1/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/npm-1/privkey.pem;
    include /etc/nginx/conf.d/include/ssl-ciphers.conf;
    include /etc/nginx/conf.d/include/block-exploits.conf;
    location / {
        proxy_pass http://172.17.0.3:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# This WILL break because bash expands $host to empty string.
# Use Python write to avoid this:
python3 -c "
content = '''server {
    listen 80; listen [::]:80;
    server_name devlokal.id www.devlokal.id;
    include /etc/nginx/conf.d/include/letsencrypt-acme-challenge.conf;
    location / { return 301 https://\$host\$request_uri; }
}
...
'''
with open('/tmp/devlokal_ssl.conf', 'w') as f:
    f.write(content)
"
```
