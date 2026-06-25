# Google Ads — Meta Ads Transition Plan (June 2026)

## Current Status (June 19 2026)
- Google Ads fund: Rp 160,000 remaining (~5 days @ Rp 30rb/day)
- Total spend to date: Rp 420,030 (14 days)
- Conversions: 0 (funnel problem, not volume problem)
- High Priority fixes (negative keywords, conversion value, conversion window) set since June 16

## Decision
- Let Google Ads run until fund exhausted (~June 24)
- Pause Google Ads after fund runs out
- Landing page optimization needed before Meta Ads launch
- Meta Ads test after gajian (June 28): Rp 20-30rb/day for 7-14 days
- Compare CPL Meta vs Google, scale the cheaper one

## Pre-Meta Checklist
1. Fix landing page: testimonials, reduce form fields, add urgency
2. Set up FB Pixel + conversion tracking on devlokal.id
3. Verify Google Ads conversion tracking is working (value = Rp 1,500,000 for lead form, not default 1.00)
4. Prepare Meta Ads targeting: UMKM owners 25-45, Jabodetabek, interests: "pemilik usaha", "UMKM", "entrepreneur"

## Manual Outreach Data Format
KII sends raw table like:
```
Tanggal | Customer | Jenis UMKM | No Handphone | Lokasi | Keterangan | Response Y/N | Close | Income
```
OWL formats to marketing-log.csv:
```
date,name,category,phone,area,website_status,sent,response,stage,notes
2026-06-19,Dhelumière Studio,Salon,0812-9328-2975,Teluknaga Tangerang,no website,Sent,No response,Cold,WA terkirim
```

## Key Metrics to Track
- Google Ads: CPC, CTR, conversions, cost per lead
- Meta Ads: CPC, CPM, CTR, cost per lead, ROAS
- Manual outreach: response rate, warm rate, deal rate
