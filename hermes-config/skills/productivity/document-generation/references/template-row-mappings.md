# Template Row Mappings — PT Harmoni Artha Sentra

## Quotation HAS.xlsx (Verified May 29, 2026)

Template downloaded from GDrive folder `10Ix63pMDiIELx-4qaOu-T9UwR2TYgg_r`.

### Cell-by-cell Layout (all content rows)

| Row | Col | Content | Purpose |
|-----|-----|---------|---------|
| 6 | F:O | PT. HARMONI ARTHA SENTRA | Company name (merged) |
| 9 | F:O | General Supplier Marine, Oil & Gas... | Tagline (merged) |
| 11 | F:O | Jalan Sabilillah... | Address (merged) |
| 12 | F:O | Kec. Medansatria, Kota Bekasi... | City (merged) |
| 13 | F:O | No Telp : 0877-9178-6187/... | Phone (merged) |
| 14 | B:O | QUOTATION | Title (merged) |
| 16 | J:K | No Quotation : | Label (merged) |
| 16 | L:O | *(empty)* | **Value — write doc number HERE to L16** |
| 17 | J:K | Tanggal : | Label (merged) |
| 17 | L:O | *(empty)* | **Value — write date HERE to L17** |
| 18 | B | Kepada Yth : | Static label |
| 19 | B | *(empty)* | **Write client + "\nUp. Person" here** |
| 24 | B | No | Header |
| 24 | C:K | Description | Header (merged) |
| 24 | L | Qty | Header |
| 24 | M | Uom | Header |
| 24 | N | Harga Unit Price (Rp) | Header |
| 24 | O | Total | Header |
| 25 | B:O | *(placeholder "1", 0, 0)* | **Item data starts here** |
| 26 | L:N | Sub Total | Label (merged) |
| 26 | O | 0 | Value placeholder |
| 27 | L:N | Grand Total | Label (merged) |
| 27 | O | 0 | Value placeholder |
| 30 | B | Note : | Static |
| 31 | C:J | Cash Before Delivery | Note (merged) |
| 32 | C:J | Validity 1 Week | Note — **update with YAML validity** |
| 33 | C:J | Delivery After Full Payment | Note (merged) |
| 34 | C:J | Delivery Time 1-15 Days | Note — **update with YAML delivery** |
| 36 | C:J | Terms And Condition | Section (merged) |
| 37 | C:J | Not Warranty | T&C item |
| 38 | C:J | Items Cannot be returned once purchased | T&C item |
| 40 | N:O | Hormat Kami, | Sign-off label (merged) |
| 41 | B | Bank Account : | Static |
| 42 | B | No. Rekening : | Static |
| 42 | D | 006-00-5399988-8 (Mandiri) | Bank detail |
| 43 | B | Atas Nama : | Static |
| 43 | D | PT HARMONI ARTHA SENTRA | Bank detail |
| 48 | N:O | PT. Harmoni Artha Sentra | Sign-off signature (merged) |

### Dynamic Row Math (n = item count)

After RemoveRow(25) + InsertRows(25, n):

| Section | Row |
|---------|-----|
| Items | 25 to 25+n-1 |
| Sub Total | 25+n |
| Grand Total | 26+n |
| PPN | 27+n |
| Notes (Note:) | 29+n |
| Validity note | 31+n |
| Delivery note | 33+n |
| Bank | 41+n |

### Critical Pitfalls
- **Doc number goes to L16, NOT G16** — merged range L16:O16
- **Date goes to L17, NOT G17** — merged range L17:O17  
- **Client/Person share B19** — use newline separation, NOT separate rows
- **Sub Total value ≠ Grand Total value** — Sub=sum(items), Grand=sum+tax
- **Always RemoveRow(25) before InsertRows** — otherwise duplicates template rows

## Invoice HAS.xlsx

| Data | Cell |
|------|------|
| Invoice number | K16 |
| Date | K17 |
| PO number | K18 |
| Client | B21 |
| Person | B22 |
| Header | Row 26 |
| Items start | Row 27 |
| Bank | Shifts with item count |

## DO HAS.xlsx

| Data | Cell |
|------|------|
| DO number | K16 |
| PO number | K17 |
| Tanggal Kirim | K19 |
| Client | B22 |
| Items start | Row 28 |
