# Mobile-Backend Integration Checklist

## Pattern: After building backend endpoints, integrate mobile frontend

### Workflow
1. List ALL backend endpoints from `backend/app/routes/*.py` and `backend/app/main.py`
2. Check which endpoints are already in `mobile/lib/services/api_service.dart`
3. Identify gaps — endpoints that exist in backend but have no mobile function
4. Add missing functions to `ApiService` class
5. Create/update Riverpod providers to consume the API functions
6. Wire up screens to providers

## SubTrack ID Endpoint Map (as of June 2026)

### Auth (`/api/v1/auth`)
| Endpoint | Method | Mobile Function | Status |
|----------|--------|-----------------|--------|
| `/login` | POST | `login()` | ✅ Integrated |
| `/register` | POST | `register()` | ✅ Integrated |
| `/me` | GET | `getMe()` | ✅ Integrated |

### Subscriptions (`/api/v1/subscriptions`)
| Endpoint | Method | Mobile Function | Status |
|----------|--------|-----------------|--------|
| `/` | GET | `getSubscriptions()` | ✅ Integrated |
| `/` | POST | `createSubscription()` | ✅ Integrated |
| `/:id` | GET | — | ❌ Missing |
| `/:id` | PUT | `updateSubscription()` | ✅ Integrated |
| `/:id` | DELETE | `deleteSubscription()` | ✅ Integrated |
| `/stats/summary` | GET | `getStats()` | ✅ Integrated |

### Family (`/api/v1/family`)
| Endpoint | Method | Mobile Function | Status |
|----------|--------|-----------------|--------|
| `/` | POST | `createFamilyVault()` | ✅ Integrated |
| `/join/:code` | POST | `joinFamilyVault()` | ✅ Integrated |
| `/my-vaults` | GET | — | ❌ Missing |
| `/:id/members` | GET | — | ❌ Missing |

### Payments (`/api/v1/payments`)
| Endpoint | Method | Mobile Function | Status |
|----------|--------|-----------------|--------|
| `/create` | POST | `createPayment()` | ✅ Integrated |
| `/history` | GET | — | ❌ Missing |
| `/webhook/midtrans` | POST | N/A (backend-only) | — |

### Detector (`/api/v1/detect`)
| Endpoint | Method | Mobile Function | Status |
|----------|--------|-----------------|--------|
| `/` | POST | — | ❌ Missing (needs multipart upload) |

### Notifications (`/api/v1/notifications`)
| Endpoint | Method | Mobile Function | Status |
|----------|--------|-----------------|--------|
| `/register-token` | POST | — | ❌ Missing |
| `/send-test` | POST | — | ❌ Missing |
| `/settings` | GET | — | ❌ Missing |
| `/settings` | PUT | — | ❌ Missing |

### Priority for Mobile Integration
1. `getSubscription(id)` — subscription detail screen
2. `getMyVaults()` + `getVaultMembers(id)` — family screen
3. `getPaymentHistory()` — payment history screen
4. `uploadDetection(file)` — detector screen (multipart file upload)
5. `registerFcmToken()` + notification settings — settings screen

## Flutter Model Notes (June 2026)

### Family Models
- `mobile/lib/models/family.dart` — New model file for FamilyVault and FamilyMember
- Backend returns `id` as UUID string (converted via `field_validator`), mobile should parse as `String` not `Guid`
- `FamilyVaultResponse` fields: `id`, `name`, `invite_code`, `owner_id`, `created_at` (no `member_count` — removed from schema)
- `FamilyMemberResponse` fields: `id`, `vault_id`, `user_id`, `display_name`, `role`, `share_percentage`, `joined_at`
- Tier comparison: backend returns `"FAMILY"` (uppercase) — compare with `tier == 'FAMILY'` not `'family'`

### OCR Detector
- Endpoint: `POST /api/v1/detect` with multipart file upload
- Requires Pro tier (`UserTier.PRO` or `UserTier.FAMILY`)
- Use `MultipartFile.fromFileSync()` or `Dio FormData` for upload
- Response: `{ message, filename, size: int, detected: [{ name, category, price, currency, confidence, source_line }] }`
