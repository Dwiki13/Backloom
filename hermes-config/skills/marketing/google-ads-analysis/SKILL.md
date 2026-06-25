---
name: google-ads-analysis
description: Analyze Google Ads campaign performance from exported CSV data. Extract actionable insights on keywords, demographics, devices, time patterns, and budget optimization. Trigger when user shares Google Ads CSV exports (ZIP or individual files), asks for campaign analysis, ROI review, or optimization recommendations. Also trigger when the user wants business financial tracking (buku besar, GAP analysis, weekly reports) for their advertising-driven business.
---

# Google Ads Campaign Analysis + Business Financial Tracking

Analyze Google Ads performance data exported as CSV files, and optionally maintain business financial records (buku besar) for advertising-driven businesses.

## Workflow

### 1. Receive & Extract Data

User usually exports as ZIP from Google Ads → Reports → Download → CSV.

```bash
unzip -o "file.zip" -d /tmp/google_ads/
```

**⚠️ CSV Encoding:** Google Ads billing CSV exports are often **UTF-16 LE with BOM**. If `read_file` reports "Binary file", decode with:
```bash
python3 -c "
with open('file.csv', 'rb') as f:
    raw = f.read()
text = raw.decode('utf-16-le', errors='replace')
print(text)
"
```

Typical CSV files inside:
- `Time_series*.csv` — daily clicks, impressions, CPC, cost
- `Devices*.csv` — cost/clicks/impressions by device
- `Networks*.csv` — Google Search vs Search Partners
- `Demographics(Age*.csv` — age range impressions
- `Demographics(Gender*.csv` — gender split
- `Demographics(Gender_Age*.csv` — gender × age cross-tab
- `Day_&_hour*.csv` — day-of-week and hourly patterns
- `Search_keywords*.csv` — keyword, match type, status, cost, clicks, CTR
- `Searches(Search*.csv` — search terms with cost/clicks/conversions
- `Searches(Word*.csv` — word-level breakdown
- `Billing activity report.csv` — payment/spend/credit history (UTF-16 encoded)

### 2. Read & Analyze

Read ALL CSV files. Use Python for aggregation if needed.

Key metrics to compute:
- **Total spend, clicks, impressions, avg CPC, CTR**
- **Cost per day** — identify high/low days
- **Top keywords by cost** — which eat the most budget
- **CTR by keyword** — high CTR = relevant, low CTR = waste
- **Match type performance** — Broad vs Phrase vs Exact
- **Device split** — mobile vs desktop vs tablet
- **Network split** — Google Search vs Search Partners
- **Demographics** — age, gender, geo
- **Time patterns** — best days/hours
- **Conversions** — if tracking is set up
- **Payment flow** — deposits, running balance, VAT/fees (from billing CSVs)

### 3. Identify Problems

Common issues to flag:
- **Zero conversions** — conversion tracking not installed
- **High tracked conversions but zero actual leads/deals** — conversion tracking measures micro-events (button clicks), not real business outcomes. Always ask user for actual lead data.
- **Broad match bleeding budget** — irrelevant queries from broad match
- **No negative keywords** — informational queries wasting spend
- **High CPC keywords with low CTR** — poor relevance
- **Mobile-heavy traffic with zero conversions** — landing page issues
- **Keywords with "Removed" status** — still showing historical spend data
- **Search Partners underperforming** — low-quality traffic
- **Weekend CPC spikes** — bid adjustment needed for weekend days
- **Leads ghosting / 0% close rate** — follow-up system problem, not ad problem

### 4. Deliver Analysis Report

**⚠️ Telegram Formatting:** Telegram does NOT support markdown tables. Use bullet lists, emoji headers, and `key: value` pairs instead.

Structure the output:

```
📊 RINGKASAN — [Domain] (Date Range)

⏱️ TIME SERIES (Harian)
• Hari → Klik → Spend → CPC
• e.g. Sen 6 Jun → 9 klik → Rp 51.429 → Rp 5.714/klik

🔍 KEYWORD ANALYSIS
• keyword (match type, status): Rp X spend, X klik, X% CTR
• ⚠️ Removed keywords with historical spend

📱 DEVICES
• Mobile: Rp X, X klik
• Desktop: Rp X, X klik

🌐 NETWORKS
• Google Search: Rp X, X klik, Rp X CPC
• Search Partners: Rp X, X klik, Rp X CPC

👥 DEMOGRAPHICS
• Gender: Male X% / Female X%
• Top age: 25-34 (X%)

⏰ WAKTU TERBAIK
• Best day: Thursday (avg X klik)
• Best hour: 10:00-12:00

💳 PAYMENT FLOW (from billing CSVs)
• Total deposits: Rp X
• Total spend: Rp X
• VAT/fees: Rp X
• Remaining balance: Rp X

🎯 INSIGHT & REKOMENDASI

✅ YANG UDAH BAGUS
• Point 1
• Point 2

⚠️ MASALAH BESAR
• Problem 1
• Problem 2

🔧 REKOMENDASI ACTION
1. 🔴 High — Action → Expected impact
2. 🟡 Medium — Action → Expected impact
3. 🟢 Long-term — Action → Expected impact
```

**Style preferences (Indonesian market):**
- Indonesian/English mix (casual, direct)
- Format IDR with thousand separators: `Rp 656.580` not `656580`
- Use emoji headers for scanability
- Keep it actionable — always end with what to DO
- Concise over verbose — no fluff
- No markdown tables (Telegram doesn't support them)

### 5. Provide Actionable Steps

Always give COMPLETE, specific steps — not vague instructions. Include:
- Exact menu paths in Google Ads UI
- Exact text to paste (e.g., negative keywords list)
- Code snippets if relevant (e.g., conversion tracking tags)
- Priority order (what to do first)

## Key Indonesian Market Notes

- Budget often in IDR — format as Rp with thousand separators
- Common negative keywords for service businesses: `gratis`, `tutorial`, `cara bikin`, `cara membuat`, `free`, `diy`, `sendiri`
- High-intent keywords often include: `jasa`, `profesional`, `pembuatan`, `buat`
- Informational queries to exclude: `cara`, `tutorial`, `gratis`, `membuat sendiri`
- WhatsApp is primary conversion channel for Indonesian service businesses

## Conversion Tracking Setup (When Missing)

If conversions = 0 across all data, guide user through:

1. **Google Ads** → Tools & Settings → Measurements → Conversions → New conversion action
2. **Google Tag Manager** → New Tag → Google Ads Conversion Tracking
3. **Website** → Install GTM container code + conversion event triggers (button clicks, form submits)

For Next.js sites: add GTM script to `_app.tsx` or `_document.tsx`.
For WordPress: use Google Site Kit plugin.
For static HTML sites: add GTM script in `<head>` and event listeners on buttons/forms.

### Static HTML Sites (No Framework)

When the site is plain HTML/JS (not Next.js/React), conversion tracking is simpler:

1. Add GTM container snippet in `<head>` (before `</head>`)
2. Add `gtag('event', 'conversion', ...)` on button click / form submit
3. If GA4 is already loaded via `gtag('config', 'G-XXXXX')`, just add event listeners on key CTAs
4. Common CTA triggers: WhatsApp button click, contact form submit, phone number click

### When User Says "You Do It" (Akses ke VPS)

If the user wants you to directly modify the website on their VPS:
- Find the site root: `find /var/www -maxdepth 2 -name "index.html"`
- Check existing tags: `grep -n "gtag\|google\|GA4\|AW-\|googletagmanager" /var/www/domain/html/index.html`
- Check JS files for existing event tracking: `grep -n "gtag\|generate_lead\|conversion" /var/www/domain/html/main.js`
- Edit files directly on VPS, then reload nginx: `sudo systemctl reload nginx`
- Always backup before editing: `cp index.html index.html.bak.$(date +%s)`

### Getting Conversion ID from Google Ads

To get the Conversion ID (`AW-XXXXXXXXX`) and Conversion Label:
1. Google Ads → Tools & Settings → Measurements → Conversions → + New conversion action
2. Website → Category: Submit lead form → Create and continue
3. "Install the tag yourself" → copy Conversion ID and Label
4. User must do this themselves — agent cannot create conversion actions on their behalf

## Setting Conversion Values

Newly created conversions often have default values of 1.00 or 7.00 — these are NOT real values. Always check and update:

1. Google Ads → Tools & Settings → Measurements → Conversions
2. Click the conversion name → Edit → set **Value** to realistic amount
3. For service businesses: set lead form = lowest package price (e.g., 1,500,000), outbound click = estimated lead value (e.g., 500,000)

**Note:** If the "Value" field is not visible in the UI, the account may use a different version. Try clicking the conversion name to see its detail page, or check if there's a "Settings" tab within the conversion action.

Also check **Conversion Window** — default is often 90 days. For service businesses, 30 days is more realistic to avoid double-counting.

## Setting Up Negative Keywords

Always provide the COMPLETE list ready to paste. Common Indonesian service business negatives:

```
gratis, tutorial, cara bikin, cara membuat, free, diy, sendiri,
000webhost, jimdo, carrd, netlify, wix, sites google,
template gratis, how to, membuat website gratis, cara bikin website gratis
```

Apply at campaign level: Tools & Settings → Bulk Actions → Add negative keywords.

## Pausing Broad Match Keywords

Broad match bleeds budget on irrelevant queries. Always recommend pausing:
1. Keywords tab → filter by Broad match → select all → Edit → Pause
2. Keep Phrase match and Exact match only

## Pitfalls

### Google Ads UI Varies by Account Type

Menu paths differ across Google Ads account versions. "Conversions" might be under "Measurements", "Tools & Settings", or accessible only via direct URL.

**Fix:** If user can't find a menu, provide the direct URL:
- Conversions: `https://ads.google.com/aw/conversions`
- Also try: `https://ads.google.com/aw/measurement`

Ask user to screenshot their Tools & Settings page if documented paths don't match.

### Conversion Value = Default (1.00 / 7.00)

Newly created conversions show values like 1.00 or 7.00 — these are Google defaults, not real business values. ROAS and CPA optimization will be meaningless until corrected.

**Fix:** Always check conversion values in the data. If suspiciously small (1, 7, 0), guide user to set realistic values based on their service pricing.

### User Can't Find "Conversion" Menu

Some Google Ads accounts don't show "Conversion" under Tools & Settings at all. This happens with newer account types or accounts that haven't completed initial setup.

**Fix:** User must first create a conversion action: Tools & Settings → Measurements → Conversions → + New conversion action. If "Measurements" doesn't exist, the account may need to complete the initial setup wizard first.

### ⚠️ Always Confirm CPC Max Setting

Before doing any cost projection or scaling analysis, **always confirm the user's CPC max setting**. Do NOT assume Rp 7,000 or any other default. For DevLokal ID, CPC max = **Rp 5,000**. Using wrong CPC will invalidate all downstream projections (cost, ROI, break-even, scaling roadmap).

### ⚠️ Agent Cannot Send WhatsApp Messages Directly

The agent does NOT have WhatsApp sending capability unless the WhatsApp bridge (Baileys) is explicitly enabled. When the user asks "bantu kirim via WA":

1. **Do NOT claim you can send WA messages** unless you have verified the WA bridge is active
2. **Provide the message template** and let the user send it manually
3. **Clarify upfront**: "Aku nggak bisa kirim WA langsung, tapi aku bisa bikin template-nya"

**Common mistake:** Agent says "bisa, nanti aku kirim" → user provides the number → agent can't deliver → user is frustrated.

### ⚠️ User Prefers Step-by-Step Instructions (Not Direct Edits)

When the user asks for help with code changes (conversion tracking, landing page edits, etc.):
- **Provide complete step-by-step instructions** with exact code snippets
- **Do NOT directly edit files on the VPS** unless user explicitly says "tolong edit langsung"
- User's typical response: "kasih langkah aja, nanti gua yang edit manual di code nya"
- This is a **workflow preference** — user wants to learn and maintain control

### ⚠️ Don't Over-Audit Landing Pages Without Verifying

When auditing a landing page based on `web_extract` or `browser_snapshot` alone, you may misread the page. Common mistakes:

- **Testimoni section**: May show initials + "VERIFIED CLIENT" labels which look empty in text snapshot but actually have images/rendered content. **Always check if the section has visual elements before flagging as "empty".**
- **Price visibility**: User may say "harga memang di bawah" (price is intentionally below fold). Don't flag this as a problem without understanding the design intent.
- **CTA copywriting**: Don't recommend changing CTA text unless you have data showing the current one underperforms.
- **Social proof numbers**: If user says "memang projectnya baru kisaran segitu", don't inflate or flag as weak. Honesty > fake social proof.

**Rule: When user pushes back on an audit finding, accept the correction gracefully. Don't defend a wrong call.**

### ⚠️ Follow-Up System: The Real Bottleneck for Indonesian Service Businesses

For Indonesian service businesses (web dev, design, etc.), the #1 reason for 0% close rate is NOT the ads — it's the **follow-up process**. Common patterns:

**Typical funnel breakdown:**
- 179 clicks → 5 actual leads → 0 close
- The 5 leads: 2 ghosted, 1 said no, 2 "still considering"

**Root causes of lead ghosting:**
1. **Slow WA response** — Target: **< 5 minutes**
2. **No auto-reply** — Lead sends message at night, no response until morning = lost lead
3. **No follow-up sequence** — One message, then silence. Need systematic follow-up (Day 1, 2, 3, 7)
4. **No CRM/tracking** — Leads fall through the cracks

**When to recommend follow-up fixes (before ad optimization):**
- User reports leads but 0 close rate
- Conv rate looks good on paper but no revenue
- Leads say "still considering" or ghost after initial contact

### ⚠️ Tracked Conversions ≠ Actual Business Outcomes (CRITICAL)

Google Ads "conversions" are **event-based** (button clicks, form submits), NOT actual qualified leads or closed deals.

**Real-world example (DevLokal ID, June 2026):**
- Google Ads reported: **36 conversions**, 20.11% conv rate, Rp 33.938/conv
- Actual leads: **5 people**
- Actual closed deals: **0**
- The "36 conversions" were mostly WA button clicks — people who clicked but never sent a message

**How to detect this trap:**
1. **Always ask the user for actual lead/deal data** — don't rely solely on Google Ads conversion numbers
2. **Compare reported conversions vs actual leads** — if Google says 36 conv but user only got 5 leads, the tracking is measuring micro-events
3. **Build a full funnel table**: Clicks → WA Clicks → Actual Messages → Qualified Leads → Closed Deals
4. **Calculate REAL conv rate** = actual leads / clicks

### 🔧 Improving Conversion Tracking Accuracy: Scroll-Depth Gating

When the user wants more accurate conversion tracking, recommend **scroll-depth gating**:

**Concept:** Only fire Google Ads conversion when user has scrolled past a threshold (e.g., 40% = seen pricing section) AND clicked WA.

**Implementation:** Use the template at `templates/scroll-depth-gating.js`

**Expected impact:**
- Conversion count turun (dari 36 → 15-20)
- TAPI conversion quality naik
- Cost per conversion lebih realistic

### ⚠️ Google Ads Budget & Learning Phase

**Pause & Restart = Learning Phase Reset (1-2 minggu)**
- CPC naik 10-30% selama learning
- Performance nggak stabil
- Lebih baik turunkan budget daripada pause total

**Jangan Daily Budget = Target CPA**
- Kalau daily budget = target CPA → max 1 conv/hari
- Google butuh minimal 5-10 conv/minggu untuk belajar
- Lebih baik: topup 100k, daily budget 25k (tahan 4 hari)

**Fokus Conversion Dulu, Conversion Value Nanti**
- Budget terbatas → fokus ke conversion, bukan conversion value
- Set conversion value = harga paket terendah
- Evaluasi setelah 10+ conversions

### 📱 Follow-Up Message Templates for Leads

When the user asks for help creating follow-up messages, use the templates in `references/follow-up-system.md`. Key principles:
- **Soft follow-up** — Don't be pushy
- **Provide value first** — Share portfolio before asking for commitment
- **2-3 options** — Give leads a choice rather than yes/no
- **Follow-up sequence** — Day 1 (soft), Day 2 (value), Day 3 (urgency), Day 7 (final)

### CSV Encoding: UTF-16 LE

When the user asks for help with code changes (conversion tracking, landing page edits, etc.):
- **Provide complete step-by-step instructions** with exact code snippets
- **Do NOT directly edit files on the VPS** unless user explicitly says "tolong edit langsung" or "aku kasih akses, tolong ubah"
- User's typical response: "kasih langkah aja, nanti gua yang edit manual di code nya"
- This is a **workflow preference**, not a limitation — user wants to learn and maintain control

### Alternative Acquisition: Direct WA Outreach

When Google Ads isn't converting yet, suggest **direct WhatsApp outreach** to UMKM as a parallel acquisition channel:

**Approach:**
- Target UMKM in specific areas (e.g., Jabodetabek) that lack websites or have poor ones
- Use soft, personalized pitch — mention their business by name, ask before pitching
- Script template:
  ```
  Halo [Nama], perkenalkan Dwiki dari DevLokal.
  Saya lihat bisnis [Nama Bisnis] di [sumber — GoogleMaps/IG].
  Mau tanya — saat ini sudah punya website untuk bisnisnya?
  Kalau belum, kami bikin website mulai 1.5jt,
  bisa dibantu buatkan. Ga ada paksaan,
  kalau tertarik bisa saya kirim contoh portfolio.
  ```

**⚠️ Google Maps Scraping Warning:**
- Google Maps scraping is **unreliable** (bot detection, limited results without login, ToS violation)
- Headless browser scraping often fails or gets blocked, even with Playwright/Selenium
- Google Places API requires enabling the API in GCP console (existing API keys may not have access)
- **Better alternatives for building target list:**
  - Manual search on Google Maps (1-2 hours for 100 targets — most reliable)
  - Buy UMKM database (Rp 50-200K per 1000 data on Tokopedia/Google)
  - Scrape Instagram (UMKM often have WA in bio, more accessible via hashtag search)
  - Google Ads lead form extension (most scalable long-term)

**Outreach volume guidance:**\n- Manual personalized: 10-20 messages/day\n- Cold pitch response rate: ~5-10%\n- Closing rate: ~2-3% of respondents\n- **This is NOT scalable** — use as stopgap while optimizing Google Ads funnel\n\n### ⚠️ Agent Cannot Send WhatsApp Messages Directly\n\nThe agent does NOT have WhatsApp sending capability. The WhatsApp bridge (Baileys) is not enabled by default. When the user asks \"bantu kirim via WA\":\n\n1. **Do NOT claim you can send WA messages** unless you have verified the WA bridge is active (`grep -i whatsapp /root/.hermes/config.yaml` and check if it's enabled)\n2. **Provide the message template** and let the user send it manually\n3. **If user wants automated WA sending**, guide them through enabling the WhatsApp bridge or using WA Business API\n\n**Common mistake:** Agent says \"bisa, nanti aku kirim\" → user provides the number → agent can't deliver → user is frustrated. Always clarify upfront.\n\n### 📱 Follow-Up Message Templates for Leads\n\nWhen the user asks for help creating follow-up messages for leads (e.g., warm leads who ghosted), use the templates in `references/follow-up-system.md` as a starting point. Key principles:\n\n- **Soft follow-up** — Don't be pushy. Give space.\n- **Provide value first** — Share portfolio, case study, or useful info before asking for commitment.\n- **2-3 options** — Give leads a choice (Starter/Standard/Professional) rather than yes/no.\n- **Follow-up sequence** — Day 1 (soft), Day 2 (value), Day 3 (urgency), Day 7 (final).\n- **Personalize** — Use lead's name, mention their business specifically.\n\nSee `references/follow-up-system.md` for complete templates and sequences.\n\n### CSV Encoding: UTF-16 LE

Google Ads billing/activity CSV exports are often encoded as **UTF-16 LE with BOM**, not UTF-8. The `read_file` tool will report "Binary file" for these.

**Fix:** Decode via terminal:
```bash
python3 -c "
with open('file.csv', 'rb') as f:
    raw = f.read()
text = raw.decode('utf-16-le', errors='replace')
print(text)
"
```

### Weekly Recurring Reports via Cron

When the user wants weekly automated reports:
1. Create a cron job with `schedule: "0 10 * * 0"` (Sunday 10:00 WIB)
2. Use `deliver: "local"` + `send_message` in the prompt for clean Telegram delivery
3. Load the `google-ads-analysis` skill via `skills: ["google-ads-analysis"]`
4. The prompt should instruct the LLM to: find latest CSVs → analyze → save report → send to Telegram
5. Save reports to a consistent path: `/root/projects/<business>/reports/google-ads-weekly-YYYY-MM-DD.md`

## Business Financial Tracking (Accountant Role)

When the user assigns an "accountant" or "bookkeeper" role for their business:

### Buku Besar (Ledger) Maintenance
- Create/maintain a monthly buku besar at `/root/projects/<business>/reports/buku-besar-YYYY-MM.md`
- Use the template at `templates/buku-besar-template.md`
- Update whenever the user reports income or expenses in natural language:
  - "Bayar VPS Rp 350rb" → add to pengeluaran
  - "Dapet project landing page dibayar Rp 1.5jt" → add to pemasukan
- Track: Saldo Awal, Pengeluaran (Ads, PPN, VPS, etc.), Pemasukan, GAP analysis

### Weekly Report via Cron
- Set up cron job: `schedule: "0 10 * * 0"` (Sunday 10:00 WIB)
- `deliver: "local"` + `send_message` in prompt for clean Telegram delivery
- Report covers: ad spend summary, cash flow, GAP, actionable recommendations
- Save to `/root/projects/<business>/reports/google-ads-weekly-YYYY-MM-DD.md`

### Indonesian Service Business Pricing Benchmarks
- Landing page: Rp 1.000.000 - 2.500.000
- Company profile: Rp 1.500.000 - 3.000.000
- Toko online: Rp 2.000.000 - 5.000.000
- Custom web app: Rp 3.000.000+
- Use these as reference when setting conversion values in Google Ads

## Telegram Delivery Target

**DevLokal ID analysis reports → Topic Sales Marketing (1264)**
- Chat ID: `-1003966561389`
- Thread ID: `1264`
- Target: `telegram:-1003966561389:1264`
- **JANGAN kirim ke Topic Trading (334)** — itu untuk XAUUSD signals
- **JANGAN kirim ke Topic Notifikasi (5)** — itu untuk todo reminders
- On-demand analysis (KII share CSV): kirim langsung ke Topic 1264 via `send_message` atau `hermes send`

## References

- `references/indonesian-market-keywords.md` — Common keyword patterns and negative keyword lists for Indonesian service businesses
- `references/vps-static-site-patterns.md` — Patterns for analyzing and modifying static HTML sites on VPS (Nginx deployments)
- `references/case-study-devlokal-id.md` — Full case study: DevLokal ID Google Ads analysis, billing data, business financial tracking setup, and lessons learned
- `references/scaling-analysis-template.py` — Reusable Python script for scaling analysis (break-even, CPC sensitivity, phased roadmap)
- `templates/buku-besar-template.md` — Buku besar (ledger) template for tracking operational expenses, income, and GAP analysis
- `templates/scroll-depth-gating.js` — Scroll-depth gated WA conversion tracking code (improves conversion quality by only counting clicks from users who scrolled past pricing)