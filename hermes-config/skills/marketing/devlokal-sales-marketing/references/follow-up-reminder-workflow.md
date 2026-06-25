# Follow Up Reminder — Workflow Reference

## Trigger
Cron job mendeteksi warm lead yang sudah 3+ hari belum di follow up (notes: "bilang ke suami dulu", "pikir-pikir", "nanti dulu").

## Step-by-Step

### 1. Cek marketing-log.csv
```python
# Cari lead dengan stage "Warm" dan notes mengandung kata kunci FU
# yang sudah 3+ hari dari tanggal entry
```

### 2. Tulis pesan reminder ke file
```python
write_file(path='/tmp/followup-[nama-bisnis].txt', content="""🔥 Follow Up Reminder

[Nama Bisnis] (no WA) — [Area]
Status: Warm Lead — "[notes]" (X hari lalu)

Kirim follow up:
"[pesan follow up yang disesuaikan]"
""")
```

### 3. Kirim ke KII via hermes send
```bash
hermes send --to "telegram:-1003966561389:1264" --file /tmp/followup-[nama-bisnis].txt
```
**Penting:** Selalu tulis pesan ke file dulu, lalu kirim dengan `--file`. Jangan langsung inline di command line — karakter spesial (emoji, kutipan, newline) bisa menyebabkan parsing error.

### 4. Update CSV
Ubah stage dari "Warm" ke "Follow up 1" di `marketing-log.csv`:
```python
patch(
    path='/root/projects/devlokal-id/data/marketing-log.csv',
    old_string='2026-06-16,Widya Laundry,...,Warm,"Bilang ke suami dulu"',
    new_string='2026-06-16,Widya Laundry,...,Follow up 1,"Bilang ke suami dulu"'
)
```

## Contoh Pesan Follow Up per Situasi

### "Bilang ke suami dulu"
> Halo Pak/Bu [nama], selamat siang! Maaf ganggu lagi ya 🙏 Kemarin saya chat soal website untuk [bisnis bapak/ibu]. Apakah sudah sempat dibahas sama suami? Kalau mau lanjut, saya siap bantu kok 😊

### "Pikir-pikir" / "Nanti dulu"
> Halo Pak/Bu [nama], selamat [waktu]! Maaf ganggu lagi ya 🙏 Kemarin saya chat soal website untuk [bisnis]. Apakah sudah sempat dipikirin? Kalau ada pertanyaan atau mau tau lebih lanjut, saya siap bantu kok 😊

## Telegram Targets
| Target | Chat ID | Kegunaan |
|---|---|---|
| KII (Topic Sales/Marketing) | `telegram:-1003966561389:1264` | Follow up reminder, daily briefing |
| Topic 3 (Bisnis) | `telegram:-1003966561389:1264` | Daily marketing briefing |
