# Detector OCR Extraction Pitfalls — SubTrack ID

> Lessons learned from debugging the subscription detector (June 2026).

## Problem 1: Price on Different Line Than Keyword

**Symptom:** OCR produces text where the subscription keyword (e.g., "Netflix") is on a line without a price, but the price appears elsewhere in the document.

Example OCR output:
```
Bayar Netflix
...
Jumlah Transfer Rp 50.000
```

**Root cause:** `extract_price(line)` only searches the matched line. If no price on that line → item silently skipped.

**Wrong fix (don't do this):**
```python
price = extract_price(line)
if not price:
    price = extract_price(text)  # WRONG: takes first price from entire text
```
This grabs the WRONG price (e.g., "Rp 90.000" from the top of the document instead of the transfer amount near the keyword).

**Correct fix:** Use expanding outward search from the keyword line:
```python
def _find_nearest_price(lines: list[str], keyword_idx: int) -> float | None:
    """Search for price in lines nearest to the keyword line (expanding outward)."""
    offset = 1
    while keyword_idx - offset >= 0 or keyword_idx + offset < len(lines):
        if keyword_idx - offset >= 0:
            price = extract_price(lines[keyword_idx - offset])
            if price:
                return price
        if keyword_idx + offset < len(lines):
            price = extract_price(lines[keyword_idx + offset])
            if price:
                return price
        offset += 1
    return None
```

This scans line-by-line outward from the keyword (up and down simultaneously), guaranteeing the NEAREST price is found regardless of distance.

---

## Problem 2: SKIP_KEYWORDS and Family Vault Flow

**Symptom:** Family vault members pay subscriptions via transfer. OCR produces "Bayar Netflix" on the transfer receipt. The detector needs to still flag this as a subscription.

**Key insight:** In family vault flow, "transfer" is the PAYMENT METHOD, not an indicator that something is NOT a subscription. Members transfer money TO the owner to share subscription costs.

**Wrong approach (don't do this):**
```python
# Checking SKIP_KEYWORDS against ENTIRE text
full_text_lower = text.lower()
is_transfer_context = any(skip.lower() in full_text_lower for skip in SKIP_KEYWORDS)
if is_transfer_context:
    item["is_subscription"] = False  # WRONG: breaks family vault
```
This flags ALL items as non-subscription whenever "transfer" appears anywhere in the document, even if "Netflix" is on a separate line.

**Correct approach:** Only check SKIP_KEYWORDS on the **source_line** (per-line):
```python
for item in results:
    source = item.get("source_line", "").lower()
    if any(skip.lower() in source for skip in SKIP_KEYWORDS):
        item["is_subscription"] = False
        item["confidence"] = 0.3
        item["reason"] = "transfer context on same line"
```

This means:
- "Bayar Netflix" (no transfer keyword on same line) → `is_subscription: true` ✅
- "Transfer Netflix Rp 59.000" (transfer + keyword on same line) → `is_subscription: false` ✅
- "Transfer" appears somewhere else in document → doesn't affect detection ✅

---

## SKIP_KEYWORDS List (Working Set — June 2026)

```python
SKIP_KEYWORDS = [
    "transfer", "kirim", "top up", "topup", "saldo",
    "paylater", "cicilan", "ovo", "gopay", "dana", "shopeepay",
    "ke ", "kepada", "penerima", "transfer ke",
]
```

These mark items as `is_subscription: false` with `confidence: 0.3` when found on the **same line** as the subscription keyword.

---

## Detector Architecture (After June 2026 Changes)

Two detection layers run in parallel:

1. **LLM (primary):** OpenRouter LLM (`openrouter/owl-alpha`) with explicit prompt to exclude one-time transfers. Returns `is_subscription`, `confidence`, `reason`.
2. **Regex (supplementary):** Static keyword matching against `SUBSCRIPTION_KEYWORDS` dict with `SKIP_KEYWORDS` per-line filter. Same return format.

Both layers use the same response schema:
```python
{
    "name": str,
    "category": str,
    "price": float,
    "currency": "IDR",
    "billing_cycle": "monthly",
    "confidence": float,
    "is_subscription": bool,
    "reason": str,
}
```

Results are merged by name (case-insensitive), keeping the higher confidence score. Final list sorted by confidence descending.

---

## Family Vault Context

Subscriptions are **per-user**, not per-vault. Each family member who pays for a subscription via transfer should:
1. Upload their transfer proof to `/api/v1/detect`
2. Review detected items (the detector should find "Netflix" etc. even on transfer receipts)
3. Confirm via `/api/v1/detect/confirm` → subscription is registered under THEIR user_id

This means each member has their own subscription records, reminders, and billing dates.

---

## Response Schema (Post-June 2026)

`POST /api/v1/detect` response:
```json
{
  "message": "Detection complete",
  "filename": "bukti.jpg",
  "size": 12345,
  "detected": [
    {
      "name": "Netflix",
      "category": "entertainment",
      "price": 50000,
      "currency": "IDR",
      "billing_cycle": "monthly",
      "confidence": 0.8,
      "is_subscription": true,
      "reason": "keyword match: NETFLIX"
    }
  ]
}
```

`POST /api/v1/detect/confirm` request:
```json
{
  "items": [
    {
      "name": "Netflix",
      "price": 59000,
      "currency": "IDR",
      "billing_cycle": "monthly",
      "category": "entertainment",
      "next_billing_date": "2026-07-13"
    }
  ]
}
```

---

## Deploy Checklist (VPS)

KII's standard deploy command:
```bash
docker-compose up -d --build
```

If code changes don't take effect:
1. Verify changes are in the built image: `docker exec <container> cat /app/path/to/file`
2. Rebuild with cache clear: `docker-compose build --no-cache <service>`
3. Recreate container: `docker stop <container> && docker rm <container> && docker-compose up -d <service>`
