# OpenPyXL Merged Cells — Robust Handler

## Problem
Writing to cells that fall within merged ranges causes:
```
AttributeError: 'MergedCell' object attribute 'value' is read-only
```

## ⚠️ Why `get_writable_cell()` is WRONG for multi-cell writes

The old approach resolved any cell to the top-left of its merged range. This fails when writing L, M, N in a L:N merge — all three writes go to the same cell (L), causing data overlap.

## ✅ Solution: `safe_write()` — Unmerge-on-write (Verified Working — May 2026)

```python
_merged_cache = {}

def safe_write(ws, cell_ref, value):
    """Write value to cell, unmerging any overlapping merged range first. Returns cell for chaining."""
    from openpyxl.utils import coordinate_to_tuple
    row, col = coordinate_to_tuple(cell_ref)
    for mr in list(ws.merged_cells.ranges):
        if mr.min_row <= row <= mr.max_row and mr.min_col <= col <= mr.max_col:
            key = f"{mr.min_row}-{mr.min_col}-{mr.max_row}-{mr.max_col}"
            if key not in _merged_cache:
                _merged_cache[key] = (mr.min_row, mr.min_col, mr.max_row, mr.max_col)
            ws.merged_cells.remove(mr)
    if (row, col) in ws._cells:
        del ws._cells[(row, col)]
    cell = ws.cell(row=row, column=col)
    cell.value = value
    return cell

def restore_merged_cells(ws):
    """Restore all previously unmerged ranges."""
    from openpyxl.utils import get_column_letter
    for key, (min_r, min_c, max_r, max_c) in _merged_cache.items():
        ws.merge_cells(f"{get_column_letter(min_c)}{min_r}:{get_column_letter(max_c)}{max_r}")
    _merged_cache.clear()
```

### Critical Implementation Details

1. **`list(ws.merged_cells.ranges)`** — iterating the live set causes `RuntimeError: Set changed size during iteration`
2. **`ws.merged_cells.remove(mr)`** — NOT `.discard()` (MultiCellRange doesn't have discard)
3. **`del ws._cells[(row, col)]`** — clears stale MergedCell from openpyxl's internal cache so `ws.cell()` returns a real Cell
4. For generate-once workflows (load → write → save → done), no need to call `restore_merged_cells()`