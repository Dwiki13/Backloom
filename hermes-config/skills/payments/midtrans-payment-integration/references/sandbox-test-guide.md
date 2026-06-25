# Midtrans Sandbox Test Guide

## Sandbox Test Card (Success)
- Number: `4811 1111 1111 1111` (VISA)
- Expiry: `12/28` (must be future date in MM/YY format — `01/25` fails because 2025 is past)
- CVV: `123`

## Common Issues
- "Invalid expiry" error — date must be in the future, `01/25` fails (year 2025 past)
- "Make sure your card info is correct" — try `5810 1111 1111 1111` or `4411 1111 1111 1111` if `4811...` fails
- QRIS sandbox cannot be scanned with regular payment apps — use Credit Card for testing
- GoPay/ShopeePay redirect to QRIS in sandbox — avoid for testing
- BCA Virtual Account has no "Pay" button in sandbox — must settle from Midtrans Dashboard
- Ngrok session dies frequently — restart before webhook testing: `ngrok http 8002 > /tmp/ngrok.log 2>&1`
- **SQLAlchemy enum mismatch** — if `PaymentMethod` or `PaymentStatus` Python enum names don't match DB values (case-sensitive), all payment queries fail with `LookupError`. See vps-database-admin → references/sqlalchemy-enum-mismatch.md
- **`expires_at` NOT NULL** — `payments.expires_at` is NOT NULL in DB. Always set it when creating payment records manually (e.g. `datetime.utcnow() + timedelta(days=30)`)
- **Route files location** — SubTrack ID routes are in `app/routes/` (not `app/routers/` or `app/api/v1/endpoints/`). Payments route: `app/routes/payments.py`
- **Webhook silent success** — if signature doesn't match, webhook returns `200 {"message": "OK"}` without processing. Always verify with a valid SHA512 signature in tests. See midtrans-payment-integration → references/e2e-test-recipe.md

## Token Generation
```bash
cd /root/projects/subtrack-id/backend && python -c "
import sys; sys.path.insert(0, '.')
from app.config import settings; import midtransclient
snap = midtransclient.Snap(is_production=settings.MIDTRANS_IS_PRODUCTION, server_key=settings.MIDTRANS_SERVER_KEY)
result = snap.create_transaction({
    'transaction_details': {'order_id': 'test-order-xxx', 'gross_amount': 39000},
    'customer_details': {'email': 'test@test.com', 'first_name': 'Test'},
    'item_details': [{'id': 'pro-monthly', 'price': 39000, 'quantity': 1, 'name': 'SubTrack PRO'}],
})
token = result['token'] if isinstance(result, dict) else result
url = result.get('redirect_url', f'https://app.sandbox.midtrans.com/snap/vtweb/{token}')
print(f'URL: {url}')
"
```

## Webhook Setup
- Set in Midtrans Dashboard → Settings → Configuration → Payment Notification URL
- URL format: `https://<ngrok-or-domain>/api/v1/payments/webhook/midtrans`
- Signature verification skips when MIDTRANS_SERVER_KEY is empty (dev/test safety)

## Testing Preferences
- Credit Card preferred over QRIS for sandbox (QRIS cannot be scanned)
- Test manually in own browser — generate token via script, share URL
