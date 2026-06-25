# API-Frontend Alignment Patterns

## When Backend Endpoints Must Match Frontend Models

In SubTrack ID, the Flutter frontend expects specific JSON structures from backend APIs. When they don't match, you get silent failures or runtime errors in the app.

## Common Misalignments

### 1. Missing Fields
Backend returns: `{id, name, price}`
Frontend expects: `{id, name, price, currency, billing_cycle, description, ...}`

### 2. Wrong Field Names
Backend: `"billing_cycle": "monthly"`
Frontend expects: `"billingCycle": "monthly"` (camelCase)

### 3. Wrong Data Types
Backend: `datetime` objects
Frontend expects: ISO string `"2026-06-15T10:30:00Z"`

### 4. Missing Computed Properties
Frontend models often have computed properties like `monthly_cost`, `formattedPrice` that must be provided by backend.

## Solution Pattern: Serialization Helper

Create a dedicated serialization function that:
1. Maps all ORM model fields to frontend-expected names
2. Converts data types appropriately (datetime → ISO string, enums → .value)
3. Adds computed properties using the same logic as frontend
4. Handles null/empty values correctly

```python
def _serialize_subscription(sub):
    # Mapping dictionaries for computed values
    monthly_multipliers = {
        BillingCycle.WEEKLY: 4.33,
        BillingCycle.MONTHLY: 1,
        BillingCycle.QUARTERLY: 1/3,
        BillingCycle.YEARLY: 1/12,
    }
    
    yearly_multipliers = {
        BillingCycle.WEEKLY: 52,
        BillingCycle.MONTHLY: 12,
        BillingCycle.QUARTERLY: 4,
        BillingCycle.YEARLY: 1,
    }
    
    monthly_cost = sub.price * monthly_multipliers[sub.billing_cycle]
    yearly_cost = sub.price * yearly_multipliers[sub.billing_cycle]
    has_price_increased = bool(sub.previous_price and sub.previous_price < sub.price)
    
    return {
        # Basic fields
        "id": str(sub.id),
        "name": sub.name,
        "description": sub.description,
        "price": sub.price,
        "currency": sub.currency,
        
        # Enums with proper casing
        "billing_cycle": sub.billing_cycle.value if sub.billing_cycle else None,
        "category": sub.category.value if sub.category else None,
        
        # Datetime conversion
        "next_billing_date": sub.next_billing_date.isoformat() if sub.next_billing_date else None,
        "is_trial": sub.is_trial,
        "trial_ends_at": sub.trial_ends_at.isoformat() if sub.trial_ends_at else None,
        
        # Price history
        "previous_price": sub.previous_price,
        
        # URLs
        "icon_url": sub.icon_url,
        "website_url": sub.website_url,
        
        # Status flags
        "is_active": sub.is_active,
        "notify_days_before": sub.notify_days_before,
        
        # Computed properties (match frontend logic exactly)
        "monthly_cost": monthly_cost,
        "yearly_cost": yearly_cost,
        "has_price_increased": has_price_increased,
        
        # Timestamps
        "created_at": sub.created_at.isoformat() if sub.created_at else None,
        "updated_at": sub.updated_at.isoformat() if sub.updated_at else None,
        
        # Relationship fields
        "vault_id": str(sub.vault_id) if sub.vault_id else None,
    }
```

## Usage in Endpoints

```python
@router.get("/{vault_id}/subscriptions")
async def list_vault_subscriptions(...):
    subscriptions = db.query(Subscription).filter(...).all()
    return [_serialize_subscription(s) for s in subscriptions]

@router.get("/{vault_id}/subscriptions/{sub_id}")
async def get_vault_subscription(...):
    subscription = db.query(Subscription).filter(...).first()
    return _serialize_subscription(subscription)
```

## Verification Steps

1. **Manual test**: Call endpoint directly and inspect JSON
   ```bash
   curl -H "Authorization: Bearer <token>" http://localhost:8002/api/v1/factory/{vault_id}/subscriptions
   ```

2. **Frontend test**: Verify the Flutter app renders data correctly without errors

3. **Automated test**: Add test cases that validate the exact JSON structure returned

## When to Apply This Pattern

- Any endpoint that returns model data to Flutter frontend
- When creating new API endpoints
- When modifying existing endpoints that power UI screens
- Before releasing to production (catch mismatches early)

## Related Files in This Project
- `backend/app/routes/family.py` - `_serialize_subscription` helper
- `mobile/lib/models/subscription.dart` - Frontend Subscription model
- `mobile/lib/services/api_service.dart` - API call layer