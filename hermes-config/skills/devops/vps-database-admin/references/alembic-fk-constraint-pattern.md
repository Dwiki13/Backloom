# Alembic FK Constraint Migration Pattern

## Problem

Hardcoded `op.drop_constraint()` calls break migrations when:
- Constraint doesn't exist (table created manually)
- Constraint has a different name than expected
- Migration was previously partially applied (InFailedSqlTransaction)

## Safe Pattern: Dynamic SQL Discovery

Use this template for any migration that needs to drop and recreate FK constraints:

```python
def upgrade() -> None:
    # Step 1: Drop all existing FK constraints dynamically (never fails)
    op.execute("""
        DO $$
        BEGIN
            -- Drop FKs on table_a
            FOR con IN
                SELECT constraint_name
                FROM information_schema.table_constraints
                WHERE table_name = 'table_a'
                  AND constraint_type = 'FOREIGN KEY'
            LOOP
                EXECUTE format('ALTER TABLE table_a DROP CONSTRAINT IF EXISTS %I', con.constraint_name);
            END LOOP;

            -- Drop FKs on table_b
            FOR con IN
                SELECT constraint_name
                FROM information_schema.table_constraints
                WHERE table_name = 'table_b'
                  AND constraint_type = 'FOREIGN KEY'
            LOOP
                EXECUTE format('ALTER TABLE table_b DROP CONSTRAINT IF EXISTS %I', con.constraint_name);
            END LOOP;
        END $$;
    """)

    # Step 2: Recreate with desired ondelete behavior
    op.create_foreign_key(
        'table_a_fk_name', 'table_a', 'referenced_table',
        ['fk_column'], ['id'], ondelete='CASCADE',
    )
    op.create_foreign_key(
        'table_b_fk_name', 'table_b', 'referenced_table',
        ['fk_column'], ['id'], ondelete='CASCADE',
    )


def downgrade() -> None:
    pass  # or reverse the changes
```

## Key Rules

1. **Never hardcode constraint names** in `op.drop_constraint()` — always discover via `information_schema`
2. **Use `DO $$` blocks** — `DROP CONSTRAINT IF EXISTS` inside a DO block won't abort the transaction
3. **No `DECLARE RECORD`** — `FOR con IN ...` auto-declares the loop variable in PostgreSQL
4. **One DO block per migration** — put all drops in a single `op.execute()` call
5. **Test with `-T` flag** — `docker-compose exec -T api alembic upgrade head`

## Stamping Migrations When Table Exists

If a table was created manually but the migration hasn't been applied:

```bash
# Stamp without running
docker-compose exec -T api alembic stamp <revision_id>

# Then apply remaining migrations
docker-compose exec -T api alembic upgrade head
```

## Real-World Example: family_payments + family_members

See migration files:
- `c1d2e3f4a5b6_add_ondelete_cascade_to_family_members.py`
- `d2e3f4a5b6c7_fix_all_fk_constraints_for_vault_delete.py`
- `f3a4b5c6d7e8_force_recreate_all_constraints.py`

All three originally hardcoded constraint names and broke. Fixed by replacing with dynamic SQL pattern above.
