---
name: daily-worklist
description: Daily to-do / worklist tracking for KII — auto-generate today's date, carry over pending tasks, mark stale items. Trigger when user says "todays task", "tambahin todo", "todo hari ini", "update progress", "done", or any task/note tracking request.
---

# Daily Worklist (KII)

Daily task tracking with automatic date generation, pending task carry-over, and stale tagging.

## Rules

1. **ALWAYS auto-generate today's date** — never hardcode or guess dates. Run `TZ='Asia/Jakarta' date +%Y-%m-%d` to get the current date. This is non-negotiable.
2. **One file per day** — `/root/todo-YYYY-MM-DD.md` (e.g. `todo-2026-05-28.md`)
3. **Carry-over on new day** — when user sends tasks for a new day:
   - **WAJIB: Read ALL previous todo files** (at least 3-4 days back) before writing anything. Check each file for tasks marked `[x]` done — those must NEVER reappear in today's list.
   - Task yang masih pending akan dibawa ke file hari baru. Setiap kali user bertanya tentang to-do list harian, selalu baca file terbaru `/root/todo-YYYY-MM-DD.md` untuk memastikan informasi akurat.
   - All pending (`- [ ]`) tasks carry over to today's file
   Task yang udah done TIDAK boleh muncul lagi di hari berikutnya.
   - New tasks appended at the bottom
   - **PITFALL: Never write today's todo without cross-checking history first.** If a task was already done in any previous file, it does not get carried over.
4. **Stale tagging** — when carrying over to a new day, if a task was already pending in the previous day's file AND in the 2-days-ago file, mark it with `⚠️` in the Pending Details table as stale
5. **Task updates via chat** — user can say "nomor X done" or "done #3" to mark complete; check it off in the file
6. **Pending Details table** — maintain a table showing each pending task with Origin (Day N / New) and Stale status (No / Yes)
7. **Cron reminders** — KII uses cron jobs with `no_agent=True` + scripts that send directly via Telegram Bot API curl calls

## File Template

```markdown
# To-Do List — YYYY-MM-DD (Day)

## Tasks

- [ ] 1. Task name
- [x] 2. Task done

## Status

- Done: #2
- Pending: #1

## Pending Details

| # | Task | Origin | Stale |
|---|------|--------|-------|
| 1 | Task name | New / Day N | No / Yes |

## Notes

- Created: YYYY-MM-DD
- Updated: YYYY-MM-DD (description)

## Example
See references/sample-todo.md for a sample showing in-progress (~), done (x), and pending ([ ]) tasks with proper status tracking and stale tagging.
```

## Project Planning Workflow (KII Pattern)

When KII asks for brainstorming/planning (not immediate execution):

1. **Research first** — Web search for market data, competitors, demand signals
2. **Validate problem** — Is it universal? Will people pay? What's the competition?
3. **Present options** — Give 3-5 ranked alternatives with pros/cons
4. **Get alignment** — Confirm direction before detailed planning
5. **Write plan to file** — Save to `/root/projects/<project-name>/PLAN.md` or similar
6. **Send to Topic Coding** — Use thread 1116, NOT Topic Trading (334)
7. **Create todo items** — Break plan into trackable tasks in daily worklist

**Format:** Keep plans structured but not verbose. KII prefers:
- Architecture diagram (ASCII/emoji)
- Tech stack table
- Week-by-week roadmap
- Monetization table
- Competitive comparison
- Todo checklist at the end

When updating (marking done, adding, removing):

1. Read today's file
2. Apply the change
3. Update Status counts
4. Update Pending Details table
5. Update the "Updated" line in Notes

## Critical Pitfall: No Done-Task Duplication Across Days

**NEVER carry over a task that is already marked `[x]` done in ANY previous file.** Before writing today's todo, scan all recent files (3-5 days back) with `grep -l "TASK_NAME" /root/todo-*.md` or read each file individually. If a task appears as `[x]` in any past file, it is COMPLETE and must not reappear. Only `[ ]` (pending) and `[~]` (in-progress) tasks get carried over.

## Tasks from External Channels (Cron Jobs, Topic Bisnis)

Tasks may be created by cron jobs or other agents and written directly to the todo file. When KII says "cek todo hari ini":

1. **Read the local file first** — `/root/todo-YYYY-MM-DD.md`
2. **Show what's there** — don't try to fetch from Telegram topics or external systems
3. **If KII mentions tasks from another channel** — he'll tell you what to add/remove
4. **KII curates generated tasks** — cron jobs may create 5 tasks, KII may remove 3. This is normal.
5. **Never try to access Telegram topic history** to "discover" tasks — KII will tell you directly

### When KII Explicitly Asks to Check a Telegram Topic

Sometimes KII will DIRECTLY TELL you to check messages from a specific topic (e.g., "cek kiriman bulan Juni di topic Bisnis 334"). When this happens:

1. **Use `session_search`** with the topic filter and date range — e.g., `session_search(query="task todo Juni 2026", sort="newest")`
2. **Filter for actionable items** — ignore conversational messages, focus on task-creating messages
3. **Present a filtered summary** — KII said "task-task yang Juni aja yang lu inventarisir" — give him the task list, not the conversation
4. **Don't over-explain** — KII said "gak usah sama lu mulu soalnya gak relate" — just give the relevant tasks, not meta-commentary about what you found

**Pitfall (Jun 19, 2026):** KII asked to check topic Bisnis for June tasks. Agent tried session search but didn't filter properly — returned too much noise. KII had to repeat the request multiple times. When KII gives a specific instruction like "cek topic X for month Y", do it immediately with `session_search`, filter for tasks/action items, and present clean results.

### Reconciling `todo` Tool Entries with File-Based Tracking

Some cron jobs use the `todo` tool to create tasks. These entries are separate from the `/root/todo-YYYY-MM-DD.md` file:

1. **The file is the source of truth** — always show the file contents first
2. **`todo` tool entries may not appear in the file** — if KII says a task was created but it's not in the file, check if it was created via `todo` tool
3. **When in doubt, ask KII** — "I see X in the file, but Y was mentioned. Should I add Y to the file?"

## 🔴 Todo File Is Source of Truth — Read It First, Always

When KII says "cek todo" or "cek todo hari ini":
1. Run `TZ='Asia/Jakarta' date +%Y-%m-%d` to get today's date
2. Read `/root/todo-YYYY-MM-DD.md` — this is the SINGLE SOURCE OF TRUTH
3. Show the summary from that file (In Progress, Pending, Done counts)
4. DO NOT try to access Telegram topics, session history, or external sources
5. If the file doesn't exist yet for today, say so and ask if KII wants to create one

**Pitfall (Jun 21, 2026):** KII asked "hasil brief tadi pagi yang lu kirim kan menghasilkan todo untuk hari ini ya?" — OWL tried to search session history and couldn't find it. The answer was ALREADY in the local todo file `/root/todo-2026-06-21.md`. Just read the file.

**Pitfall (Jun 19, 2026):** KII said "cek todo hari ini" — agent tried to search session history and said "I can't access topic Bisnis." The answer was already in the local todo file. Just read it.

## 🔴 CRITICAL: Always Carry Over + Show Full Summary on New Day

**When KII sends a task on a new day, the agent MUST:**

1. **Read the previous day's todo file** (`/root/todo-YESTERDAY.md`) BEFORE writing anything
2. **Extract all non-done tasks** (`[ ]` pending + `[~]` in-progress) — these are carry-over
3. **Create today's file** with carry-over tasks FIRST, then new tasks appended
**Step 4: Send a summary showing ALL tasks — carry-over AND new — in one combined view. Also explicitly ask: "Carry-over dari kemarin, ada yang sudah done?:" and list stale `[~]` tasks so KII can correct status before work begins.**
**Step 5: Wait for KII's response about stale carry-over tasks before finalizing.**
5. **NEVER create a fresh todo with only the new task** — leaving out carry-over pending tasks is a bug

**Example flow when KII says "Todo hari ini: UAT Amman":**
```
Step 1: Read /root/todo-2026-06-01.md
Step 2: Find pending/in-progress: "Buat ~/projects [~]", "Buat project playbook [~]", "Aktifkan SQLite FTS [ ]", "RAG/vector search [ ]"
Step 3: Write /root/todo-2026-06-02.md with those 4 carry-over + "UAT Amman" as new task
Step 4: Reply with summary showing ALL 5 tasks (4 carry-over + 1 new)
```

**If carry-over is missed**, KII will call it out. When that happens:
- Acknowledge the mistake
- Read the previous day's file immediately
- Rebuild today's file with the correct carry-over
- Re-send the complete summary

## Pitfall: Stale/Future Todo Files

Sometimes todo files exist for dates that haven't happened yet (e.g., `todo-2026-06-04.md` created during a session on May 31). When reading/writing, ALWAYS use `TZ='Asia/Jakarta' date +%Y-%m-%d` to get the REAL today's date. Never assume from conversation context or system prompt timestamp.

**When carrying over pending tasks to a new day's file:** read only yesterday and 2-days-ago files. Do NOT carry tasks from a "future" file created in a previous session — those tasks likely already exist in today's file or were handled separately.

## 🔴 CRITICAL: Verify Stale Tasks Before Finalizing Carry-Over

When carrying over tasks that are marked `[~]` (in-progress) or have been pending for 3+ days:

1. **ALWAYS confirm with the user** before finalizing — explicitly list stale carry-over tasks and ask "Statusnya masih sama, ada yang sudah done?"
2. **NEVER blindly carry over `[~]` tasks** — KII often completes tasks between sessions (especially `[~]` which are actively worked on). The todo file in the DB may be stale.
3. **KII's Flutter/mobile tasks** are especially prone to this — KII manages that code himself and frequently finishes between OWL todo sessions.
4. If KII says a task is already done from a previous day, mark it `[x]` in today's file immediately — do another session to mark it done.

**Pitfall example (Jun 18, 2026):** Carried over "Flutter: payment flow integration" as `[~]` in-progress from Jun 17 file. KII had already completed it on Jun 17. Result: KII called it out as "ini udah Done kenapa masih in progress?" — the verification step was skipped.

## 🔴 When KII Says "Cek Todo" — Read the File First, Nothing Else

**When KII asks to "cek todo" or "cek todo hari ini":**

1. **FIRST**: Run `TZ='Asia/Jakarta' date +%Y-%m-%d` to get today's date
2. **SECOND**: Read `/root/todo-YYYY-MM-DD.md` — this is the single source of truth
3. **THIRD**: Show the summary from that file (In Progress, Pending, Done counts)
4. **DO NOT** try to access Telegram topics, session history from other threads, or external sources — the todo file IS the inventory
5. **DO NOT** say "I can't access topic X" — just read the file and show what's there
6. If the file doesn't exist yet for today, say so and ask if KII wants to create one (carry over from yesterday)

**Pitfall example (Jun 19, 2026):** KII said "cek todo hari ini" — agent tried to search session history and said "I can't access topic Bisnis." KII was frustrated because the answer was already in the local todo file. The file had been created earlier in the same session. Just read it.

**Second pitfall example (Jun 19, 2026):** KII said "tadi ada dari topic bisnis yang create todo" — agent again tried to access Telegram topics. The correct response: read the local file, show what's there, and if KII mentions tasks from another channel, he'll tell you what to add. Don't try to fetch from external systems.

**Third pitfall example (Jun 19, 2026):** KII explicitly asked to "cek kiriman bulan Juni di topic Bisnis 334" — this is a DIRECT INSTRUCTION to check external sources. Use `session_search` immediately with appropriate query and date filter. Don't say "I can't access" — KII already knows what's possible, he's telling you what to do.

**KII's intent when saying "cek todo":** Show me what's in the todo file. That's it. Don't overthink — UNLESS KII explicitly asks to check another source (like a Telegram topic). In that case, use `session_search` to find relevant sessions and filter for tasks.

## 🔴 KII's Communication Style for Todo

- **Concise, numbers first** — don't over-explain or add meta-commentary
- **"Gak usah sama lu mulu"** — KII doesn't want to hear about your process, just the results
- **When presenting filtered results** — just list the tasks, don't explain why each one was included/excluded
- **When KII gives a specific filter** (e.g., "task-task yang Juni aja") — apply the filter silently and present results

## Date auto-generation (CRITICAL PITFALL)

**NEVER hardcode dates.** Always execute:
```
TZ='Asia/Jakarta' date +%Y-%m-%d
```
to get today's date before creating or updating any todo file. Do NOT guess or assume the date from the conversation history or system prompt.

**GOTCHA — System prompt date ≠ today's date:** The `Conversation started: Friday, May 29, 2026` line in the system prompt may be STALE. ALWAYS run `TZ='Asia/Jakarta' date +%Y-%m-%d` fresh — never trust the session start timestamp.

## Script Parsing Pitfalls

The morning/evening reminder scripts (`scripts/todo-reminder-morning.sh`, `scripts/todo-reminder-evening.sh`) must:

1. **Parse only the `## Tasks` section** — use `awk '/^## Tasks/{found=1; next} /^## /{found=0} found'` to extract tasks. Never grep the whole file, or you'll pick up lines from other sections.
2. **Clean task names properly** — use `sed 's/^- \[.\] [0-9]*\. //'` to strip the `- [ ] N. ` prefix. A bare `sed 's/^- \[ \\] //'` leaves the number and dot in the output.
3. **Count reliably** — use `grep -c .` with fallback `|| echo 0`. Empty variables should count as 0, not 1.
4. **Empty file check** — if no todo file exists for today, send "No to-do list today" message and exit.

## Telegram Topic Delivery

Cron `deliver=local` + Bot API direct via curl (Approach B). Never use `deliver=telegram:...` with `no_agent=true` — the wrapper text is unavoidable.

## Trading vs Coding Delivery Split

KII uses separate Telegram topics for different classes of work:
- **Trading signals / XAUUSD operational updates** → Topic Trading (`334`)
- **Planning / dev updates / code review / brainstorming** → Topic Coding (`1116`)
- **General reminders / worklist notifications** → Topic Notifikasi (`5`)

**Pitfall:** Do not send project plans into Trading just because the session also mentions trading elsewhere. Match the topic to the intent of the message.

Topic delivery requires **numeric** chat_id + message_thread_id:

### 🔴 Known Topic IDs (MyAssistant24/7 group — chat_id: -1003966561389)

| Topic | Thread ID | Use For |
|---|---|---|
| **Notifikasi** | 5 | Todo reminders, daily summaries, cron notifications |
| **Trading** | 334 | XAUUSD signals, trading alerts — **NEVER send project plans here** |
| **Coding** | 1116 | Project plans, dev updates, code reviews, brainstorming results |

**PITFALL:** Always double-check the target topic before sending. Project plans and dev discussion → Topic Coding (1116). Trading signals → Topic Trading (334). General notifications → Topic Notifikasi (5).

- ✅ `CHAT_ID="-1003966561389"` `THREAD_ID="5"` → Topic Notifikasi
- ✅ `CHAT_ID="-1003966561389"` `THREAD_ID="1116"` → Topic Coding
- ✅ `CHAT_ID="-1003966561389"` `THREAD_ID="334"` → Topic Trading
- ❌ Named topic references don't work in curl — resolve numeric IDs via `send_message(action='list')` first
- If a send fails with "Could not resolve", retry with the numeric `chat_id:thread_id` format

## Done-Task Carry-Over Rule

**NEVER carry over tasks already marked `[x]` in ANY previous file.** When building today's todo:
1. Read the immediately previous day's file — only carry `[ ]` and `[~]` tasks
2. `[x]` tasks stay in old files as history, never reappear
3. If a user explicitly asks to re-add a done task, rewrite it as a NEW task with a new number (don't reuse the `[x]` checkmark)
4. When user provides a list that mixes done and pending (e.g., from an old todo), mark the done ones as `[x]` immediately in today's file — don't show them as pending in summaries

## Cron Delivery Architecture — CRITICAL GOTCHA

There are TWO approaches. Use **Approach B** (Bot API direct).

### ❌ APPROACH A: stdout + Hermes cron delivery (BROKEN — adds wrapper)

Setting `deliver: telegram:<chat_id>:<thread_id>` with `no_agent: true` causes Hermes to **wrap script stdout** with:

```
Cronjob Response: <job name>
(job_id: ...)
-------------
<actual script output>
To stop or manage this job, send me a new message...
```

**There is NO way to suppress this wrapper.** Do not use this approach.

### ✅ APPROACH B: Bot API Direct via curl (CLEAN — no wrapper)

Set `delivery: "local"` on the cron job (so Hermes doesn't send anywhere), and have the script send directly via `curl` to Telegram Bot API.

**Cron job config:**
```json
{
  "action": "create",
  "name": "To-Do Reminder Pagi",
  "schedule": "30 8 * * *",
  "no_agent": true,
  "script": "todo-reminder-morning.sh",
  "deliver": "local",
  "enabled_toolsets": []
}
```

**Script approach:**
```bash
#!/bin/bash
source /root/.hermes/.env   # reads TELEGRAM_BOT_TOKEN
CHAT_ID="-1003966561389"
THREAD_ID="5"
# ... parse todo file, build $MSG ...
curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
  -d "chat_id=${CHAT_ID}" \
  -d "message_thread_id=${THREAD_ID}" \
  --data-urlencode "text=${MSG}" > /dev/null
```

**Key points:**
- `source /root/.hermes/.env` to read `TELEGRAM_BOT_TOKEN` from env file — never hardcode tokens in scripts
- `deliver: "local"` prevents Hermes from also sending script stdout → no double messages
- Redirect curl to `/dev/null` so script stdout stays clean

## External Task Append (Cron Integration)
## External Task Append (Cron Integration)

When other cron jobs or automated processes need to add tasks to today's todo:

1. **Get today's date:** `TZ='Asia/Jakarta' date +%Y-%m-%d`
2. **Append to `/root/todo-YYYY-MM-DD.md`** under `## Tasks` section
3. **Update `## Status`** counts (Pending +1)
4. **Update `## Pending Details`** table with new row (Origin: New, Stale: No)
5. **Do NOT send a separate notification** — the existing `To-Do Reminder Pagi` (08:30) and `To-Do Reminder Malam` (20:00) scripts automatically pick up all tasks in the file. Sending a duplicate notification causes double messages.

**Example append format:**
```markdown
- [ ] Follow up kategori [KATEGORI] di area [AREA] — target [N] kontak
```

**Integration check tasks:** When using `cross-stack-integration-check` skill, append discovered gaps as tasks with Origin: "Integration Check". Mark each task with priority emoji (🔴 critical, 🟡 warning, 🟠 mismatch) and owner tag (Backend/Flutter) so KII can filter by ownership.

**Integration Check Tasks:**
When running `cross-stack-integration-check` skill, append discovered gaps as tasks with Origin: "Integration Check". Group by priority (🔴 Critical, 🟡 Warning, 🟠 Mismatch) and add a `## Integration Check Results` section header to separate them from regular tasks.

**Pitfall:** External integrations should only append to the file. Let the existing reminder scripts handle all notifications.

## 🔴 PITFALL: Concurrent Writes from Subagents

When multiple agents/subagents write to the same todo file simultaneously:

1. **Always READ the file first** before writing — check for existing sections
2. **Merge into existing structure** — add new tasks under the existing `## Tasks` section, update existing `## Status` counts, add rows to existing `## Pending Details` table
3. **Never create duplicate sections** — a second `## Status` or `## Pending Details` header corrupts the file and breaks the reminder scripts
4. **If you see a `_warning` about sibling modification** — re-read the file, then merge your changes into the latest version
5. **If the file has duplicate sections** — clean up by merging into a single coherent structure before proceeding

**Pitfall example (Jun 19, 2026):** A subagent appended integration check tasks with a second `## Status` section and second `## Pending Details` table. The file ended up with two Status sections and two Pending Details tables. The reminder scripts would parse the wrong section. The main agent had to rebuild the entire file to fix it.

## Cron Job Tool Restrictions

Cron job agents with `no_agent: true` run with NO toolsets. Only the script executes. All file operations must be done via shell commands in the script itself.

## Stale Tagging Workflow

After carry-over, when building today's todo file:
1. Read **yesterday's** file — tasks carried from "yesterday" get `Origin: Carried (1 day)`
2. Read **2-days-ago** file — tasks carried from "2 days ago" get `⚠️` and `Stale: Yes`
3. A task becomes stale after **2 full days** of being pending
4. Format in Pending Details table: `⚠️ Stale` for stale tasks, `No` for fresh ones

## Script Parsing Pitfalls (CRITICAL)

The reminder scripts parse `todo-YYYY-MM-DD.md`. These pitfalls have caused broken output in production:

### 1. Parse ONLY the `## Tasks` section
**Wrong:** `grep '^\- \[ \]' "$FILE"` — matches lines in ANY section (Notes, Pending Details table, etc.)
**Right:** Use awk to isolate the section first:
```bash
TASKS_SECTION=$(awk '/^## Tasks/{found=1; next} /^## /{found=0} found' "$FILE")
PENDING=$(echo "$TASKS_SECTION" | grep '^\- \[ \]' | sed 's/^- \[ \] [0-9]*\. //' | grep -v "^$")
```

### 2. Strip task prefix correctly
**Wrong:** `sed 's/^- \[ \\] //'` — leaves the number (e.g., "1. Buat quotation...")
**Right:** `sed 's/^- \[ \] [0-9]*\. //'`

### 3. Count non-empty lines safely
**Wrong:** `echo "$PENDING" | grep -c . || true` — returns 0 on empty but also on error
**Right:** `echo "$PENDING" | grep -c . 2>/dev/null || echo 0`

### 4. Bash if-syntax
**Wrong:** `if [ ! -f "$FILE" then` — missing semicolon
**Right:** `if [ ! -f "$FILE" ]; then`

### 5. Evening script must exist
Both `scripts/todo-reminder-morning.sh` AND `scripts/todo-reminder-evening.sh` must exist.
If evening script is missing, the cron job (`To-Do Reminder Malam`) will fail silently.
The evening script should show "Done Today" FIRST (recap style), then pending/in-progress.

## Cron Reminder Languages: English Only

Both reminders use **English only** (no Indonesian/mix):

- Morning header: `To-Do Today — {Day}, {dd Month yyyy}`
- Evening header: `Summary To-Do Night — {Day}, {dd Month yyyy}`
- Section headers: `Done Today:`, `In Progress:`, `Pending:`
- Morning closing: `Have a productive day!`
- Evening closing: `Incomplete tasks carried over to tomorrow. Good night!`
- Summary line: `Summary: N done / N pending / N in progress`
- Empty file morning: `No to-do list today. Send tasks to OWL!`
- Empty file evening: `No to-do list today. Good night!`

**NOTE:** Previous versions used Indonesian. KII explicitly requested English on 2026-05-29.

## 🔴 In-Chat Summary Format: English Only

When sending a todo summary to Telegram (via `send_message`), **always use English** — same format as cron scripts:

```
📋 To-Do Today — Tuesday, June 02, 2026

🔄 In Progress:
• Task name

⬜ Pending:
• Task name

📊 Summary: N done / N pending / N in progress
```

- Date format: `{Day}, {Month} {dd}, {yyyy}` (e.g., "Tuesday, June 02, 2026")
- Do NOT use Indonesian words like "Hari Ini", "Selesai", "Pending" → must be "Done", "In Progress", "Pending"

## 🔴 Task Granularity: Split Compound Tasks

When a task combines two distinct deliverables, split it into separate items:

- **Bad:** `SSL + Deploy` — is this backend SSL? Mobile APK deploy? Both?
- **Good:** `3a. SSL untuk API Backend` + `3b. Build Flutter APK + Deploy ke Play Store`

## 🔴 Never Auto-Mark Done Based on Time

**NEVER mark a task as `[x]` done just because the scheduled time has passed.** A task is only done when KII explicitly says it's done (e.g., "done #3", "nomor 5 selesai", "mark done").

If KII only asks to edit/rename a task, do ONLY the rename — do NOT change the status.

## 🔴 Bulk Done Updates — Verify EVERY Task Marked Done

When KII lists multiple tasks to mark done (e.g., "6, 7, 8, 9 done" or "task X through Y done"):

1. **Apply the status change to file FIRST, then send the summary.** Don't just list changes in the summary without updating the file.
2. **Double-check that EVERY task in the list is meant to be done.** If KII lists "tasks #6-15 done", all of them move to `[x]` — but if KII later corrects that one task should still be In Progress, revert that single task immediately WITHOUT re-asking.
3. **Pitfall (Jun 19, 2026):** KII said "update #6, #7, #8-15 to Done". Task #5 was listed at the start of the conversation but was NOT meant to be done — it was still In Progress. The mistake was treating the entire pending/done list as a flat range. Always verify: is the task KII mentioned actually done, or was it just nearby in the list?

## 🔴 Pause and Confirm When KII Questions a Task

When KII questions whether to do a task (e.g., "task #27 enggak ya?", "jangan ngoding dulu", "atau gimana?"):

1. **STOP coding immediately** — do not proceed with the task in question
2. **Explain why** the task might need to be held (e.g., mobile-side dependency, production keys not ready, KII manages that code)
3. **Ask for confirmation** before proceeding — KII wants to align before execution
4. **Suggest alternatives** — offer other tasks that can be worked on now

**Common hold patterns:**
- Tasks that touch `mobile/` code → KII manages mobile, don't touch
- Tasks requiring production API keys → hold until KII provides keys
- Testing/QA tasks → usually KII's domain after features are done
- Payment integration (Midtrans/Stripe) → hold until production keys ready

**🔴 Security rule for API keys:**
- NEVER paste real API keys (Midtrans, Firebase, Stripe, etc.) into the agent session in code or `.env` edits — the key can leak in logs, history, or session transcripts
- When KII provides real keys, respond with the exact manual steps (edit `.env` + restart) and do NOT apply them via agent
- Always let KII manually set secrets: `nano .env` → edit → `docker-compose restart api`

**PITFALL:** Do not auto-skip or auto-hold tasks without telling KII. Always communicate which tasks are held and why, then ask what to work on next.

## Telegram Topic Notifikasi Delivery

When sending todo summaries to Topic Notifikasi:
- **Target**: `telegram:MyAssistant24/7 / topic 5` (resolved via `send_message(action='list')`)
- **Chat ID**: `-1003966561389`, **Thread ID**: `5`
- Use `send_message(target='telegram:MyAssistant24/7 / topic 5', message='...')` directly

## Support Files

- `references/second-brain-project.md` — Second Brain project reference (architecture, roadmap, monetization)
- `references/subtrack-id-project.md` — SubTrack ID project reference (API endpoints, deployment, constraints)
- `references/memory-tool-gotchas.md` — MEMORY.md/USER.md management pitfalls (drift recovery, capacity limits, § delimiter)
- `references/todo-checklist.md` — Todo checklist patterns
- `references/notification-format.md` — Notification format reference
- `references/midtrans-integration.md` — Midtrans Snap API integration reference (token generation, webhook signature, idempotency)

- `scripts/todo-reminder-morning.sh` — morning reminder (08:30 WIB), Bot API direct
- `scripts/todo-reminder-evening.sh` — evening recap (20:00 WIB), Bot API direct
- **Both must be kept in sync** — if one is updated (parsing logic, Bot API call), update the other too.
- **Both must be executable** — `chmod +x` after any edit.
- **Test after edits** — run `bash -n <script>` for syntax, then dry-run the parsing logic before relying on cron.
- `references/memory-tool-gotchas.md` — MEMORY.md/USER.md management pitfalls (drift recovery, capacity limits, § delimiter)
