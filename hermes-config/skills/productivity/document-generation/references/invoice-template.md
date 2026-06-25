# Invoice Template Layout (XLSX)

Based on: Invoice HAS.xlsx (template from Drive)

## Header (rows 1-13, col F)
Same as Quotation template.

## Title (row 14)
- **INVOICE** centered, bold

## Metadata (rows 16-20, col J/K)
- No Invoice, Tanggal, No Quotation, No PO, No DO

## Client Info (rows 22-24, col B)
- "Kepada Yth :" / Company / "Up. [person]"

## Table (row 28+)
Headers: No (B) | Description (C) | Qty (L) | Uom (M) | Harga Unit Price (N) | Total (O)
Data starts row 29.

## Footer
- Sub Total (L+O)
- Grand Total (L+O, bold)
- Terbilang: "[amount in words] Rupiah"
- Bank: Mandiri 006-00-5399988-8 a/n PT HARMONI ARTHA SENTRA
- Sign-off: "Hormat Kami," + company name

## Notes
- References QTN, PO, AND DO numbers
- Includes pricing (unlike DO)
- Format: INV/HAS/YYYY/MM/XXX
- Terbilang auto-generated from Grand Total
