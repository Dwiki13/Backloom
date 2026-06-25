---
name: document-generation
description: Generate business documents (Quotation, Delivery Order, Invoice) for PT Harmoni Artha Sentra. Creates Excel + PDF files and uploads to Google Drive project-2026 folders. Auto-increments document numbers, handles merged cells in templates, converts to PDF via LibreOffice.
---

# Document Generation — PT Harmoni Artha Sentra

Generate Quotation, Delivery Order, and Invoice documents. Output: Excel + PDF, uploaded to Google Drive.

## Two Versions Available

### ✅ Go Version (Primary — Preferred)

**Path:** `/root/.hermes/docgen/` — compiled binary at `/root/.hermes/docgen/docgen`

YAML-driven, auto-downloads templates from GDrive, built-in Telegram notifier.

**Step 1:** Create a YAML config:

```yaml
type: quotation
client: PT Pasific Process Engineering
person: Pak Edy
validity: 1 Week
delivery: 7-14 Hari
items:
  - desc: RADIO VHF M330
    qty: 1
    uom: Pcs
    price: 6250000
  - desc: ECHOSOUNDER FURUNO FCV 689
    qty: 1
    uom: Pcs
    price: 24650000
```

**Step 2:** Run:

```bash
cd /root/.hermes/docgen && go run . --config your-config.yaml
# Or use the pre-built binary:
cd /root/.hermes/docgen && ./docgen --config your-config.yaml
```

Output: Excel + PDF generated, uploaded to GDrive, tracker updated, Telegram notification sent automatically.

To recompile: `cd /root/.hermes/docgen && go build -o docgen .`

### 🐍 Python Version (Legacy Fallback)

**Path:** `/root/.hermes/scripts/document_generator.py`

```bash
python3 /root/.hermes/scripts/document_generator.py  # test mode
```

Or import and call functions: `generate_quotation(...)`, `generate_delivery_order(...)`, `generate_invoice(...)`

## Key Files

| File | Purpose |
|------|---------|
| `/root/.hermes/scripts/document_generator.py` | Main script — QTN, DO, Invoice generation |
| `/root/.hermes/data/document-tracker.json` | Auto-increment counters + document history |
| `/root/.hermes/templates/` | Excel templates |
| `/root/.hermes/output/` | Generated files (Excel + PDF) |

## Required Credential Files

| File | Purpose | Required? |
|------|---------|-----------|
| `/root/.hermes/credentials/gdrive-oauth-token.json` | OAuth access + refresh token | ✅ Yes |
| `/root/.hermes/credentials/gdrive-oauth-client.json` | OAuth client_id + client_secret (for token refresh) | ✅ Yes |
| `/root/.hermes/credentials/gdrive-service-account.json` | Service account (cannot upload to user folders) | ❌ Optional |

⚠️ **Credential status as of May 2026:**
- `gdrive-oauth-token.json` — OAuth access + refresh token (auto-refreshed by Go version) ✅
- `gdrive-oauth-client.json` — OAuth client_id + client_secret (required for token refresh) ⚠️ VERIFY — may be missing
- `gdrive-service-account.json` — Service account (cannot upload to user-shared folders) ⚠️ Optional

⚠️ If `gdrive-oauth-client.json` is missing, GDrive upload will fail. OAuth is required for uploading to PT folders (service account can't access user-shared folders).

## Document Numbering

- **Format:** `QTN/HAS/YYYY/MM/SEQ`, `DO/HAS/YYYY/MM/SEQ`, `INV/HAS/YYYY/MM/SEQ`
- **Scope:** Global (not per-PT), resets SEQ to 001 each month
- **PO:** Manual number — user provides via file upload
- **Tracker:** `/root/.hermes/data/document-tracker.json` → `document_counters`

## Google Drive Structure

- **Root:** `12SsvGGk-m6wDPlELcgEtByUsXrWGDYen` (Project 2026)
- **Template folder (KII shared):** `10Ix63pMDiIELx-4qaOu-T9UwR2TYgg_r`
- Per PT: subfolders `Quotation/`, `PO/`, `Delivery Order/`, `Invoice/`
- PT folder IDs stored in tracker under `pt_folders`

## Item Format

```python
{
    "description": "Elbow 90° ASTM A234 Gr. WPB Sch STD; DN150; 6\"",
    "qty": 3,
    "uom": "Pcs",          # default: Pcs
    "unit_price": 574500,
    "total": 1723500       # optional, auto-calculated if missing
}
```

## Document Flow

1. Script loads template, fills data using `safe_write()` for merged cells
2. Calculates: Sub Total → Discount (optional) → PPN 11% → Grand Total
3. Saves Excel → converts to PDF via LibreOffice
4. Uploads both to Google Drive subfolder
5. Updates tracker with doc number, date, client, totals, drive links

## Company Info (auto-filled from tracker)

- **Name:** PT. HARMONI ARTHA SENTRA
- **Tagline:** General Supplier Marine, Oil & Gas, Sparepart, Safety First
- **Address:** Jl. Sabilillah, Medansatria, Bekasi 17132
- **Phone:** 0877-9178-6187 / 0896-0247-3532
- **Bank:** Mandiri 006-00-5399988-8 a/n PT HARMONI ARTHA SENTRA

## Template Row Mappings

### Quotation HAS.xlsx
| Field | Cell/Row |
|-------|----------|
| Title "QUOTATION" | B14:O14 (merged, static) |
| No Quotation label | J16:K16 (merged) |
| **No Quotation value** | **L16** (L16:O16 merged) ⚠️ NOT G16 |
| Tanggal label | J17:K17 (merged) |
| **Tanggal value** | **L17** (L17:O17 merged) ⚠️ NOT G17 |
| Kepada Yth label | B18 (static "Kepada Yth :") |
| Client name | B19 (+ "\nUp. Person" on same cell) |
| Table header | Row 24 (B=No, C:K=Desc, L=Qty, M=Uom, N=Harga, O=Total) |
| Items start | Row 25 |
| Sub Total | L row after last item, O = value |
| Grand Total | L row after subtotal, O = value (bold) |
| PPN | L row after grand total, O = value |
| Notes start | B30 (shifts down by n-1) |
| Bank | B41–D43 (shifts with items) |
| Sign-off "Hormat Kami" | N(bank+7) |
| Sign-off company name | N(bank+11) |

⚠️ **Merged cells are critical** — L16:O16, L17:O17, C24:K24, L26:N26, L27:N27 etc. Always write to the FIRST cell of a merged range. Inserting rows shifts everything below — use RemoveRow+InsertRows, NOT just InsertRows.
⚠️ **Client/Person share B19** — use newline (`\n`) to put "Up. Name" on second line of same cell. NOT a separate row.

### Invoice HAS.xlsx (UPDATED May 2026 — new template from GDrive)
| Field | Cell/Row |
|-------|----------|
| No Invoice | K16 |
| Tanggal | K17 |
| No PO | K18 |
| **⚠️ No Quotation / No DO fields REMOVED** | — |
| Kepada Yth | B20 |
| Up. [person] | B21 |
| Table header | Row 26 |
| **Items start** | **Row 27** |
| Sub Total / Grand Total | L+O rows after last item |
| Terbilang | B(grand+2) |
| Bank | B(terbilang+5) onwards |
| Sign-off | N(bank+7) |

### Delivery Order HAS.xlsx
| Field | Cell/Row |
|-------|----------|
| No DO | K16 |
| No PO | K17 |
| Tanggal Kirim | K19 |
| Kepada Yth | B21–B22 |
| Up. [person] | B23 |
| Table header | Row 27 |
| Items start | Row 28 |
| Sign-off | B/L rows after items |

## Go Version — Cell Mapping Pitfalls (CRITICAL)

The Go version (`/root/.hermes/docgen/`) uses `excelize/v2` to fill templates. These gotchas were discovered through actual template inspection:

### ⚠️ Quotation Number & Date — WRONG cells in old code
- **Doc number** → write to **L16** (merged L16:O16), NOT G16
- **Date** → write to **L17** (merged L17:O17), NOT G17
- Labels "No Quotation :" and "Tanggal :" are static in J16:K16 and J17:K17

### ⚠️ Client + Person — ONE cell, not two
- **B19 only** — write `"PT Name\nUp. Person"` with newline
- Do NOT write client to B19 and person to B20 (B20 doesn't exist as a data cell)

### ⚠️ Row Insert Strategy — RemoveRow FIRST
```go
// CORRECT:
f.RemoveRow(sheet, 25)          // remove placeholder
f.InsertRows(sheet, 25, n)      // insert n item rows
subTotalRow := 25 + n           // dynamic position

// WRONG:
f.InsertRows(sheet, 26, n)      // duplicates SubTotal/GrandTotal rows!
```

### ⚠️ Dynamic Row Positions
All rows below items shift by (n-1) from template positions:
- SubTotal = 25+n, GrandTotal = 26+n, PPN = 27+n
- Note rows shift: Validity = 31+(n-1), Delivery = 33+(n-1)
- Bank area: ~41+(n-1)

### ⚠️ Sub Total ≠ Grand Total
- Sub Total = sum of item prices (excluding tax)
- Grand Total = Sub Total + PPN
- Do NOT put Grand Total value in both Sub Total and Grand Total cells

### Verify After Any Template Change
Always inspect the actual template file before running:
```bash
cd /root/.hermes/docgen && go run /tmp/check_template.go
```
### Go Source Files (for debugging/modifying)
- `main.go` — CLI entry point, dispatches to generators
- `generator.go` — Core document generation logic (Excel fill + PDF)
- `config.go` — YAML config loading
- `parser.go` — Document type parsing
- `uploader.go` — Google Drive upload (OAuth)
- `notifier.go` — Telegram notification
- `tracker.go` — Document number tracking + counter management

### Skill Files
- SKILL.md: `/root/.hermes/skills/document-generator-go/SKILL.md` — Go-specific usage reference
- `references/template-row-mappings.md` — Cell-by-cell template layout (Quotation/Invoice/DO), verified May 2026

### DB-Linked Variant
- `/root/Procurement-HAS/docgen-go/` — Go docgen with PostgreSQL integration
- Supports `generate-id` mode to generate from DB quotation ID
- Uses same template filling logic but loads data from DB instead of YAML
- Token auto-refreshed by Go version using `gdrive-oauth-client.json`
- If `gdrive-oauth-client.json` is missing, token refresh will fail when token expires (~1 hour)

### ⚠️ Service Account vs OAuth
- Service Account **cannot upload to user-shared folders** — must use OAuth

### ⚠️ PDF Conversion
- `libreoffice --headless --convert-to pdf:calc_pdf_Export [file] --outdir [dir]`
- timeout=120 minimum

### ⚠️ Template Updates
- When KII updates a template in GDrive, replace the file in `/root/.hermes/templates/`
- **Always re-verify row mappings** after template update by inspecting the actual file
- Update the Template Row Mappings section above after each change

### ⚠️ Quotation Function Parameters
- Signature: `generate_quotation(client_name, client_person, items, validity, delivery_time, ...)`
- NOT `customer_person` or `delivery` — parameter names matter!

### ✅ OpenCode IS Available on VPS
- OpenCode is installed at `/root/.opencode/bin/opencode` (NOT in PATH — always use full path)
- For ALL coding tasks (Python/JS/etc), MUST use OpenCode — do NOT write_file/execute_code directly
- Command: `/root/.opencode/bin/opencode run "[task detail]" --model opencode/deepseek-v4-flash-free`
- This is a WAJIB workflow rule for every session
- See also: `opencode` skill (autonomous-ai-agents category)

## "Bisnis Topic Bot" — Telegram Bot Concept

KII wants a Telegram bot for natural language document generation.

### Command Format

**Quotation:**
```
buat quotation PT Pasific Process Engineering
Up. Pak John
items:
1. Elbow 90" DN150 x 2 pcs @ 500.000
2. Tee Equal DN100 x 1 pcs @ 300.000
```

**PO (via file upload):**
```
[upload file] caption: masukin po ini untuk customer PT X kasih nama file PPE 4026000506 ...
```

**DO:**
```
buat do untuk PT Pasific Process Engineering
Up. Pak John
items:
1. Elbow 90" DN150 x 2 pcs
```

**Invoice:**
```
buat invoice untuk PT Pasific Process Engineering
Up. Pak John
ref: QTN/HAS/2026/05/014
ref: PPE 4026000506
items:
1. Elbow 90" DN150 x 2 pcs @ 500.000
```
- `ref:` fields optional — cross-reference QTN/PO/DO

### Bot Output
- Generate document (xlsx + PDF)
- Upload to GDrive PT subfolder
- Send file + GDrive link to KII via Telegram
- Return document number

## Quotation Generation (Detailed) — from quotation-generator

### Document Numbering (Global, NOT per PT)

All document counters are **global across all PTs**. When generating the next document, ALWAYS scan existing files across ALL PT folders to find the highest number, then increment.

| Doc Type | Format | Example |
|----------|--------|---------|
| QTN | `QTN/HAS/YYYY/MM/XXX` | `QTN/HAS/2026/05/011` |
| DO | `DO/HAS/YYYY/MM/XXX` | `DO/HAS/2026/05/004` |
| INV | `INV/HAS/YYYY/MM/XXX` | `INV/HAS/2026/05/001` |
| PI | (same as QTN ref) | Uses referenced QTN number |

Counters auto-increment month if the current month changes.

### Full Document Pipeline (QTN → PO → DO → INV)

This skill covers the full document pipeline for each client/project. See:
- `references/delivery-order-template.md` — DO template structure
- `references/invoice-template.md` — Invoice template structure
- `references/quotation-template.md` — detailed quotation template structure
- `references/price-ref-pipe-fittings-2026.md` — pipe fitting price references (May 2026)
- `references/gdrive-folders.md` — Full folder ID reference
- `references/gdrive-upload.md` — Drive upload code patterns

### Additional Templates

- **Proforma Invoice.xlsx** — proforma invoice (uses BCA bank, different format)
- **Tertuju Untuk (Template Amplop Invoice).pdf** — envelope template
- **Surat Pernyataan.pdf** — statement letter
- **Kop Surat.pdf** — letterhead

### Additional Pitfalls (from quotation-generator)

- **Bank accounts differ by document type:** Quotation/Invoice use Mandiri (PT HAS), Proforma Invoice uses BCA (Tias Juliansyah). Match the template to the correct bank.
- **⚠️ Use Go version, not Python, for new work.** The Go version (`/root/.hermes/docgen/`) is the maintained tool. Python script is legacy fallback only.
- **Don't generate without confirmation:** Always show the draft to user first before saving to Drive unless they explicitly say "langsung save" or "langsung upload"
- **⚠️ Slash in filename:** `/` is valid in Drive filenames but NOT in local filesystem paths. Replace with `_` when saving locally.

### Company Info

- **Company:** PT. HARMONI ARTHA SENTRA
- **Tagline:** General Supplier Marine, Oil & Gas, Sparepart, Safety First
- **Address:** Jl. Sabilillah, Kel. Medansatria, Kec. Medansatria, Kota Bekasi, Jabar 17132
- **Phone:** 0877-9178-6187 / 0896-0247-3532
- **Bank Mandiri:** 006-00-5399988-8 a/n PT HARMONI ARTHA SENTRA
- **Bank BCA:** 7410740286 a/n TIAS JULIANSYAH (for Proforma Invoice)

### Key Folder IDs (Project 2026)

See `references/gdrive-folders.md` for the full list.
- Project 2026 root: `12SsvGGk-m6wDPlELcgEtByUsXrWGDYen`
- Template folder (KII shared): `10Ix63pMDiIELx-4qaOu-T9UwR2TYgg_r`
- Per PT: subfolders `Quotation/`, `PO/`, `Delivery Order/`, `Invoice/`

## References

- `references/openpyxl-merged-cells-workaround.md` — merged cell helper code
- `references/go-template-inspection.md` — Go template inspection pitfalls
- `references/template-row-mappings.md` — Cell-by-cell template layout (Quotation/Invoice/DO)
- `references/delivery-order-template.md` — DO template structure
- `references/invoice-template.md` — Invoice template structure
- `references/gdrive-upload.md` — Drive upload code patterns
- `references/gdrive-folders.md` — Full folder ID reference
- `references/quotation-template.md` — detailed quotation template structure
- `references/price-ref-pipe-fittings-2026.md` — pipe fitting price references
- `scripts/document_generator.py` — Main document generation script (QTN, DO, INV), legacy Python fallback