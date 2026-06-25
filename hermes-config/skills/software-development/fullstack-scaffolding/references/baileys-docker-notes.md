# Baileys v6 + Docker Networking — Debugging Notes

## Baileys v6 Migration

### Breaking Change: makeCacheableSignalKeyStore
Baileys v6 REQUIRES `makeCacheableSignalKeyStore`. Without it, Baileys connects then immediately disconnects in an infinite loop.

```javascript
const {
  makeWASocket, useMultiFileAuthState, makeCacheableSignalKeyStore,
  DisconnectReason, fetchLatestBaileysVersion,
} = require("@whiskeysockets/baileys");

const { state, saveCreds } = await useMultiFileAuthState(AUTH_DIR);
const { version } = await fetchLatestBaileysVersion();

const sock = makeWASocket({
  version,
  auth: { creds: state.creds, keys: makeCacheableSignalKeyStore(state.keys, { trace: () => {} }) },
  printQRInTerminal: false,
  browser: ["Second Brain", "Chrome", "1.0.0"],
  syncFullHistory: false,
  markOnlineOnConnect: false,
});
```

### Auth State
- Dir: `.baileys_auth/` (NOT `.wwebjs_auth/`)
- Clear when switching adapters: `rm -rf .baileys_auth`
- On `DisconnectReason.loggedOut`: clear auth + restart

### Large JSON Lines from Baileys
QR code JSON can exceed Node.js `readline()` 64KB buffer limit. Use custom chunked reader in Python — see baileys.py `_read_stdout()` method.

### npm install in Docker
`@whiskeysockets/baileys` installs from GitHub — requires `git` in Dockerfile apt-get.

## Docker Networking

### Multi-Network Containers
`docker network connect npm_default secondbrain-api` — attach container to additional networks.

### Docker Compose v1 ContainerConfig Bug
`docker-compose down` + `up` can fail with `KeyError: 'ContainerConfig'`. Fix: `docker rm -f <container>` then `up`.

### DNAT Hijacking
Docker published ports add iptables DNAT rules. Check: `iptables -t nat -L -n | grep PORT`.
