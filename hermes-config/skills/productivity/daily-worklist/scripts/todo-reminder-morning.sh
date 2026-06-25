#!/bin/bash
# To-Do Reminder Pagi (Morning) — Clean Telegram delivery
# Reads /root/todo-YYYY-MM-DD.md and sends formatted reminder via Bot API
#
# PITFALLS (see SKILL.md for details):
# - Parse ONLY ## Tasks section (awk isolation)
# - Strip "- [ ] N. " prefix properly (sed with [0-9]*\. )
# - Use "grep -c . 2>/dev/null || echo 0" for safe counting
# - Semicolon before "then" in if-statements

TODAY=$(TZ='Asia/Jakarta' date "+%A, %d %B %Y")
FILENAME=$(TZ='Asia/Jakarta' date +%Y-%m-%d)
FILE="/root/todo-${FILENAME}.md"

source /root/.hermes/.env
CHAT_ID="-1003966561389"
THREAD_ID="5"

if [ ! -f "$FILE" ]; then
  MSG="📋 No to-do list today. Send tasks to OWL!"
  curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -d "chat_id=${CHAT_ID}" \
    -d "message_thread_id=${THREAD_ID}" \
    --data-urlencode "text=${MSG}" > /dev/null
  exit 0
fi

# Parse only from ## Tasks section (stop at next ## header)
TASKS_SECTION=$(awk '/^## Tasks/{found=1; next} /^## /{found=0} found' "$FILE")

# Extract and clean task names (strip "- [ ] N. " prefix)
IN_PROGRESS=$(echo "$TASKS_SECTION" | grep '^\- \[~\]' | sed 's/^- \[~\] [0-9]*\. //' | grep -v "^$")
PENDING=$(echo "$TASKS_SECTION" | grep '^\- \[ \]' | sed 's/^- \[ \] [0-9]*\. //' | grep -v "^$")
DONE=$(echo "$TASKS_SECTION" | grep '^\- \[x\]' | sed 's/^- \[x\] [0-9]*\. //' | grep -v "^$")

# Count safely
IN_COUNT=$(echo "$IN_PROGRESS" | grep -c . 2>/dev/null || echo 0)
PEND_COUNT=$(echo "$PENDING" | grep -c . 2>/dev/null || echo 0)
DONE_COUNT=$(echo "$DONE" | grep -c . 2>/dev/null || echo 0)

# Build message
MSG="📋 To-Do Today — ${TODAY}"

if [ "$IN_COUNT" -gt 0 ]; then
  MSG="${MSG}

In Progress:"
  MSG="${MSG}
$(echo "$IN_PROGRESS" | while IFS= read -r line; do [ -n "$line" ] && echo "  🔄 ${line}"; done)"
fi

if [ "$PEND_COUNT" -gt 0 ]; then
  MSG="${MSG}

Pending:"
  MSG="${MSG}
$(echo "$PENDING" | while IFS= read -r line; do [ -n "$line" ] && echo "  ⬜ ${line}"; done)"
fi

if [ "$DONE_COUNT" -gt 0 ]; then
  MSG="${MSG}

Done Today:"
  MSG="${MSG}
$(echo "$DONE" | while IFS= read -r line; do [ -n "$line" ] && echo "  ✅ ${line}"; done)"
fi

MSG="${MSG}

Summary: ${DONE_COUNT} done / ${PEND_COUNT} pending / ${IN_COUNT} in progress
Have a productive day! 💪"

curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
  -d "chat_id=${CHAT_ID}" \
  -d "message_thread_id=${THREAD_ID}" \
  --data-urlencode "text=${MSG}" > /dev/null
