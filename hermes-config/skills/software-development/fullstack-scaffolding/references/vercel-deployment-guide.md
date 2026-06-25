# Vercel Dashboard Deployment — Step by Step

## For Mobile Users (Termius/Browser)

### Step 1: Login
- Open browser → vercel.com → Login with your account

### Step 2: Import Project
- Click **"Add New"** → **"Project"**
- Find and select the repo (e.g., `Dwiki13/expense-tracker`)
- Click **"Import"**

### Step 3: Configure Environment Variables
Before deploying, scroll to **"Environment Variables"** and add:

| Key | Value |
|-----|-------|
| `NEXT_PUBLIC_SUPABASE_URL` | `https://<project-ref>.supabase.co` |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | `eyJhbG...` (full anon key from Supabase dashboard → Settings → API) |

### Step 4: Deploy
- Click **"Deploy"**
- Wait for build to complete (~2-3 minutes)
- Your app will be live at `https://<project-name>.vercel.app`

## Post-Deployment Verification

After deployment, test:
1. Visit the deployed URL
2. Register a new account
3. Add an expense
4. Check that data persists (Supabase connection working)

## Common Deployment Issues

| Issue | Fix |
|-------|-----|
| `Invalid API key` | Check `NEXT_PUBLIC_SUPABASE_ANON_KEY` is the **anon** key, not service_role |
| `Could not find table` | Run schema SQL in Supabase SQL Editor |
| Build fails | Check Next.js version compatibility; ensure `middleware.ts` is renamed to `proxy.ts` for Next.js 16 |
| Auth redirect loops | Ensure `site_url` in Supabase Auth settings matches the deployed URL |
