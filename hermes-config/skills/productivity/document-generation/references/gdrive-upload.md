# Google Drive Upload via Service Account

## Credentials

- Service Account JSON: `/root/.hermes/credentials/gdrive-service-account.json`
- Email: `hermes-drive-access@ai-agent-497609.iam.gserviceaccount.com`
- Scopes: `https://www.googleapis.com/auth/drive`

## Setup Requirements

1. Service Account created in Google Cloud Console
2. JSON key downloaded and saved to credentials path
3. Target Google Drive folder shared with Service Account email as **Editor**

## Upload Code Pattern

```python
import re
from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload

def upload_to_drive(local_path, filename, parent_folder_id):
    creds = service_account.Credentials.from_service_account_file(
        '/root/.hermes/credentials/gdrive-service-account.json',
        scopes=['https://www.googleapis.com/auth/drive']
    )
    service = build('drive', 'v3', credentials=creds)
    file_metadata = {'name': filename, 'parents': [parent_folder_id]}
    media = MediaFileUpload(local_path, mimetype='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
    file = service.files().create(body=file_metadata, media_body=media, fields='id, webViewLink').execute()
    print(f"Uploaded: {filename} -> {file['webViewLink']}")
    return file
```

## Project 2026 Folder IDs (as of 2026-05-29)

Root (Project 2026): 12SsvGGk-m6wDPlELcgEtByUsXrWGDYen
- PT Asian Bulk Logistics: 1hIL03kl-PK7LbMPLci_kDLWZaDzViEFb
- PT Bintang Indonesia Gede: 1GmWLP0UNAdQRxNt31-p08Ms37byM26LS
- PT Jelajah Samudera Bersama: 1Ynoc1I3jeRYLoW-GVgbI820PAhhZdfIZ
- PT Pasific Process Engineering: 1aqxoIhFa3Vw6p8sH8BkhzZUz4mnR59c6
- PT Pelayaran Jangkar Bahurekso Beribadat: 1wrXL2KmNDD0mKGpIM0qffCRyDGAn9JDH

Each PT folder has: Quotation, PO, Invoice, Delivery Order subfolders.

## File Naming

- Excel: [PT Name]_QTN.HAS.YYYY.MM.XXX.xlsx
- PDF: same with .pdf extension
- Sanitize slashes to underscores for local filesystem paths

## Notes

- Service Account works without browser (fully automated)
- Must share target folders with SA email as Editor
- Rate limit: ~1000 requests/100 seconds
