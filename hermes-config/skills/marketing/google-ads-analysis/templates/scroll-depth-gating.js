/**
 * Scroll-Depth Gated WhatsApp Conversion Tracking
 * 
 * Replace your existing trackWAConversion() function with this version.
 * Only fires Google Ads conversion when user has scrolled past threshold.
 * 
 * Prerequisites:
 * - gtag.js already loaded on page
 * - AW-XXXXXXXXX/YYYYYYYYYYYYYYY = your Google Ads conversion ID/label
 * 
 * Expected impact:
 * - Conversion count drops (e.g., 36 → 15-20)
 * - Conversions become more qualified
 * - Cost per conversion becomes more realistic
 */

// Replace existing trackWAConversion function
window.trackWAConversion = function (label) {
  var scrollPercent = Math.round(
    (window.scrollY / (document.body.scrollHeight - window.innerHeight)) * 100
  );
  
  // Always track GA4 event for analytics (regardless of scroll depth)
  gtag('event', 'wa_click', {
    event_category: 'lead',
    event_label: label || 'unknown',
    scroll_depth: scrollPercent
  });

  // Only fire Google Ads conversion if user scrolled >= 40%
  // (meaning they've seen pricing section and have real intent)
  if (scrollPercent >= 40) {
    gtag('event', 'conversion', {
      'send_to': 'AW-XXXXXXXXX/YYYYYYYYYYYYYYY',  // <-- REPLACE THIS
      'event_callback': function () { }
    });
  }
};

// Optional: Scroll depth milestone tracking for analytics
// Add this once, before </script>
var scrollMilestones = [25, 50, 75, 100];
var firedMilestones = [];
window.addEventListener('scroll', function () {
  var pct = Math.round(
    (window.scrollY / (document.body.scrollHeight - window.innerHeight)) * 100
  );
  scrollMilestones.forEach(function (m) {
    if (pct >= m && firedMilestones.indexOf(m) === -1) {
      firedMilestones.push(m);
      gtag('event', 'scroll_depth', {
        event_category: 'engagement',
        event_label: m + '%'
      });
    }
  });
}, { passive: true });
