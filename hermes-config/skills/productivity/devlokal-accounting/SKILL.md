---
name: devlokal-accounting
description: Use when KII asks to record business transactions (income or expenses), analyze financials, generate financial reports, or discuss business metrics. Covers DevLokal ID, Rental PS, and Admin PT Harmoni Artha Sentra. Trigger on "catet", "expense", "pemasukan", "pengeluaran", "laporan keuangan", "margin", "cash flow", "budget", "spend", "bayar", "dapet project", "invoice", "gajian", "rental", "harmoni", "admin".
---

# KII Business Accounting Workflow

Financial tracking and analysis for KII's THREE businesses.

## Businesses Overview

| # | Business | Type | Status |
|---|---|---|---|
| 1 | **DevLokal ID** | Jasa Web Freelance | Active, Google Ads running |
| 2 | **Rental PS** | Rental PlayStation | Active |
| 3 | **Admin PT Harmoni Artha Sentra** | Admin/Operational Support | Active |

---

## Business 1: DevLokal ID — Jasa Web Freelance

- **Services & Pricing:**
  - Landing page: Rp 1.500.000
  - Company profile: Rp 2.500.000
  - Toko online: custom
  - Custom web app: custom
- **Portfolio:** Kanopi Pro, PT Harmoni Artha Sentra, Sevora & Co
- **WA Business:** 6289602473532
- **Google Ads:** Active — billing CSV analysis, weekly reports
- **Employees:** No permanent employees. Per-project collab with freelancers. When KII says "collab [nama] Rp X", record as expense (category: collab/freelance)

## Business 2: Rental PS (Playstation)

- **Type:** Rental PlayStation business
- **Structure:** Partnership with friend — **profit split 70:30** (friend 70%, KII 30%)
- **KII's share of income: 30% of gross rental revenue**
- **Fixed monthly costs (deducted from KII's 30%):**
  - Electricity: Rp 82.000/bulan
  - Maintenance/repair fund (uang kas): Rp 100.000/bulan
- **KII's net from Rental PS = (30% × gross revenue) - Rp 182.000**
- **Separate bookkeeping** — record both gross revenue and KII's net share

## Business 3: Admin PT Harmoni Artha Sentra

- **Type:** Administrative / operational support for PT Harmoni Artha Sentra
- **Structure:** KII is a salaried partner — receives monthly salary/gaji
- **Partners:** 4 people total (including KII)
- **Income for KII:** Monthly salary from PT Harmoni Artha Sentra
- **Expenses:** Operational costs, supplies, transport, communication
- **Separate bookkeeping** from other businesses

---

## Payroll / Gajian Schedule

- **Gajian date: 28th of every month**
- **If 28th falls on Saturday/Sunday (weekend): gajian moves to the preceding Friday (27th or 26th)**
- **Accounting starts recording from the day AFTER gajian**
- On gajian day, record salary/wage expenses for all employees across all businesses

### Auto-Calculate Gajian Date (DO NOT ask KII — calculate it)

When you need to determine the gajian date for any month:

1. Run: `python3 -c "import datetime; d = datetime.date(YYYY, MM, 28); print(d.strftime('%A %d %B %Y'))"`
2. If result is **Saturday** → gajian = Friday 27th
3. If result is **Sunday** → gajian = Friday 26th (or 27th if 26th is also weekend, but this never happens)
4. Otherwise → gajian = 28th as normal
5. Recording starts the day after gajian

### Gajian Reminder Rule

- **Every day, check if gajian is within the next 3 days**
- If yes AND no payroll has been recorded yet for that month → send reminder to Topic 3:
  > "📅 Reminder: Gajian besok/tanggal [X]. Siapa aja yang gajian dan berapa?"
- If KII hasn't responded by gajian day → send another reminder
- Do NOT wait for KII to ask — proactively remind

### Gajian Dates 2026 (Pre-calculated)

| Month | 28th falls on | Gajian Date | Recording Starts |
|---|---|---|---|
| Juni 2026 | Sunday (per KII) | **Jumat 26 Jun** | 27 Jun 2026 |
| Juli 2026 | Monday | Senin 28 Jul | 29 Jul 2026 |
| Agustus 2026 | Thursday | Kamis 28 Aug | 29 Aug 2026 |
| September 2026 | Sunday | **Jumat 26 Sep** | 27 Sep 2026 |
| Oktober 2026 | Tuesday | Selasa 28 Okt | 29 Okt 2026 |
| November 2026 | Friday | Jumat 28 Nov | 29 Nov 2026 |
| Desember 2026 | Sunday | **Jumat 26 Des** | 27 Des 2026 |

**Note:** Always verify with `datetime` before assuming. The 2026 table above is a reference — recalculate if unsure.
- Track headcount and per-employee salary in payroll records
- When KII says "gajian [nama] Rp X", record as payroll expense immediately even if it's before the recording start date (for baseline)

## Recording Start Date

- **Official recording start: 27 Juni 2026** (day after gajian)
- Gajian Juni 2026: **Jumat 26 Juni** (because 28 Jun falls on Sunday per KII)
- All transactions from 27 Jun 2026 onward must be recorded
- Pre-27 Jun transactions (like Google Ads spend Jun 6-14) are recorded as **historical baseline data**

## Rental PS — Profit Split Schedule

- **Bagi hasil date: 25th of every month**
- KII's share: 30% of gross monthly revenue
- Partner's share: 70% of gross monthly revenue
- Fixed costs (electricity Rp 82rb + maintenance fund Rp 100rb) deducted from KII's 30% share
- Record on the 25th: gross revenue → partner payout → KII net

---

## Topic & Delivery

- **Topic:** Topic 3 (Bisnis) in MyAssistant24/7 — chat_id: -1003966561389
- All financial reports and updates go to Topic 3

---

## Directory Structure

```
/root/projects/devlokal-id/
├── data/
│   ├── expenses.json
│   ├── income.json
│   └── google-ads-billing/
├── reports/
│   ├── buku-besar-YYYY-MM.md
│   ├── google-ads-YYYY-MM-DD.md
│   ├── profit-loss-YYYY-MM.md
│   └── tax-summary-YYYY-MM.md
└── scripts/
    └── weekly-google-ads-report.sh

/root/projects/rental-ps/
├── data/
│   ├── expenses.json
│   ├── income.json
│   └── assets.json
├── config/
│   ├── pricing.json
│   └── employees.json
└── reports/
    ├── buku-besar-YYYY-MM.md
    ├── profit-loss-YYYY-MM.md
    └── occupancy-YYYY-MM.md

/root/projects/harmoni-arsa/
├── data/
│   ├── expenses.json
│   ├── income.json
│   └── operational.json
├── config/
│   └── employees.json
└── reports/
    ├── buku-besar-YYYY-MM.md
    └── profit-loss-YYYY-MM.md
```

---

## Expense Categories

### DevLokal ID

| Category | Examples |
|---|---|
| **google-ads** | Google Ads campaign spend, VAT on ads |
| **vps-hosting** | DigitalOcean, VPS, domain, SSL, CDN |
| **software** | IDE licenses, SaaS tools, API subscriptions |
| **api-cost** | OpenAI API, Gemini, third-party APIs |
| **marketing** | Outside Google Ads (social media, etc.) |
| **operational** | Payment fees, bank charges, misc |

### Rental PS

| Category | Examples |
|---|---|
| **electricity** | PLN bill: Rp 82.000/bulan (fixed) |
| **maintenance-fund** | Uang kas maintenance: Rp 100.000/bulan (fixed) |
| **ps-equipment** | PS unit purchase/repair, controllers, TVs, headsets |
| **maintenance** | Cleaning, AC repair, furniture |
| **operational** | Snacks, drinks, wifi, misc |
| **payout-partner** | 70% revenue share payout to partner (record as expense distribution) |

### Admin PT Harmoni Artha Sentra

| Category | Examples |
|---|---|
| **supplies** | Office supplies, printer ink, paper |
| **transport** | Fuel, parking, vehicle maintenance |
| **communication** | Phone credit, internet |
| **services** | Third-party service fees |
| **operational** | Misc operational costs |

---

## Income Categories

### DevLokal ID

| Category | Examples |
|---|---|
| **project-fee** | Client project payments |
| **maintenance** | Monthly maintenance retainer |
| **referral** | Referral commissions |

### Rental PS

| Category | Examples |
|---|---|
| **rental-fee** | Hourly/session rental income (record GROSS, then split 70/30) |
| **membership** | Membership/voucher packages (record GROSS, then split) |
| **fb-food-beverage** | Snack & drink sales (100% KII's 30% share) |
| **tournament** | Tournament entry fees (record GROSS, then split) |

**Important:** Always record GROSS revenue first, then record the 70% partner payout as expense. KII's net = 30% of gross minus fixed costs (Rp 182.000).

### Admin PT Harmoni Artha Sentra

| Category | Examples |
|---|---|
| **salary** | KII's monthly salary/gaji from PT Harmoni |
| **reimbursement** | Reimbursable expenses from PT Harmoni |

---

## Payroll Tracking

- **Gajian: tanggal 28 setiap bulan**
- **Jika 28 jatuh di Sabtu/Minggu → gajian di Jumat sebelumnya (27 atau 26)**
- Record on gajian day as expense under category **payroll**
- Track per-employee: name, business assignment, monthly salary, position

### Payroll Entry Format
```json
{
  "id": "PAY-202606-001",
  "date": "2026-06-28",
  "category": "payroll",
  "business": "rental-ps",
  "description": "Gajian Juni 2026 - Karyawan A",
  "amount": 2500000,
  "currency": "IDR",
  "employee": "Karyawan A",
  "period": "2026-06"
}
```

---

## Workflows

### Recording Expenses

When KII says "bayar X Rp Y" or similar:

1. Identify which business (DevLokal / Rental PS / Harmoni Arsa)
2. Read corresponding `data/expenses.json`
3. Append new entry with unique ID
4. Write updated file
5. Update monthly ledger `buku-besar-YYYY-MM.md`
6. Confirm to KII: "[Rp X] tercatat sebagai [kategori] di [business]"

### Recording Income

When KII says "dapet X, dibayar Rp Y":

1. Identify which business
2. Read corresponding `data/income.json`
3. Append entry with status (`pending` / `dp-received` / `paid`)
4. Write updated file
5. Update monthly ledger
6. Confirm to KII

### Google Ads Analysis (DevLokal ID only)

**Note:** `google-ads-analysis` skill belongs to **Topic Marketing (1264)**, not Topic 3 (Bisnis). When KII sends Google Ads CSV in Topic 3, do basic expense recording here. Deep analysis (CPC, CTR, keyword optimization) should be requested in Topic Marketing.

When KII sends Google Ads CSV in Topic 3:

1. Decode UTF-16 LE: `raw.decode('utf-16-le', errors='replace')`
2. Analyze: daily spend, clicks, CPC, payments, VAT, trends
3. Generate report → `reports/google-ads-YYYY-MM-DD.md`
4. Update `data/expenses.json` with ad spend
5. Send summary to Topic 3

### Monthly P&L

At month-end or on request:

1. For EACH business: aggregate income, expenses, calculate margin
2. Combined overview: all three side by side
3. Include payroll as separate line item
4. Generate `profit-loss-YYYY-MM.md` per business
5. Send summary to Topic 3

### Monthly P&L Template
```
📊 Monthly P&L — [Month] [Year]

🏢 DevLokal ID:
  Income:    Rp X
  Expenses:  Rp X
  GAP:       Rp X

🎮 Rental PS:
  Income:    Rp X
  Expenses:  Rp X
  GAP:       Rp X

🏛️ Admin PT Harmoni Arsa:
  Income:    Rp X
  Expenses:  Rp X
  GAP:       Rp X

📊 Combined GAP: Rp X

---
📍 OWL Accountant — KII Businesses
```

### Weekly Report

Every Sunday 10:00 WIB (cron job `816256bf2443`), or on demand:

1. Check for new Google Ads CSVs
2. Summarize week's activity for ALL THREE businesses
3. Check if gajian is coming up — remind KII
4. Send report to Topic 3

### Weekly Report Template (Telegram)
```
📊 Weekly Financial Update
🗓 Minggu [date range]

🏢 DevLokal ID:
  Income: Rp X | Exp: Rp X | GAP: Rp X

🎮 Rental PS:
  Income: Rp X | Exp: Rp X | GAP: Rp X

🏛️ Admin PT Harmoni Arsa:
  Income: Rp X | Exp: Rp X | GAP: Rp X

📊 Combined Net Cash Flow: Rp X
📅 Gajian: [date] ([day])
💡 Notes: [insight]

---
📍 OWL Accountant — KII Businesses
```

---

## Key Metrics

### DevLokal ID

| Metric | Formula |
|---|---|
| **CAC** | Google Ads spend / leads from ads |
| **Avg Project Value** | Revenue / number of projects |
| **Profit Margin** | (Revenue - Expenses) / Revenue x 100% |
| **Ads ROI** | Revenue from ads / Ad spend |

### Rental PS

| Metric | Formula |
|---|---|
| **Occupancy Rate** | Hours rented / Available hours x 100% |
| **Rev per PS** | Rental income / Number of PS units |
| **Profit Margin** | (Revenue - Expenses) / Revenue x 100% |
| **Payroll Ratio** | Payroll / Revenue x 100% |

### Admin PT Harmoni Artha Sentra

| Metric | Formula |
|---|---|
| **Profit Margin** | (Revenue - Expenses) / Revenue x 100% |
| **Op Cost Ratio** | Operational expenses / Revenue x 100% |

### Combined

| Metric | Formula |
|---|---|
| **Monthly Burn** | Total expenses - Total income |
| **Cash Runway** | Cash on hand / Monthly burn |
| **Diversification** | Income per biz / Total income x 100% |

---

## Formatting Rules

- Currency: Rp with thousand separator → Rp 1.500.000
- Dates: Indonesian → 14 Juni 2026
- Reports: Save to file AND send Telegram summary
- Language: ID/EN mix, casual KII style

---

## Common Pitfalls

1. **Calculate gajian date yourself** — use `python3 -c "import datetime; d = datetime.date(YYYY, MM, 28); print(d.strftime('%A %d %B %Y'))"`. Do NOT ask KII to confirm. If 28th is Saturday → gajian = Friday 27th. If Sunday → gajian = Friday 26th. Otherwise → 28th. Only ask KII if the result seems ambiguous.
2. **Google Ads CSV encoding** — always decode UTF-16 LE, never read as plain text
3. **Campaign cost signs** — costs are negative (debits), payments are positive (credits)
4. **PPN (VAT)** — 11% on Google Ads in Indonesia
5. **Rental PS revenue** — always record GROSS first, then split. Never record only KII's 30% as income.
6. **Keep responses concise** — KII prefers "segitu dulu aja" style. Don't over-explain. Give the answer, not the lecture.

---

## Related Files

### DevLokal ID
- `/root/projects/devlokal-id/data/expenses.json`
- `/root/projects/devlokal-id/data/income.json`
- `/root/projects/devlokal-id/reports/`

### Rental PS
- `/root/projects/rental-ps/data/expenses.json`
- `/root/projects/rental-ps/data/income.json`
- `/root/projects/rental-ps/data/assets.json`
- `/root/projects/rental-ps/config/pricing.json`
- `/root/projects/rental-ps/config/employees.json`
- `/root/projects/rental-ps/reports/`

### Admin PT Harmoni Artha Sentra
- `/root/projects/harmoni-arsa/data/expenses.json`
- `/root/projects/harmoni-arsa/data/income.json`
- `/root/projects/harmoni-arsa/data/operational.json`
- `/root/projects/harmoni-arsa/config/employees.json`
- `/root/projects/harmoni-arsa/reports/`

### Shared
- `/root/.hermes/cache/documents/` — Uploaded CSV files from KII

### Skill References
- `references/gajian-schedule.md` — Gajian dates, recording start rules, 2026 calendar
- `references/rental-ps-split.md` — Profit split calculation, recording steps, examples
