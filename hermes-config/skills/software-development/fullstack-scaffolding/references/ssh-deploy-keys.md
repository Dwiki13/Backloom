# SSH Deploy Key Setup for GitHub Actions → VPS

## Generate Key Pair

```bash
ssh-keygen -t ed25519 -f ~/.ssh/PROJECT_deploy -N "" -C "github-actions-deploy"
```

Produces:
- `~/.ssh/PROJECT_deploy` — private key → GitHub Secret `VPS_SSH_KEY`
- `~/.ssh/PROJECT_deploy.pub` — public key → VPS `~/.ssh/authorized_keys`

## Add Public Key to VPS

```bash
# On the VPS:
echo "ssh-ed25519 AAAA... github-actions-deploy" >> ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

## Test Connection

```bash
ssh -o StrictHostKeyChecking=no -i ~/.ssh/PROJECT_deploy user@host "echo OK && hostname"
```

## Add to GitHub Secrets

Repo → Settings → Secrets and variables → Actions → New repository secret:

- `VPS_HOST`: IP address or hostname
- `VPS_USER`: SSH username (e.g. `root`)
- `VPS_SSH_KEY`: Entire contents of private key file (including `-----BEGIN...` and `-----END...`)

## Troubleshooting

| Problem | Fix |
|---------|-----|
| "Permission denied" | Check `authorized_keys` has the correct public key, permissions are 600 |
| "Host key verification failed" | Add `-o StrictHostKeyChecking=no` to SSH command |
| Wrong compose syntax | Test `docker-compose --version` vs `docker compose version` on VPS |
| Deploy key not working | Ensure key has no passphrase (`-N ""` during generation) |
