# OpenCode Workflow — Lessons Learned

## Date: June 15 2026

### What happened
- User requested fixes to family vault payment flow (owner view proof, etc.)
- Plan written to `.hermes/plans/family-vault-payment-fix.md`
- OpenCode was handed the plan with `--model opencode/deepseek-v4-flash-free`
- OpenCode correctly:
  - Added `proof = relationship("PaymentProof", back_populates="payment", uselist=False)` to `FamilyPayment`
  - Switched `PaymentProof.payment` from `backref` to `back_populates`
  - Added `joinedload(FamilyPayment.proof)` to both list and history endpoints
  - Added 2 new tests for proof fields
- OpenCode **incorrectly deleted** 4 endpoints: `mark_paid`, `confirm_payment`, `reject_payment`, `get_payment_summary`
  - These were ~200 lines of working code
- Fix: `git checkout HEAD -- app/routes/family.py` to restore, then manually apply only the needed changes

### Key Takeaway
**NEVER commit OpenCode output without reviewing the diff.** OpenCode can be aggressive about removing code it thinks is duplicate or unnecessary. Always:
1. Check `git diff` for each file
2. Verify critical endpoints still exist
3. Run the full test suite before committing

### Relationship Pattern: back_populates
When model A references model B and model B references model A, use `back_populates` instead of `backref` to avoid import order issues:

```python
# Model A (loaded first)
class FamilyPayment(Base):
    proof = relationship("PaymentProof", back_populates="payment", uselist=False)

# Model B (loaded second)
class PaymentProof(Base):
    payment = relationship("FamilyPayment", back_populates="proof")
```

`backref` didn't work because `FamilyPayment` is imported before `PaymentProof` in `app/models/__init__.py`, so the backref couldn't resolve the string `"PaymentProof"` at class definition time.
