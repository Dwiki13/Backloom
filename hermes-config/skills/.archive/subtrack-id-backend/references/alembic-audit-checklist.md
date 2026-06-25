# Alembic Audit Checklist — Read-Only DB Verification

Use this when asked to "verify Alembic" or "check DB matches models". **Read-only — never modify DB.**

## Steps

### 1. Migration Chain
```bash
docker-compose exec -T api alembic history --verbose
```
- Check chain is clean (no orphans, linear)
- Note the head revision

### 2. All Tables
```sql
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
ORDER BY table_name;
```

### 3. Column Comparison (per table)
```sql
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = '<table>'
ORDER BY ordinal_position;
```
Compare against Python model `__table__.columns`. Flag:
- Columns in model but missing in DB
- Columns in DB but missing in model
- Nullable mismatches

### 4. FK Constraints
```sql
SELECT tc.table_name, kcu.column_name,
       ccu.table_name AS fk_table, ccu.column_name AS fk_col,
       rc.delete_rule
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu ON ccu.constraint_name = tc.constraint_name
JOIN information_schema.referential_constraints rc ON rc.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' AND tc.table_schema = 'public'
ORDER BY tc.table_name;
```
Verify ON DELETE rules match model expectations (CASCADE for family relationships, SET NULL for optional refs).

### 5. Enum Values
```sql
SELECT t.typname, e.enumlabel
FROM pg_type t JOIN pg_enum e ON t.oid = e.enumtypid
WHERE t.typtype = 'e'
ORDER BY t.typname, e.enumsortorder;
```
Compare against Python enum `.value` attributes. **Values must be lowercase in PostgreSQL.**

### 6. Output Format
Present findings as:
- ✅ Clean sections
- ⚠️ Warnings (non-critical mismatches)
- ❌ Issues (critical problems)
- Summary: production-ready yes/no
