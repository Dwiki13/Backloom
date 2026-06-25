# VPS Static Site Patterns for Google Ads Tracking

## Finding the Site

```bash
# Find static HTML sites on VPS
find /var/www -maxdepth 2 -name "index.html"

# Check existing tracking tags
grep -rn "gtag\|google\|GA4\|AW-\|googletagmanager\|dataLayer" /var/www/domain/html/

# Check JS for existing event tracking
grep -rn "gtag\|generate_lead\|conversion\|event" /var/www/domain/html/js/ /var/www/domain/html/main.js
```

## Common Architecture

Typical static HTML site on Nginx:
```
/var/www/domain/
├── html/
│   ├── index.html      ← main page, put GTM here
│   ├── main.js         ← event listeners, add conversion events here
│   ├── thank-you.html  ← conversion confirmation page
│   ├── css/
│   ├── js/
│   └── assets/
└── nginx.conf
```

## Adding Google Ads Conversion Tracking to Static HTML

### Step 1: Add GTM to index.html `<head>`

```html
<!-- Google Tag Manager -->
<script>(function(w,d,s,l,i){w[l]=w[l]||[];w[l].push({'gtm.start':
new Date().getTime(),event:'gtm.js'});var f=d.getElementsByTagName(s)[0],
j=d.createElement(s),dl=l!='dataLayer'?'&l='+l:'';j.async=true;j.src=
'https://www.googletagmanager.com/gtm.js?id='+i+dl;f.parentNode.insertBefore(j,f);
})(window,document,'script','dataLayer','GTM-XXXXXXX');</script>
<!-- End Google Tag Manager -->
```

### Step 2: Add conversion event on CTA click (in main.js)

```javascript
// Track WhatsApp button click as conversion
document.querySelectorAll('a[href*="wa.me"]').forEach(link => {
  link.addEventListener('click', () => {
    if (typeof gtag === 'function') {
      gtag('event', 'conversion', {
        send_to': 'AW-XXXXXXXXX/YYYYYYYYYY',
        value: 1.0,
        currency: 'IDR'
      });
    }
  });
});

// Track form submit as conversion
const form = document.querySelector('.kontak-form');
if (form) {
  form.addEventListener('submit', () => {
    if (typeof gtag === 'function') {
      gtag('event', 'conversion', {
        send_to': 'AW-XXXXXXXXX/YYYYYYYYYY',
        value: 1.0,
        currency: 'IDR'
      });
    }
  });
}
```

### Step 3: Reload Nginx

```bash
sudo systemctl reload nginx
```

## Key CTA Selectors for Indonesian Service Sites

- WhatsApp buttons: `a[href*="wa.me"]`
- Contact forms: `form.kontak-form`, `form.contact-form`
- Phone links: `a[href*="tel:"]`
- CTA buttons: `.btn-cta`, `.btn-whatsapp`

## Backup Before Edit

```bash
cp /var/www/domain/html/index.html /var/www/domain/html/index.html.bak.$(date +%s)
cp /var/www/domain/html/main.js /var/www/domain/html/main.js.bak.$(date +%s)
```
