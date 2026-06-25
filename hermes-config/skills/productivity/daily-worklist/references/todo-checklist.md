# Checklist: Preventing Done-Task Duplication & Script Errors

## Before Writing Today's Todo
1. `TZ='Asia/Jakarta' date +%Y-%m-%d` → get REAL today's date
2. Read yesterday's file: `/root/todo-YESTERDAY.md`
3. Read 2-days-ago file: `/root/todo-2DAYSAGO.md`
4. For each task in those files:
   - `[x]` done → SKIP, never carry over
   - `[~]` in-progress → carry over
   - `[ ]` pending → carry over
5. STALE check: if task was pending in BOTH yesterday AND 2-days-ago → tag ⚠️

## Before Editing Reminder Scripts
1. Check `bash -n <script>` for syntax
2. Test parsing: run the awk+sed pipeline manually against a real todo file
3. Update BOTH morning and evening scripts together
4. `chmod +x` after edits
