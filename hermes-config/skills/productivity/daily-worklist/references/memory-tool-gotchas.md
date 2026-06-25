# Memory Tool Gotchas

Lessons learned from live debugging (2026-05-30).

## The Drift Problem

MEMORY.md and USER.md are managed by the `memory` tool, NOT by `write_file` or `patch`. If any other tool writes to these files, the memory tool's round-trip parser detects drift and **permanently refuses** to make any further edits until the file is cleared.

## Recovery Procedure

If `memory(action=add/replace/remove)` fails with "wouldn't round-trip":

```bash
echo -n "" > /root/.hermes/memories/MEMORY.md   # or USER.md
```

Then rebuild entries via `memory(action=add, content=...)`.

## Capacity Management

- MEMORY.md: 2,200 char limit
- USER.md: 1,375 char limit
- When near limit: compress entries or remove stale ones before adding new ones

## § Delimiter

The `§` character on its own line is the entry separator. The memory tool auto-injects it — never add it manually when calling `memory(action=add)`.
