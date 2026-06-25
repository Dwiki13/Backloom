# Scroll-Depth Gating for Conversion Tracking

## Problem
Google Ads conversion tracking fires on every WA button click — including users who haven't seen pricing or services. This inflates conversion count and makes CPA unreliable.

## Solution
Only fire Google Ads conversion if user has scrolled far enough to have seen the pricing section (≥40% scroll depth).

## Implementation

### Edit `trackWAConversion()` in index.html

**BEFORE:**
```javascript
window.trackWAConversion = function (label) {
  gtag('event', 'conversion', {
    'send_to': 'AW-XXXXXXXXX/XXXXXXXXXXXXXXXXXXXX',
    'event_callback': function () { }
  });
  gtag('event', 'wa_click', { event_category: 'lead', event_label: label || 'unknown' });
};
```

**AFTER:**
```javascript
window.trackWAConversion = function (label) {
  var scrollPercent = Math.round((window.scrollY / (document.body.scrollHeight - window.innerHeight)) * 100);

  // Always track GA4 event
  gtag('event', 'wa_click', {
    event_category: 'lead',
    event_label: label || 'unknown',
    scroll_depth: scrollPercent
  });

  // Only fire Google Ads conversion if scrolled >= 40%
  if (scrollPercent >= 40) {
    gtag('event', 'conversion', {
      'send_to': 'AW-XXXXXXXXX/XXXXXXXXXXXXXXXXXXXX',
      'event_callback': function () { }
    });
  }
};
```

### Optional: Scroll Depth Milestones
```javascript
var scrollMilestones = [25, 50, 75, 100];
var firedMilestones = [];
window.addEventListener('scroll', function () {
  var pct = Math.round((window.scrollY / (document.body.scrollHeight - window.innerHeight)) * 100);
  scrollMilestones.forEach(function (m) {
    if (pct >= m && firedMilestones.indexOf(m) === -1) {
      firedMilestones.push(m);
      gtag('event', 'scroll_depth', { event_category: 'engagement', event_label: m + '%' });
    }
  });
}, { passive: true });
```

## Deployment
```bash
# Backup
cp /var/www/devlokal.id/html/index.html /var/www/devlokal.id/html/index.html.bak.$(date +%s)

# Verify changes
grep -n "scrollPercent\|firedMilestones" /var/www/devlokal.id/html/index.html

# Reload web server (s6-supervise)
sudo kill -HUP $(cat /var/run/nginx.pid)
```

## Expected Results
- Conversion count drops 40-50%
- Data becomes accurate — only pricing-aware users counted
- Cost per conversion rises but reflects reality

## Threshold Guide
- 30% — Lenient (saw services)
- 40% — Standard (saw pricing)
- 50% — Strict (scrolled past pricing)