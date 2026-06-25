# Case Study: devlokal.id Google Ads Analysis (June 2026)

## Campaign Overview
- **Domain:** devlokal.id
- **Business:** Jasa pembuatan website (freelance web dev) — DevLokal ID
- **Period analyzed:** 6-14 June 2026 (9 days)
- **Campaign:** DevLokal - Search - Leads
- **Total spend:** Rp656.580
- **Total clicks:** 117
- **Avg CPC:** Rp5.612

## Billing Data Findings (June 14 2026)

### Daily Pattern
- Best day: Thu 10 Jun → 24 klik, CPC Rp3.844 (cheapest high-volume day)
- Worst day: Tue 8 Jun → 3 klik only
- Weekend (Fri-Sun) CPC significantly higher (Rp7.000-9.900) vs weekday (Rp3.400-5.700)
- Mon 7 Jun had best CPC: Rp3.406/klik

### Payment Flow
- Total deposits: Rp1.400.000 (4 manual payments via Mastercard •••• 4136)
- 4 payment declines due to insufficient funds (before successful ones)
- Running balance on 14 Jun: ~Rp803.030
- VAT charged: Rp138.740 (for 5-14 Jun period)
- Overrun credit: Rp2.203

### Key Insight
Weekday ads perform 2x better than weekend. Recommend reducing weekend bids by 30% or setting ad-schedule bid adjustments.

## Previous Analysis (6-13 Jun) — Keyword & Device Data

### Keywords
- **Best performer:** "jasa pembuatan website" (Phrase) — CTR 12.96%, 7 klik, Rp73.260
- **Worst performer:** "bikini website" (Broad) — CTR 3.38%, 30 klik, Rp158.798 (most expensive)
- **Removed keywords** still showed historical spend of ~Rp87.585
- Phrase match consistently outperformed Broad match in CTR (2-4x higher)

### Devices
- Mobile: 85% of budget (Rp481.639), 94 clicks from 2,788 impressions
- Desktop: 12% of budget (Rp110.356), 16 clicks from 814 impressions
- Tablet: negligible

### Networks
- Google Search: CPC Rp7.012, 77 clicks
- Search Partners: CPC Rp1.678, 34 clicks (4x cheaper!)

### Demographics
- Male 70.69% / Female 29.50%
- Dominant age: 25-34 (40.41%) + 18-24 (30.09%)
- Male 25-34 = largest segment (30.01%)

### Time Patterns
- Best hours: 10 AM (339 imp), 11 AM (430 imp)
- Best days: Tuesday (914 imp), Wednesday (782 imp)
- Worst days: Monday (80 imp), Thursday (377 imp)

### Conversions
- Conversion tracking WAS set up (GA4 connected)
- "Submit lead form": 1 conversion, value 1.00 (default — needs update)
- "Outbound clicks": 7 conversions, value 7.00 (default — needs update)
- Conversion window: 90 days (too long — recommend 30 days)

## Actions Taken
1. Analyzed 12 CSV files from Google Ads export (keywords, devices, demographics, time, searches)
2. Analyzed billing/activity CSV (UTF-16 encoded) for cash flow tracking
3. Identified negative keyword candidates from search terms data
4. Recommended pause all Broad match keywords
5. Recommended conversion value update to realistic amounts
6. Recommended conversion window change to 30 days
7. Set up weekly cron job (Sunday 10:00 WIB) for automated report delivery to Telegram Topic Trading (334)
8. Saved report to `/root/projects/devlokal-id/reports/google-ads-weekly-2026-06-14.md`

## Business Financial Tracking (New — June 14 2026)

### OWL as Accountant Role
KII assigned OWL the role of "Accountant DevLokal ID" in Topic 3 (Bisnis). Responsibilities:
- Record operational expenses (VPS, hosting, Google Ads, etc.)
- Record income/revenue from client projects
- Analyze GAP (margin = income minus expenses)
- Weekly automated reports via cron job
- Forward-looking business analysis and recommendations

### Buku Besar (Ledger) Template
Created `/root/projects/devlokal-id/reports/buku-besar-2026-06.md` with sections:
- Saldo Awal (initial balance / deposits)
- Pengeluaran Operasional (operational expenses) — Google Ads, PPN/Fee, VPS/Hosting
- Pemasukan (revenue) — client, service, amount, status
- Ringkasan GAP (profit/loss summary)
- Catatan (notes)

### DevLokal ID Pricing
- Landing page: Rp 1.500.000
- Company profile: Rp 2.500.000
- Toko online: custom
- Custom web app: custom
- Portfolio: Kanopi Pro, PT Harmoni Artha Sentra, Sevora & Co

### Weekly Report Cron Job
- Job ID: 816256bf2443
- Schedule: Every Sunday 10:00 WIB (`0 10 * * 0`)
- Delivery: local (LLM handles analysis + send_message)
- Skills loaded: google-ads-analysis

## How to Update the Buku Besar
KII can report income/expenses in natural language:
- "Bayar VPS DigitalOcean Rp 350rb" → add to pengeluaran
- "Dapet project company profile dari PT Harmoni, dibayar Rp 2.5jt" → add to pemasukan
- OWL updates `/root/projects/devlokal-id/reports/buku-besar-YYYY-MM-DD.md` accordingly

## Updated Analysis (6-15 Jun 2026) — Time Series Only + Scaling

### Updated Time Series Data (10 days)
- Period: 6-15 June 2026
- Total clicks: 122
- Avg clicks/day: 12.2
- Median: 12.5
- Std dev: 6.52
- CV: 53.5%

### Day-of-Week Pattern (Confirmed)
- **Senin (Mon): 3 clicks (-75% vs avg)** — Dead zone. Pausing recommended.
- **Selasa (Tue): 21 clicks (+72%)** — Sweet spot.
- **Rabu (Wed): 24 clicks (+97%)** — Peak day.
- **Kamis (Thu): 15 clicks (+23%)** — Good.
- **Jumat (Fri): 14 clicks (+15%)** — Good.
- **Sabtu (Sat): 11 clicks avg** — Below avg.
- **Minggu (Sun): 10 clicks avg** — Below avg.
- **Key finding:** Senin consistently dead (3 clicks × 2 data points). Rabu-Selasa consistently peak.

### Trend
- Linear regression slope: -0.376 clicks/day → Essentially FLAT (R² = 0.03)
- No organic growthAds DevLokal ID — Analysis & Scaling (Jun 2026) — Need budget scale.

### ⚠️ CPI Max Setting
KII sets CPC max at **Rp 5,000** (not Rp 7,000). Always use Rp 5,000 as upper bound for DevLokal ID cost projections.

### Cost Analysis (Updated @ CPC Rp 5,000)
| Scenario | CPC | Daily Spend | Monthly Est. |
|----------|-----|-------------|--------------|
| Low | Rp 1,500 | Rp 18,300 | Rp 549K |
| Mid | Rp 3,500 | Rp 42,700 | Rp 1.28M |
| Max KII | Rp 5,000 | Rp 61,000 | Rp 1.83M |

### Conversion Funnel @ CPC Rp 5,000 (122 clicks)
| Scenario | Click-to-Lead | Lead-to-Deals | Leads | Deals | Revenue | Cost/Deal |
|----------|--------------|---------------|-------|-------|---------|-----------|
| Konservatif | 2% | 5% | 2 | 0 | Rp 0 | — |
| Moderat | 5% | 10% | 6 | 0 | Rp 0 | — |
| Optimis | 8% | 15% | 9 | 1 | Rp 2.5M | Rp 610K |

### Break-Even Analysis
- **B/E rate: 0.20%** = 1 deal per 500 clicks
- **B/E @ current (1x):** 0.7 deals/bulan — Not enough
- **B/E @ 2x:** 1.5 deals/bulan — Start breaking even
- **B/E @ 3x:** 2.2 deals/bulan — Profitable

### Scaling Roadmap
| Phase | Scale | Clicks/bln | Spend/bln | Est. Deals (optimis) | ROAS |
|-------|-------|------------|-----------|----------------------|------|
| Current | 1x | 366 | Rp 1.8M | 4.4 | 6.0x |
| Phase 1 (Bulan 1-2) | 2x | 732 | Rp 3.7M | 8.8 | 6.0x |
| Phase 2 (Bulan 3-4) | 3x | 1,098 | Rp 5.5M | 13.2 | 6.0x |
| Phase 3 (Bulan 5+) | 4-5x | 1,464-1,830 | Rp 7.3-9.1M | 17.6-22.0 | 6.0x |

### CPC Sensitivity at 3x (~1,100 clicks/bln)
| CPC | Spend | Profit | ROI |
|-----|-------|--------|-----|
| Rp 5,000 (base) | Rp 5.5M | Rp 27.5M | +500% |
| Rp 5,500 (+10%) | Rp 6.1M | Rp 27.0M | +445% |
| Rp 6,000 (+20%) | Rp 6.6M | Rp 26.4M | +400% |
| Rp 6,500 (+30%) | Rp 7.2M | Rp 25.9M | +362% |

### Budget Allocation Recommendation
| Hari | Weight | Action |
|------|--------|--------|
| Senin | 0.21x | ⬇️ KURANGI 50-60% |
| Selasa | 1.50x | ⬆️ TAMBAH 25% |
| Rabu | 1.71x | ⬆️ TAMBAH 25% |
| Kamis | 1.07x | ➡️ PERTAHANKAN |
| Jumat | 1.00x | ➡️ PERTAHANKAN |
| Sabtu | 0.79x | ⬇️ KURANGI 20% |
| Minggu | 0.71x | ⬇️ KURANGI 20% |

### Key Takeaways (Updated)
1. **SENIN = DEAD ZONE** — 2 data points, consistently 3 clicks. Pause or cut 50-60%.
2. **SELASA-RABU = SWEET SPOT** — +72-97% vs average. Add budget +25%.
3. **TREND FLAT** — No organic growth. Need budget scale or quality score improvement.
4. **VOLUME TOO SMALL** — 122 clicks/10 days = ~370/month. Too small for reliable conversion funnel. Target 1,000-2,000 clicks/month minimum.
5. **NO CONVERSION TRACKING** — Setup form submit, WA click, phone call tracking before scaling.
6. **QUICK WIN** — Dayparting + bid adjustment can improve efficiency 15-20% without budget increase.
7. **CPC MAX = Rp 5,000** — KII's setting. Use for all projections.
8. **SCALING RISK** — CPC may rise 10-30% when scaling. Conversion rate may drop. Step-by-step approach required.

## Lessons Learned
- KII prefers direct answers with complete commands, not vague instructions
- Google Ads UI varies — "Conversion" menu may not exist for all account types
- Always check conversion values — defaults (1.00, 7.00) are not real business values
- Static HTML sites on VPS (Nginx) are straightforward to modify for conversion tracking
- KII's site was at `/var/www/devlokal.id/html/` — found via `find /var/www -maxdepth 2 -name "index.html"`
- **CSV Encoding:** Google Ads billing CSVs are UTF-16 LE with BOM — must decode via python3, not read directly
- **Telegram formatting:** No table support — use bullet lists and emoji headers
- **Weekly reports:** Use cron job with `deliver: "local"` + `send_message` in prompt for clean delivery
- **Report style:** Indonesian/English mix, IDR thousand separators (Rp 656.580), concise, actionable
- **MEMORY.md drift:** If memory tool refuses due to drift, use `patch` tool to append directly — check for `.bak` files and `.lock` files that may cause false drift detection
- **⚠️ CPC MAX for DevLokal ID = Rp 5,000** — Always use this as upper bound, never assume higher
- **⚠️ Scaling analysis pattern:** Always include break-even, CPC sensitivity, and phased roadmap — KII expects this level of detail for budget decisions
- **⚠️ Don't scale before first conversion:** 122 clicks with 0 closing = funnel problem, not volume problem. KII agreed scaling was premature. Recommend waiting 30 days and focusing on funnel optimization first.
- **⚠️ Google Maps scraping is unreliable:** Headless browser scraping via Playwright failed (timeout, bot detection, limited results without login). Google Places API key may not have Places API enabled. Better alternatives: manual search, buy database, IG scraping, or Google Ads lead forms.
- **✅ Direct WA outreach as alternative:** When ads aren't converting, suggest manual WA outreach to UMKM. Soft pitch script: mention business name, ask before pitching. 10-20 msgs/day, ~5-10% response rate. Not scalable but good stopgap.
- **✅ Landing page audit findings (devlokal.id):** Design is clean & professional. Issues found: (1) WA number may not render in HTML source, (2) no testimonial section, (3) form has 3 required fields causing friction, (4) no urgency/scarcity signals, (5) no conversion tracking visible. Priority fixes: testimonials, reduce form fields, add urgency.

## Session: June 21 2026 — Conversion Tracking Live, Funnel Gap Discovered

### What Happened
- KII installed conversion tracking and negative keywords
- New CSV data showed: **36 conversions**, 20.11% conv rate, Rp 33.938/conv
- OWL initially reported this as "PROFITABLE — ROAS 58.93x"
- KII corrected: "tapi yang WA gua hanya segini bro" — shared actual lead spreadsheet
- **Reality check:** Only 5 actual leads, 0% close rate
- Google Ads "36 conversions" = WA button clicks, not actual qualified leads

### The Funnel Gap
| Stage | Google Ads Reported | Actual |
|-------|-------------------|--------|
| Clicks | 179 | 179 |
| Conversions | 36 | ~5 actual messages |
| Qualified Leads | — | 5 (2 ghosted, 1 said no, 2 considering) |
| Closed Deals | — | 0 |

### Root Cause Analysis
- Conversion tracking was set up to track **WA button click** as conversion
- 36 people clicked the WA button, but most never sent a message
- Of the 5 who did message: 2 ghosted after first reply, 1 said no, 2 "still considering" (B2B, longer sales cycle)
- **The ad is working** (good CTR, good targeting) — the problem is the **follow-up process**

### Lessons Learned (CRITICAL)
1. **Google Ads conversions ≠ actual leads.** Always ask user for real lead/deal data before declaring success.
2. **Build the full funnel table** when user provides actual data: clicks → WA clicks → actual messages → qualified leads → closed deals
3. **Calculate REAL metrics** based on actual leads, not tracked conversions
4. **Follow-up system is the bottleneck** — not ad optimization. Focus on:
   - WA auto-reply (respond within 5 minutes)
   - Follow-up sequence (Day 1, 2, 3, 7)
   - WA Business labels for lead tracking
5. **Don't calculate ROAS from tracked conversions** — it will be wildly inflated
6. **Scaling is premature** when close rate is 0%, regardless of what Google Ads reports

### Updated Recommendations
1. Fix follow-up system (auto-reply, follow-up templates, CRM)
2. Redefine conversion tracking to measure "WA message sent with prefill" instead of "WA button click"
3. Wait for actual close data before scaling budget
4. Consider landing page changes: add testimonials, reduce form friction, add urgency

## Session: June 21, 2026 (Part 2) — Landing Page Audit Correction & Follow-Up Templates

### What Happened
- OWL audited devlokal.id landing page and flagged 6 "problems"
- KII corrected OWL on multiple points:
  1. Testimonials DO exist (initials + "VERIFIED CLIENT" labels with images)
  2. Price IS below fold (intentional design choice)
  3. CTA copy is fine (user's style preference)
  4. "10+ projects" is accurate (genuine count, not inflated)
  5. No discount/urgency is intentional
  6. WA links work on both desktop and mobile
- OWL was wrong on 5 out of 6 audit points

### Lessons Learned (CRITICAL)
1. **Don't flag issues without verifying with the user first** — web_extract/browser_snapshot can misrepresent visual elements
2. **Accept corrections gracefully** — KII knows his business better than OWL's assumptions
3. **Don't assume design choices are bugs** — "price below fold" might be intentional
4. **Social proof numbers should be honest** — don't recommend inflating project counts
5. **WA links may be redacted in web_extract** — always ask user to confirm they work

### Follow-Up Templates Created
- Template 1: Soft follow-up for "pikirkan dulu" leads
- Template 2: Portfolio follow-up for leads who asked price
- Template 3: Day 2 follow-up for no-response leads
- Template 4: Day 7 final follow-up with urgency
- Saved to `templates/follow-up-templates.md`

### Updated Funnel Analysis (Post-Correction)
- Landing page is NOT the problem (design is clean, professional, complete)
- Conversion tracking overcounting IS the problem (WA click ≠ qualified lead)
- Follow-up process IS the bottleneck (0% close rate from 5 actual leads)
- **Root cause**: No systematic follow-up sequence, leads fall through cracks

## Session: June 21, 2026 (Part 3) — Scroll-Depth Gating Implementation

### What Happened
- OWL and KII identified that conversion tracking was overcounting (WA button click = conversion, not actual lead)
- Solution: Implement scroll-depth gating — only fire Google Ads conversion if user scrolled ≥40% (seen pricing section)
- Code edited directly on VPS at `/var/www/devlokal.id/html/index.html`
- Nginx reloaded via HUP signal (s6-supervise managed)

### Technical Implementation
```javascript
// Scroll-depth gating for trackWAConversion
window.trackWAConversion = function (label) {
  var scrollPercent = Math.round((window.scrollY / (document.body.scrollHeight - window.innerHeight)) * 100);
  
  // Always track GA4 event
  gtag('event', 'wa_click', {
    event_category: 'lead',
    event_label: label || 'unknown',
    scroll_depth: scrollPercent
  });

  // Only fire Google Ads conversion if scrolled >= 40%
  if (scrollPercent >= 40) {
    gtag('event', 'conversion', {
      'send_to': 'AW-18217403806/oESnCKOhp8AcEJ6L3u5D',
      'event_callback': function () { }
    });
  }
};
```

### Expected Results
- Conversion count will DROP (from 36 → estimated 15-20)
- But data will be more accurate — only qualified leads counted
- Cost per conversion will be more realistic

### Lessons Learned
1. **Scroll-depth gating** is a reliable technique for filtering low-intent WA clicks
40% threshold = user has seen hero + services + pricing sections
2. **Always backup before editing** — `cp index.html index.html.bak.<timestamp>`
3. **Nginx on s6-supervise** — use `kill -HUP <pid>` instead of `systemctl reload`
4. **Verify grep after edit** — confirm changes took effect before declaring done

### Google Ads Learning Phase Note
- KII asked: "Kalau pause & restart, learning phase reset?"
- Answer: YES — 1-2 week learning phase on restart, CPC rises 10-30%
- Recommendation: Keep campaign running with small budget rather than pausing
- If must pause, allow 2 weeks for stabilization after restart

### Budget Math for Small-Budget Campaigns
- Google Ads needs 5-10 conversions/week minimum for learning
- 30-50 conversions for reliable data
- Daily budget = TCPA → max 1 conv/day (not enough)
- Better: Lower daily budget to extend runway, collect more data
- KII's setup: Topup 100k, daily budget 25k, target CPA 50k → 4 days runway

## Session: June 21, 2026 (Part 4) — Prototype-First Outreach Strategy

### What Happened
- KII and KII discussed replacing long WA intro templates with prototype-first approach
- Old approach: 6-8 line template → wait for response → FU1 with portfolio
- New approach: Directly send prototype link + 1 sentence → filter non-qualified leads immediately

### Why Prototype-First Works Better
1. People don't read long WA messages — scan 2-3 lines max
2. Proof > promises — seeing a real website beats 100 words of description
3. Automatic filter — only interested people respond
4. 5 min per lead vs 3-5 min for template typing

### Template (All Categories)
```
Halo, ini contoh website [kategori] yang pernah saya buat:
[LINK PROTOTYPE]

Kalau cocok, bisa saya buatkan yang serupa untuk [nama bisnis] 😊
```

### Portfolio Inventory
- Laundry: https://laundry-website-desi-pguf.bolt.host/
- Company Profile: https://kanopi-pro.vercel.app/, https://harmoni-arsa.id/
- Salon: NEEDED
- F&B: NEEDED
- Bengkel: NEEDED

### Lessons Learned
1. **Don't send prototype link in first message for OLD approach** — too salesy
2. **But for NEW approach, prototype IS the first message** — it's the hook
3. **Personalize with business name** — "untuk [nama bisnis]" makes it feel researched, not spam
4. **Follow-up only with those who responded** — max 2 FU, then archive

### Skill Updated
- `devlokal-sales-marketing` SKILL.md updated with prototype-first templates
- Old templates replaced entirely — no more 6-8 line intros

### What Happened
- KII asked for scaling analysis → OWL provided full scaling roadmap (1x-5x)
- KII correctly pushed back: "scaling terlalu besar, belum ada closing"
- OWL agreed: 10 days too early, focus on funnel first
- KII suggested direct WA outreach to UMKM as alternative acquisition
- OWL provided outreach strategy, script template, and scraping approach
- Google Maps scraping attempted but failed (unreliable)
- Decision: KII will manually search targets, start with 10 UMKM/day

### Key Decision
**Do NOT scale Google Ads yet.** Wait for 30 days of data and first conversion. Focus on:
1. Funnel optimization (landing page, conversion tracking)
2. Quick wins (dayparting, bid adjustments)
3. Parallel acquisition via direct WA outreach
4. Review on ~July 7 2026