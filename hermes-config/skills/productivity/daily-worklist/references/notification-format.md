# Notification Format Reference

Output format of the two daily cron reminder scripts (`todo-reminder-morning.sh` and `todo-reminder-evening.sh`), AND the in-chat summaries sent via `send_message` to Topic Notifikasi.

## In-Chat Summary (via send_message to Topic Notifikasi)

**Target**: `telegram:MyAssistant24/7 / topic 5`

**Language**: English only — never Indonesian.

```
📋 To-Do Today — {Day}, {Month} {dd}, {yyyy}

🔄 In Progress:
• Task name

⬜ Pending:
• Task name

📊 Summary: N done / N pending / N in progress
```

- Date format: `Tuesday, June 02, 2026` (not "Selasa, 02 Juni 2026")
- Section order: In Progress → Pending
- Omit sections with 0 items
- Use bullet `•` for task items

## Morning Reminder (08:30 WIB)

Header: `To-Do Today`

```
To-Do Today — {Day}, {dd Month yyyy}

In Progress:
- {task}          <- only if any [~] items exist

Pending:
- {task}          <- only if any [ ] items exist

Done:
- {task}          <- only if any [x] items exist

Summary: {done} done / {pending} pending / {in_progress} in progress

Have a productive day!
```

Section order: In Progress → Pending → Done

Empty file output:
```
No to-do list today. Send tasks to OWL!
```

## Evening Recap (20:00 WIB)

Header: `Summary To-Do Night`

```
Summary To-Do Night — {Day}, {dd Month yyyy}

Done Today:
- {task}          <- only if any [x] items exist

In Progress:
- {task}          <- only if any [~] items exist

Pending:
- {task}          <- only if any [ ] items exist

Summary: {done} done / {pending} pending / {in_progress} in progress

Incomplete tasks carried over to tomorrow. Good night!
```

Section order: Done → In Progress → Pending (achievement-first recap)

Empty file output:
```
No to-do list today. Good night!
```

## Counting Rules

- Section headers (Done/In Progress/Pending) are **omitted entirely** if there are no matching items
- Counts in Summary line only include non-empty matched lines from the todo file
- Sections separated by single blank line, one blank line before closing line

## Script Implementation Notes

- Use `grep` to extract tasks by checkbox state: `[ ]` pending, `[~]` in progress, `[x]` done
- Use `printf` (not `echo`) for reliable newlines — `echo -e` may produce literal `\n` on some systems
- Use `awk 'NF>0'` to filter empty lines before printing
- Count lines with `awk 'NF>0{count++}END{print count+0}'`
- Scripts contain **zero curl calls** — output only, cron handles delivery
