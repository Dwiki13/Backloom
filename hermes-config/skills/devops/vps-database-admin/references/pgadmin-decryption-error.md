# pgAdmin Password Decryption Error

## Error Log Snippet
```
2026-06-09 01:50:32,366: ERROR\tpgadmin:\t'utf-8' codec can't decode byte 0xaf in position 1: invalid start byte
UnicodeDecodeError: 'utf-8' codec can't decode byte 0xaf in position 1: invalid start byte
2026-06-09 01:50:32,369: ERROR\tpgadmin:\tCould not connect to server(#100) - 'SubTrack DB'.
Error: Failed to decrypt the saved password.
Error: 'utf-8' codec can't decode byte 0xaf in position 1: invalid start byte
::ffff:103.247.21.216 - - [09/Jun/2026:01:50:32 +0000] \"POST /browser/server/connect/1/100 HTTP/1.1\" 401 310 \"http://202.10.46.161:5050/browser/\" \"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36\"
```

## Root Cause
The password stored in the `server.password` column was encrypted using a method incompatible with pgAdmin's internal decryption routine. This occurred when attempting to manually encrypt the password outside of pgAdmin (e.g., using a Python script that mimicked the encryption but used a different key or mode).

pgAdmin v9.15 uses AES‑CFB8 encryption with a key derived from the `SECRET_KEY` stored in the `keys` table. External encryption attempts that do not replicate this exact process (including the same IV handling and key padding) produce ciphertext that pgAdmin cannot decrypt, leading to the `UnicodeDecodeError` when trying to interpret the decrypted bytes as UTF‑8.

## Resolution
1. Delete the problematic server record from pgAdmin's internal SQLite database:
   ```sql
   DELETE FROM server WHERE id = <SERVER_ID>;
   ```
2. Re‑register the server via the pgAdmin web UI, entering the password directly in the connection form and ensuring **"Save Password"** is checked. This causes pgAdmin to encrypt the password using its own internal routine, guaranteeing compatibility.

## Verification
- After re‑registering, the server connects successfully.
- No decryption errors appear in pgAdmin logs.
- The `password` column now contains a value that pgAdmin can decrypt correctly.
