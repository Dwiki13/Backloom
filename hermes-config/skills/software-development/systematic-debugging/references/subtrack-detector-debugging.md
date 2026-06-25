# SubTrack ID — Detector Debugging Notes

## Context
SubTrack ID's `/api/v1/detect` endpoint uses OCR + LLM + regex to detect subscriptions from uploaded proof images.

## File Layout (as of June 2026)
```
backend/app/
├── services/
│   ├── llm_detector.py    # LLM-based detection (primary)
│   └── detector.py        # Regex-based detection (secondary)
├── routes/
│   └── detector.py        # /api/v1/detect and /api/v1/detect/confirm
```

## Key Debugging Sessions

### 1. Price Extraction Fallback (June 13, 2026)

**Problem**: "Bayar Netflix" on last line of OCR text, no price on same line → `extract_price(line)` returns None → item skipped entirely.

**Failed fix 1**: `extract_price(text)` — returns first price from entire document (wrong: Rp 90.000 instead of Rp 50.000).

**Failed fix 2**: Fixed window of 3 lines — still missed (price was 8 lines away).

**Working fix**: Expanding outward search from keyword line. See `_find_nearest_price()` in `detector.py`.

### 2. SKIP_KEYWORDS False Positives for Family Vault (June 13, 2026)

**Problem**: Family vault members pay subscriptions via transfer. Full-text SKIP_KEYWORDS check flagged ALL items as `is_subscription: false` when "transfer" appeared anywhere in the text.

**Failed fix**: Check SKIP_KEYWORDS against full text → broke family vault flow.

**Working fix**: Only check SKIP_KEYWORDS on `source_line` (per-line). "Bayar Netflix" on its own line → `is_subscription: true`. "Transfer Netflix Rp 50.000" on same line → `is_subscription: false`.

### 3. LLM Prompt Update (June 13, 2026)

Added explicit instruction: "Do NOT include one-time transfers, person-to-person payments, top-ups, or shopping purchases."

Added new response fields: `is_subscription` (bool), `confidence` (0-1), `reason` (string).

## Test Cases

```python
# Family vault: transfer + subscription keyword on separate lines
text = """Bukti Transaksi
Jumlah Transfer Rp 50.000
Bayar Netflix"""
# Expected: Netflix, is_subscription=true, price=50000

# Transfer only (no subscription keyword)
text = """Bukti Transfer
Dari Budi Ke Joko
Jumlah Rp 100.000"""
# Expected: 0 items

# Subscription keyword on same line as transfer
text = """Transfer Netflix Rp 59.000"""
# Expected: Netflix, is_subscription=false, confidence=0.3
```

## Deployment Notes
- Repo: `github.com/Dwiki13/subtrack-id`
- API runs on port 8002 via Docker
- Compose file: `backend/docker-compose.yml`
- Rebuild: `docker-compose up -d --build`
- Always pull before push (KII may have pushed from VPS)
