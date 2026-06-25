# SSH Tunnel + pgAdmin Setup for VPS PostgreSQL

Reference from subtrack-id (2026-06-07). How to access VPS PostgreSQL from local PC via SSH tunnel + pgAdmin.

## When to Use

- VPS PostgreSQL is NOT exposed to public internet (security best practice)
- You need GUI access to inspect/debug database
- pgAdmin on local PC cannot directly connect to VPS internal Docker network

## Prerequisites

- SSH access to VPS (key-based auth preferred)
- pgAdmin 4 installed on local PC
- PostgreSQL running in Docker on VPS (not exposed to host network)

## Step 1: Ensure SSH Key is on VPS

From local PC (PowerShell):
```powershell
type C:\Users\user\.ssh\id_rsa.pub
```

Copy the output, then SSH into VPS and append it:
```bash
ssh root@<VPS_IP>
mkdir -p ~/.ssh
echo "PASTE_KEY_HERE" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
exit
```

**Note:** If using `type ... | ssh ... "cat >> ..."` pipe approach, the key may not actually get appended due to PowerShell pipe handling. Use the two-step approach above for reliability.

## Step 2: Open SSH Tunnel

From local PC (PowerShell or Git Bash):
```powershell
ssh -N -L 15432:localhost:5432 root@<VPS_IP>
```

- `-N` = no shell, just forward ports
- `-L 15432:localhost:5432` = forward local port 15432 to VPS's localhost:5432
- Use port `15432` (not `5432`) to avoid conflict with local PostgreSQL
- **Keep this terminal open** while using pgAdmin

**Troubleshooting:**
- `bind [127.0.0.1]:5432: Address already in use` → local PostgreSQL is running, use `15432` instead
- `Permission denied` → SSH key not in `authorized_keys`, use password or fix key
- `Connection refused` in pgAdmin → tunnel not active, check terminal

## Step 3: Configure pgAdmin

1. Open pgAdmin 4
2. Right-click **Servers** → **Register** → **Server**
3. **General** tab: Name = `SubTrack VPS` (or any name)
4. **Connection** tab:
   - Host: `localhost`
   - Port: `15432`
   - Maintenance database: `subtrack` (or `postgres`)
   - Username: `hermes` (or your DB user)
   - Password: (your DB password)
5. Click **Save**

## Step 4: Verify

If connection succeeds, you should see:
```
Servers
  └── SubTrack VPS
       └── Databases
            └── subtrack
                 └── Tables
                      ├── family_members
                      ├── family_vaults
                      ├── payments
                      ├── subscriptions
                      └── users
```

## Common Pitfalls

- **Terminal closed = tunnel dead**: If you close the SSH terminal, pgAdmin loses connection
- **Port conflict**: Always use non-standard local port (15432) if local PostgreSQL exists
- **Key format**: OpenSSH keys work directly. PuTTY users need `.ppk` format (convert via PuTTYgen)
- **Password change**: If DB password was changed on VPS, update pgAdmin connection settings
- **Docker network hostname**: If PostgreSQL is on a Docker network with hostname `postgres` (not `localhost`), the tunnel destination should be `postgres:5432` instead of `localhost:5432`. Verify with `docker exec <api_container> cat /app/.env.production | grep DATABASE_URL` to see what hostname the backend uses.

## Alternative: Direct Port Exposure (Less Secure)

If SSH tunnel is too cumbersome, you can expose PostgreSQL port on VPS with firewall restriction:

```bash
# On VPS: allow only your IP
ufw allow from <YOUR_IP> to any port 5432
```

Then connect pgAdmin directly to `<VPS_IP>:5432`. **Not recommended** for production.
