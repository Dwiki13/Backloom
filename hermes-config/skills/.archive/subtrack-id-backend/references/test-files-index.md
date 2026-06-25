# Test Files Index — SubTrack ID Backend

## Test Files (109 tests total as of June 15 2026)

### API Endpoint Tests

| File | Tests | What It Covers |
|------|-------|----------------|
| `tests/test_endpoints.py` | ~40 | Auth, subscriptions, family vault CRUD, payments (create/history/webhook), detector, notifications — auth/no-auth happy paths |
| `tests/api/v1/endpoints/test_payment_proofs.py` | 10 | Payment proof upload/get/delete, mark-paid with proof, proof overwrite, file validation |
| `tests/api/v1/endpoints/test_notifications.py` | ~7 | FCM token register, send-test, settings, list, mark-read, mark-all-read |
| `tests/api/v1/endpoints/test_family_payments.py` | 15 | **NEW June 15** — Payment history pagination, reject endpoint, member-scoped payment viewing, payment summary with total_awaiting |

### Celery Task Tests

| File | Tests | What It Covers |
|------|-------|----------------|
| `tests/tasks/test_billing.py` | 6 | generate_family_payments, check_overdue_payments |
| `tests/tasks/test_auto_confirm.py` | 7 | **NEW June 15** — auto_confirm_awaiting_payments: 24h auto-confirm, 6h reminder, dual-threshold, no-FCM-token edge case |

### Model Tests

| File | Tests | What It Covers |
|------|-------|----------------|
| `tests/models/test_user.py` | ~4 | User model, tier enum |
| `tests/models/test_subscription.py` | ~5 | Subscription model, billing cycle |
| `tests/models/test_payment.py` | ~5 | Payment model, Midtrans fields |
| `tests/models/test_family.py` | ~10 | FamilyVault, FamilyMember, FamilyPayment models |

## Creating New Test Files

### For new API endpoints:
Create `tests/api/v1/endpoints/test_<feature>.py` with:
- SQLite test DB (`sqlite:///./test_<feature>.db`)
- `engine`, `TestingSessionLocal`, `override_get_db()`
- `app.dependency_overrides[get_db]` and `app.dependency_overrides[get_current_user]`
- Helper functions: `create_user()`, `create_vault()`, `create_subscription()`, `create_family_payment()`, `add_vault_member()`
- `set_auth_user()` / `clear_auth()` in try/finally blocks
- `engine.dispose()` in fixture teardown

### For new Celery tasks:
Create `tests/tasks/test_<task_name>.py` with:
- Patch `get_session` and external services (FCM, notifications)
- `MagicMock()` for DB query chains
- Test happy path + edge cases (empty results, wrong status, missing FCM token)

### Dual-Threshold Pitfall:
When a task has multiple time thresholds (e.g. 6h + 24h), a payment older than BOTH triggers BOTH actions. Use `call_count` and `call_args_list` instead of `assert_called_once()`:
```python
assert mock_fcm.call_count == 2
member_call = [c for c in mock_fcm.call_args_list if c.kwargs.get('token') == "member_fcm_token"]
assert len(member_call) == 1
```
