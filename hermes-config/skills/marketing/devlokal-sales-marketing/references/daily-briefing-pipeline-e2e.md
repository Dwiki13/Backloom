# Daily Briefing Pipeline — End-to-End Reference

Validated 2026-06-24. Full execution path for the daily marketing briefing cron job.

## Pipeline Steps (in order)

### 1. Data Gathering
```bash
# Date
TZ='Asia/Jakarta' date +%Y-%m-%d
TZ='Asia/Jakarta' date +A

# CSV analysis
awk -F',' 'NR>1{print $3}' /root/projects/devlokal-id/data/marketing-log.csv | sort | uniq -c | sort -rn  # categories
awk -F',' 'NR>1{print $5}' /root/projects/devlokal-id/data/marketing-log.csv | sort | uniq -c | sort -rn  # areas
awk -F',' 'NR>1{print $8}' /root/projects/devlokal-id/data/marketing-log.csv | sort | uniq -c | sort -rn  # response
awk -F',' 'NR>1{print $9}' /root/projects/devlokal-id/data/marketing-log.csv | sort | uniq -c | sort -rn  # stage
awk -F',' 'NR>1{print $1}' /root/projects/devlokal-id/data/marketing-log.csv | sort | uniq -c | sort -rn  # per date

# Warm/leads detail
awk -F',' 'NR>1 && ($9=="Warm" || $9=="Follow up 1" || $9=="Follow up 2"){print $1","$2","$3","$5","$9","$10}' /root/projects/devlokal-id/data/marketing-log.csv

# Financial
python3 -c "
import json
with open('/root/projects/devlokal-id/data/expenses.json') as f:
    data = json.load(f)
total = sum(e['amount'] for e in data['expenses'])
spend = sum(e['amount'] for e in data['expenses'] if 'spend' in e['description'].lower())
print(f'Total: Rp {total:,} | Campaign spend: Rp {spend:,}')
"
```

### 2. Key Metrics to Calculate
- **Response rate** = Responded / (Total - Invalid) × 100
- **CPC avg** = Campaign spend / Total clicks
- **Burn rate** = Total spend vs Income (CRITICAL if 0)
- **Budget runway** = Remaining budget / Daily spend rate

### 3. Recommendation Engine Logic
When choosing today's target category/area:
1. Find category with lowest saturation (fewest existing contacts)
2. Find area with highest UMKM density but fewest contacts in DB
3. Cross-reference: high potential + low competition = priority
4. Score 1-10 based on: market size, competition in DB, response history

### 4. Telegram Send (preferred: execute_code)
Use `execute_code` tool with subprocess — see SKILL.md "Sending method" section.

### 5. Todo File
- Check if `/root/todo-YYYY-MM-DD.md` exists
- If not: create with full template (see SKILL.md)
- If exists: append new tasks under `## Tasks`
- Always update `## Status` and `## Pending Details`

## Common Pitfalls
1. **Don't run the script** — it doesn't exist. Manual briefing only.
2. **Don't send to thread 334** — that's Trading. Always use 1264.
3. **Don't extract token from .env** — it's masked. Use `/root/.hermes/scripts/.bot_token`.
4. **Don't skip the todo file** — reminder scripts depend on it.
5. **Response rate < 15%** → pivot category or area, don't push same segment.
6. **Income = 0 after 20+ days** → CRITICAL, prioritize warm lead follow-up over new outreach.

## Data File Locations
- `/root/projects/devlokal-id/data/marketing-log.csv` — main log
- `/root/projects/devlokal-id/data/income.json` — income records
- `/root/projects/devlokal-id/data/expenses.json` — ad spend
- `/root/projects/devlokal-id/sales-tracking.md` — detailed contact history
- `/root/todo-YYYY-MM-DD.md` — daily todo (created by this pipeline)
