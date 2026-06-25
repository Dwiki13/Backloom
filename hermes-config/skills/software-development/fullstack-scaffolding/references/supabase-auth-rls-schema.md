# Supabase Auth + RLS Schema Pattern

## Auto-create profile on signup

```sql
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', '')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

## RLS Policy Pattern (per-user data)

```sql
-- Enable RLS
ALTER TABLE public.my_table ENABLE ROW LEVEL SECURITY;

-- SELECT
CREATE POLICY "Users can view own data" ON public.my_table
  FOR SELECT USING (auth.uid() = user_id);

-- INSERT
CREATE POLICY "Users can insert own data" ON public.my_table
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- UPDATE
CREATE POLICY "Users can update own data" ON public.my_table
  FOR UPDATE USING (auth.uid() = user_id);

-- DELETE
CREATE POLICY "Users can delete own data" ON public.my_table
  FOR DELETE USING (auth.uid() = user_id);
```

## Key Rules

- Always `auth.uid() = user_id` for per-user tables
- INSERT policies use `WITH CHECK`, not `USING`
- Use `DROP POLICY IF EXISTS` before `CREATE POLICY` for idempotent migrations
- Drop + recreate triggers to update them
