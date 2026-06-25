# Contributing to Backloom

Thanks for wanting to contribute! Here's how to get started.

## Ways to Contribute

- **Bug reports** — Open an issue with your OS, Docker version, and the error output
- **Feature requests** — Open an issue describing the use case
- **Pull requests** — Bug fixes, new database support, new cloud providers
- **Testing** — Try it on your own VPS setup and report what works / doesn't

## Developing

Backloom is pure Bash — no build step needed.

```bash
git clone https://github.com/YOUR_USERNAME/backloom.git
cd backloom

# Test syntax before submitting
bash -n install.sh && echo "Syntax OK"
```

## Pull Request Guidelines

1. Test your changes on Ubuntu 22.04+ before submitting
2. Keep the installer self-contained (single file, no external dependencies beyond curl/docker/rclone)
3. Add new database types to `detect_databases()` and handle them in both backup + restore sections
4. Update README.md if adding new features or supported platforms

## Adding a New Database Type

In `install.sh`, find the `detect_databases()` function and add detection:

```bash
echo "$image" | grep -qi "yourdb" && db_type="yourdb"
```

Then handle it in the generated backup script's `case "$db_type"` block.

## Reporting Bugs

Please include:
- OS and version (`lsb_release -a`)
- Docker version (`docker --version`)
- Full error output
- Your `docker ps -a` output (redact passwords)

## Code Style

- 2-space indentation
- Use helper functions: `info()`, `ok()`, `warn()`, `die()`
- Keep user-facing messages concise and friendly
- Always test with `bash -n` before pushing

---

All contributions are welcome, big or small. Thank you!
