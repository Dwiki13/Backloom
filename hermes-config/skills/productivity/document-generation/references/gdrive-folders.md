# Google Drive Folder IDs — Project 2026

Last verified: 2026-05-29

## Root
- **Project 2026:** `12SsvGGk-m6wDPlELcgEtByUsXrWGDYen`

## PT Folders

| PT Name | Folder ID |
|---------|-----------|
| PT Asian Bulk Logistics | `1hIL03kl-PK7LbMPLci_kDLWZaDzViEFb` |
| PT Bintang Indonesia Gede | `1GmWLP0UNAdQRxNt31-p08Ms37byM26LS` |
| PT Jelajah Samudera Bersama | `1Ynoc1I3jeRYLoW-GVgbI820PAhhZdfIZ` |
| PT Pasific Process Engineering | `1aqxoIhFa3Vw6p8sH8BkhzZUz4mnR59c6` |
| PT Pelayaran Jangkar Bahurekso Beribadat | `1wrXL2KmNDD0mKGpIM0qffCRyDGAn9JDH` |

## Subfolders (per PT)
Each PT folder contains:
- Quotation / PO / Invoice / Delivery Order

## Service Account
- Email: `hermes-drive-access@ai-agent-497609.iam.gserviceaccount.com`
- Credentials: `/root/.hermes/credentials/gdrive-service-account.json`

## Adding New PTs
When a new PT is added:
1. Get the folder ID from Drive
2. Add to the table above
3. Add to `pt_folders` in `/root/.hermes/data/document-tracker.json`
4. Create subfolders: Quotation, PO, Invoice, Delivery Order
