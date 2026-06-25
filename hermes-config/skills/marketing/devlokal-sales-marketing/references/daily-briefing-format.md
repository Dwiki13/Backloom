# Daily Marketing Briefing — Validated Format

## Format That Works (validated 2026-06-23)

This is the format used in the actual briefing sent on 2026-06-23. It differs from the earlier template — this is the current validated version:

```
📋 *Daily Marketing Briefing — [Day], [Date]*

🎯 *Rekomendasi Hari Ini:*
• *Kategori:* [Kategori UMKM]
• *Area:* [Area target]
• *Target:* [N] kontak baru
• *Alasan:*
  — [Reason 1 with score impact]
  — [Reason 2 with score impact]
  — *Score: X/10* — priority level

📊 *Snapshot Outbound:*
• Total kontak: N (N Laundry, N Salon, N Other)
• Response rate: X% (N/N) — [assessment]
• Warm leads: [Name] ("quote"), [Name] (context)
• Lost: [Name] (reason)
• Invalid: N nomor
• Belum bales: N kontak → follow up window status

📍 *Area Performance:*
• [Area]: N kontak ([breakdown])
• [Area]: N kontak ([breakdown])
• [Area]: N kontak ([breakdown])

💰 *Financial Snapshot:*
• Total Google Ads spend: Rp X (N deposit + N campaign + VAT)
• Total income: Rp X ⚠️ (if 0)
• CPC rata-rata: ~Rp X (N total clicks)
• Conversion: N closing dari outbound → revenue assessment

💡 *Action Items:*
1. *[URGENCY]* — specific action with context
2. *[URGENCY]* — specific action with context
3. *[URGENCY]* — specific action with context

📝 *Market Intel:*
• Kompetitor: [names] — harga range
• DevLokal edge: [key differentiator]
• Tren: [relevant trend]
• Market condition: [assessment]

📌 *Daily Worklist:*
- [ ] [Task 1]
- [ ] [Task 2]
- [ ] [Task 3]
- [ ] [Task 4]
- [ ] [Task 5]

🤖 _OWL — DevLokal ID Sales & Marketing_
```

## Data Sources (in order of priority)
1. `/root/projects/devlokal-id/data/marketing-log.csv` — pipeline stats
2. `/root/projects/devlokal-id/data/income.json` — income
3. `/root/projects/devlokal-id/data/expenses.json` — ad spend
4. `/root/todo-YYYY-MM-DD.md` (yesterday) — previous status
5. `web_search` — market trends, industry benchmarks
6. `/root/projects/devlokal-id/sales-tracking.md` — detailed contact history

## Key Metrics to Calculate
- **Response rate** = Responded / (Total - Invalid)
- **CPC avg** = Total spend / Total clicks
- **Burn rate** = Total spend vs Income (CRITICAL if 0 income)
- **Budget runway** = Remaining budget / Daily spend rate

## Style Rules
- Numbers first, analysis second
- Use emoji section headers for scanability
- Keep each bullet to 1-2 lines max
- Always end with actionable recommendations
- Concise — KII style, no fluff
- Recommendation FIRST (most important), then supporting data
