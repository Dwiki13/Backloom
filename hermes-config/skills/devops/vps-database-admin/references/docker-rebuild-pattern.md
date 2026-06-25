# Docker Rebuild Pattern — SubTrack

## Force Rebuild When Container Keeps Using Old Image

If `docker-compose up -d --build api` still runs old code, the container may be stuck on an old image due to network attachment caching:

```bash
# Nuclear option: remove container entirely, then rebuild
docker rm -f subtrack-api
cd /root/projects/subtrack-id/backend && docker-compose up -d --build api

# Verify the new code is running
docker exec subtrack-api python3 -c "
import inspect
import app.routes.payments as p
print(inspect.getsource(p.verify_midtrans_signature))
"
```

If the container fails to start due to `DATABASE_URL` resolving to wrong host (`localhost` instead of `postgres`), check that it's on the correct Docker network (`backend_net`):

```bash
# Inspect which networks the new container is on
docker inspect subtrack-api --format '{{json .NetworkSettings.Networks}}'
```

**Tip:** Always verify file updates inside the container after rebuild — don't trust the build cache.

## Network Gotcha: Container on Wrong Network

When recreating containers, Docker may attach them to `bridge` (default) instead of the project's custom networks (`backend_net`, `npm_default`). This breaks DB connectivity and nginx proxy access.

**Fix:** Use `docker-compose up` (which reads the compose file's `networks:` section) instead of `docker run` or manual `docker network connect`.
