# Next.js 16 + Supabase Pitfalls

## Next.js 16 Breaking: middleware.ts → proxy.ts

**Change:** `src/middleware.ts` is deprecated in Next.js 16. Renamed to `src/proxy.ts`.

**Correct proxy.ts pattern:**
```ts
import { type NextRequest } from 'next/server'

export function proxy(request: NextRequest) {
  // proxy logic
  return response
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico).*)'],
}
```

- Export a **named `proxy` function** (or default export). Not `middleware`.
- Read docs: `node_modules/next/dist/docs/01-app/03-api-reference/03-file-conventions/proxy.md`

## Supabase SSR with Next.js 16

**`cookies()` is async** — always `await`:
```ts
import { cookies } from 'next/headers'

export async function createClient() {
  const cookieStore = await cookies()  // must await
  return createServerClient(SUPABASE_URL, SUPABASE_KEY, {
    cookies: {
      getAll() { return cookieStore.getAll() },
      setAll(cookiesToSet) {
        try {
          cookiesToSet.forEach(({ name, value, options }) =>
            cookieStore.set(name, value, options)
          )
        } catch {
          // Server Component — cookies may not be mutable
        }
      },
    },
  })
}
```

**Key patterns:**
- `supabase.from('expenses').select('*, categories(name, icon, color)')` — joined relation returns `categories` as **object or array** depending on relationship. Handle both: `Array.isArray(categories) ? categories[0] : categories`
- Always use `.eq('field', value)` for filtering, never raw SQL in client calls.

## Recharts Tooltip Formatter

**Type error:** `Type '(value: number) => string' is not assignable to type 'Formatter<ValueType, NameType>'`

**Fix:**
```tsx
// ❌ Wrong
<Tooltip formatter={(value: number) => formatCurrency(value)} />

// ✅ Correct — let TypeScript infer, cast manually
<Tooltip formatter={(value) => formatCurrency(Number(value as number))} />
```

## TypeScript Interface for Supabase Relations

When Supabase returns joined data, the relation type can be inconsistent. Use a helper:

```ts
function getCategory(categories: { name: string }[] | { name: string } | null) {
  if (!categories) return null
  if (Array.isArray(categories)) return categories[0] || null
  return categories
}
```

## RLS Policies Pattern

Always create per-table RLS with these policies (minimum):
- `FOR SELECT USING (auth.uid() = user_id)`
- `FOR INSERT WITH CHECK (auth.uid() = user_id)`
- `FOR UPDATE USING (auth.uid() = user_id)`
- `FOR DELETE USING (auth.uid() = user_id)`

**Auto-create profile trigger:**
```sql
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name)
  VALUES (NEW.id, NEW.email, COALESCE(NEW.raw_user_meta_data->>'full_name', ''));
  -- Insert default categories, settings, etc.
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```
