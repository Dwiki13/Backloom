# Next.js + Supabase Environment Variables Template

Copy to `.env.local` and fill in your values:

```env
NEXT_PUBLIC_SUPABASE_URL=https://YOUR_PROJECT_ID.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

## Where to find these values

1. Go to [supabase.com/dashboard](https://supabase.com/dashboard)
2. Select your project
3. Go to **Settings → API**
4. Copy **Project URL** and **anon public key**

## Important

- `.env.local` is git-ignored by default in Next.js projects
- The `NEXT_PUBLIC_` prefix is required for client-side access
- Never commit `.env.local` to git
- For Vercel deployment, add these as environment variables in project settings
