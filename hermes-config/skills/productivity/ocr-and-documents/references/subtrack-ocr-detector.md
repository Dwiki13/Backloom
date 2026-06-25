# OCR Detector — SubTrack ID Pattern

## Context
SubTrack ID uses OCR to detect subscriptions from bank statement screenshots/receipts.
The pipeline: file upload → OCR text extraction → keyword-based detection.

## detect_from_text() Behavior

Location: `backend/app/services/detector.py`

**Important quirk**: Keyword and price MUST be on the same line for detection to work.
The function iterates per keyword, per line — checks if keyword is in the line AND
if `extract_price()` finds a price in that same line.

```
# Works:
NETFLIX Rp 169.000
SPOTIFY Rp 54.000

# Won't detect (keyword and price on different lines):
NETFLIX
Rp 169.000
```

**Keyword list** (27 services): NETFLIX, SPOTIFY, DISNEY, HOTSTAR, CANVA, YOUTUBE,
ICLOUD, GOOGLE ONE, VIDIO, VIU, WE TV, IQIYI, CHATGPT, OPENAI, MIDJOURNEY, ADOBE,
MICROSOFT, DROPBOX, GITHUB, FIGMA, NOTION, GRAMMARLY, TOKOPEDIA, BUKALAPAK, SHOPEE,
LAZADA

**Price patterns recognized**:
- `Rp 169.000` / `Rp 169,000`
- `169.000 IDR` / `169000 RUPIAH`
- `amount: Rp 169.000` / `jumlah Rp 169.000`

## OCR Stack
- **PDF**: `pdfplumber` — page-by-page text extraction via `BytesIO`
- **Image**: `pytesseract` + `Pillow` — `Image.open(BytesIO(content))` → `image_to_string()`
- **System dep**: `tesseract-ocr` binary (v5.3.4 on VPS)

## Environment Check
```bash
which tesseract          # /usr/bin/tesseract
tesseract --version      # 5.3.4
python3 -c "import pdfplumber; import pytesseract; from PIL import Image; print('OK')"
```
