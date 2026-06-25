# Password with Asterisks (`***`) — Shell Globbing Pitfall

## Problem

When a password contains `***` (3 asterisks) or other glob characters (`*`, `?`, `[`), shell commands like `sed`, `echo`, `printf`, and `cat` may interpret them as glob patterns or regex metacharacters.

## Common Failures

### sed regex replacement
```bash
# BROKEN — *** treated as regex (zero or more of zero or more)
sed 's/hermes:***/hermes:NEWPASS/' file.env

# BROKEN — even with escaping
sed 's/hermes:\*\*\*/hermes:NEWPASS/' file.env
```

### printf / echo with glob
```bash
# RISKY — *** may expand to filenames in current directory
echo "postgresql://hermes:***@host/db" > file.env
printf "%s\n" "postgresql://hermes:***@host/db" > file.env
# If no files match ***, it stays as *** (usually OK, but fragile)
```

### Python replace with wrong target
```python
# BROKEN — replacing "***" when actual password is different
content = content.replace(b'***', b'newpass')  # password might not be ***
```

## Diagnosis

Check actual file bytes with `od` or `hexdump` (NOT `cat` which may mask output):
```bash
od -c /path/to/.env.production
# 2a 2a 2a = *** (asterisks)
# 68 65 72 6d 65 73 = hermes
```

## Solutions

### 1. Use Python for file editing (most reliable)
```python
python3 -c "
with open('/path/to/.env.production', 'rb') as f:
    content = f.read()
content = content.replace(b'OLD_BYTES', b'NEW_BYTES')
with open('/path/to/.env.production', 'wb') as f:
    f.write(content)
"
```

### 2. Use cat with heredoc (single-quoted delimiter prevents ALL expansion)
```bash
cat > /path/to/.env.production << 'ENDOFFILE'
DATABASE_URL=postgresql://hermes:***@postgres:5432/subtrack
ENDOFFILE
```
**Critical:** The `'ENDOFFILE'` single quotes prevent ALL shell expansion. Without them, `$VAR` and `*` would still expand.

### 3. Set password in PostgreSQL to match what's in the file
```bash
# If file has *** as password, set DB password to ***
docker exec postgres psql -U hermes -d subtrack -c "ALTER USER hermes PASSWORD '***';"
```

## Prevention

1. **Avoid `***` in passwords** — use alphanumeric passwords like `hermes_db_2026`
2. **Always use Python for .env file editing** — avoids all shell escaping issues
3. **Verify with `od -c`** — `cat` may mask output; always check actual bytes
4. **When using heredoc, ALWAYS single-quote the delimiter** (`<< 'EOF'` not `<< EOF`)
