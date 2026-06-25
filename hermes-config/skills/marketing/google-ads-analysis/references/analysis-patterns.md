# Google Ads CSV Analysis Script Template

Use this Python script to quickly aggregate Google Ads CSV exports. Run via execute_code.

```python
import csv
import os
from collections import defaultdict

def parse_idr(value):
    """Parse IDR currency string like 'Rp51,429' to int"""
    return int(value.replace('Rp', '').replace(',', '').strip())

def read_csv(path):
    with open(path, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        return list(reader)

# Usage example:
# data_dir = '/tmp/google_ads'
# for fname in os.listdir(data_dir):
#     if fname.endswith('.csv'):
#         rows = read_csv(os.path.join(data_dir, fname))
#         print(f"\n=== {fname} ===")
#         for row in rows[:5]:
#             print(row)
```

## Key Analysis Patterns

### Keyword Efficiency Score
```
efficiency = (CTR * 100) / CPC
```
Higher = better relevance per rupiah spent.

### Waste Detection
Flag keywords where:
- Cost > Rp10,000 AND Clicks = 0 (expensive, no engagement)
- CTR < 2% AND Cost > Rp5,000 (irrelevant, burning budget)
- Match type = Broad AND CTR < 3% (too broad)

### Conversion Tracking Check
If ALL conversion values = 0.00, conversion tracking is NOT installed. This is the #1 priority fix.
