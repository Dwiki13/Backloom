# DevLokal Website Optimization & Meta Ads Reference

## Website: devlokal.id
- Stack: Static HTML/CSS/JS (no framework)
- Path: `/var/www/devlokal.id/html/index.html`
- WA number placeholder: `62WA_NUMBER` (replace with actual number)
- GA tracking: G-Y81TS75NGZ (already installed)
- Facebook Pixel: NOT yet installed (needed before running ads)

## Conversion Optimization Checklist (June 2026)

### Done ✅
- [x] Harga paket visible (Starter Rp 1.5jt / Standard Rp 2.5jt / Professional Rp 5.5jt)
- [x] Sticky WA button (`.wa-float` bottom-right)
- [x] Hero headline changed to pain-driven: "Bisnis Lo Udah Go Digital, Tapi Belum Punya Website?"
- [x] CTA changed: "WhatsApp Gua" → "Konsultasi Gratis →", "Lihat Paket" → "Lihat Paket & Harga →"
- [x] Portfolio section exists (Sevora & Co)
- [x] FAQ section with accordion
- [x] Contact form (nama, WA, kebutuhan)
- [x] Proses kerja section (4 steps)
- [x] Schema.org structured data (ProfessionalService + FAQPage)

### Pending ❌
- [ ] Facebook Pixel installation (CRITICAL — before any ads)
- [ ] Testimoni klien section (need content from KII)
- [ ] More portfolio projects (currently only 1, need 3-5 total)
- [ ] Blog/content section (SEO)

## Meta Ads Campaign Structure (Budget Mini — Rp 1.5jt/bulan)

### Campaign: Leads via WhatsApp
- Objective: Messages (WhatsApp)
- Budget: Rp 50.000/hari
- Ad Sets: Jakarta (broad 25-45, interest: UMKM/entrepreneur), Surabaya (same)
- Placements: FB Feed + IG Feed + IG Stories only
- Creative variants: Video testimoni, Before/After carousel, Price anchor

### Key Metrics to Monitor
- CPL (Cost per Lead): target < Rp 30.000
- CTR: target > 1%
- Frequency: kill if > 3 (creative fatigue)
- Kill rule: CPL > Rp 50.000 after 3 days → turn off ad set

### Scaling Path
1. Start: Rp 1.5jt/bulan (test market)
2. If CPL < Rp 30rb: scale to Rp 3jt/bulan
3. Add Google Search Ads for high-intent leads
4. Add retargeting (website visitors who didn't chat)

## ROI Calculation
- Harga website: Rp 1.5jt–5jt
- Cost per lead @ Rp 2jt budget: ~Rp 30.000
- Conversion rate 10% → cost per acquisition: ~Rp 300.000
- ROI: 5x–16x

## Platform Benchmarks (Indonesia, June 2026)
| Platform | CPM | CPC | CPL | Best For |
|----------|-----|-----|-----|----------|
| Meta Ads | 15-30rb | 1.5-4rb | 15-50rb | Awareness + Leads |
| Google Search | — | 3-10rb | 20-60rb | High-intent leads |
| TikTok Ads | 10-20rb | 1-3rb | — | B2C, less effective for B2B |

## Notes
- KII prefers discussing strategy before implementing changes
- Website edits must go through OpenCode workflow
- Backup before editing: `cp index.html index.html.bak.$(date +%s)`
