# Drive API Search Syntax

Reference for `$GAPI drive search` queries — covers both default and raw-query modes.

## Default Mode

The `search` subcommand wraps the `query` argument into a `fullText contains '...'` Drive API call.

```
# Simple keyword search (searches file name + content text)
$GAPI drive search "quarterly report" --max 10
```

This is equivalent to `fullText contains 'quarterly report'`.

## Raw Query Mode (`--raw-query`)

For any query involving `parents in`, `mimeType`, date filters, boolean combinators,
shared-drive filters, or non-primary text properties you **MUST** use `--raw-query`.
Without it, `drive search` wraps your query in `fullText contains '...'` which
produces an `Invalid Value` error.

```
# List children of a specific folder
$GAPI drive search "'FOLDER_ID' in parents and trashed=false" --raw-query --max 50

# List only sub-folders inside a folder
$GAPI drive search "mimeType='application/vnd.google-apps.folder' and 'FOLDER_ID' in parents and trashed=false" --raw-query --max 50

# Search by MIME type across all of Drive
$GAPI drive search "mimeType='application/vnd.google-apps.spreadsheet'" --raw-query --max 50

# Exclude trashed files from a keyword search
$GAPI drive search "name contains 'report' and trashed=false" --raw-query --max 20
```

## Common Drive API Query Operators

| Operator | Example | Description |
|----------|---------|-------------|
| `'ID' in parents` | `'abc123' in parents` | Files inside a folder |
| `mimeType=` | `mimeType='application/vnd.google-apps.folder'` | Filter by MIME type |
| `name contains` | `name contains 'budget'` | Name substring match |
| `trashed=false` | `trashed=false` | Exclude trashed files |
| `modifiedTime>` | `modifiedTime>='2026-01-01T00:00:00Z'` | Modified after date |
| `and` / `or` / `not` | `A and B`, `A or B`, `not C` | Boolean combinators |
| `(` `)` | `('id1' in parents or 'id2' in parents)` | Grouping |

## Common MIME Types

| Type | Value |
|------|-------|
| Folder | `application/vnd.google-apps.folder` |
| Spreadsheet | `application/vnd.google-apps.spreadsheet` |
| Document | `application/vnd.google-apps.document` |
| PDF | `application/pdf` |
| Plain text | `text/plain` |

## Drive `get` (single file/folder metadata)

```
# Get metadata for a file or folder by ID
$GAPI drive get FILE_ID
```

Returns: `id`, `name`, `mimeType`, `modifiedTime`, `size`, `webViewLink`, `parents`, `owners`.

## Pitfalls

- **`parents in` / boolean / mimeType queries silently fail** if you forget `--raw-query`.
  Error: `HttpError 400: Invalid Value`. Fix: add `--raw-query`.
- `--max` defaults to 100 in the script. Use lower values (e.g., `--max 50`) for large
  folders to keep output manageable.
- `fullText contains` mode cannot search file names by substring -- it searches indexed
  text content AND the exact full name. Use `name contains 'term'` with `--raw-query` for
  partial name matching.
