# Tier & Pricing Revision Strategy

## Framework for Evaluating Free/Paid Tiers

When a user asks "is the free tier too limited?" or "should we revise pricing", use this analysis:

### 1. Check if Free Tier is "Complete" for Basic Use
A free tier should let a user do the **core job** without paying. For example:
- **Gdrive Storage core job:** "Connect drives → browse files → upload → download → delete"
- If the free tier can do ALL of that, it's good. If it can't (e.g., can't search or sort), it feels broken.

### 2. Identify the "Upgrade Trigger"
Users pay when they hit a **natural wall**:
- **Capacity limits:** more drives, more storage
- **Historical data:** usage charts, activity history
- **Power features:** API access, versioning, audit logs

### 3. Tier Design Principles
| Principle | Bad | Good |
|-----------|-----|------|
| Free = functional | Lock search/filter/sort behind paywall | Give basic CRUD + search + sort free |
| Upgrade = more capacity | Same features, just raise limits | Unlock new data categories (history, audit) |
| Price anchoring | Free only, no tiers | 3 tiers with clear value curve |

### 4. Common Pattern (SaaS Indonesia)
- Free: 1-2 drives, basic features, no history
- Low (Rp 19-29rb): full features, more capacity, some history
- High (Rp 49-79rb): power features (API, audit, versioning)

### 5. Response Template
When asked "feature free terlalu dikit?", respond with:
1. Acknowledgment of current limitation
2. Analysis of what makes a tier "feel abandoned"
3. Concrete recommendation with feature matrix
4. Code changes needed if approved
