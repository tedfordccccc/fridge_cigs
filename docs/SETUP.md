# Setup: accounts and keys

Everything here is free to start except Apple sign-in ($99/yr Apple Developer Program)
and Google Places beyond the monthly free usage. Dashboards move buttons around; if a
label doesn't match, search the dashboard for the bold words.

## Where things live

```
README.md          build brief
prototype/         source of truth for look, copy, scoring
tools/             wordmark + icon generators
docs/SETUP.md      this file
web/               the Next.js app (deploy this folder)
  supabase/migrations/   database schema + security rules
  supabase/tests/        RLS checks (npm run test:db, needs local Postgres)
  src/lib/scoring.ts     Crispiness math (npm test)
```

Run locally: `cd web && npm install && cp .env.example .env.local && npm run dev`, then open http://localhost:3000.

## 1. Supabase (database + sign-in): needed for step 2

1. Go to **supabase.com** → **Start your project** → sign in with GitHub.
2. **New project**. Name it `fridge-cig-report`, pick a region near you, and generate a
   database password (save it in a password manager; you rarely need it).
3. When it finishes: left sidebar → **SQL Editor** → **New query**. Paste all of
   `web/supabase/migrations/20261011000000_init.sql` and click **Run**. "Success. No rows returned" means it worked.
4. Left sidebar → **Project Settings** (gear) → **API Keys**. Copy the **Publishable key** (`sb_publishable_…`).
   Your **Project URL** is under **Project Settings → Data API** (or the **Connect** button at the top).
   Put both in `web/.env.local`:
   ```
   NEXT_PUBLIC_SUPABASE_URL=https://xxxx.supabase.co
   NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
   ```
   Do **not** use the **Secret** / `service_role` key anywhere in this app.
5. **Authentication → URL Configuration**: set **Site URL** to `http://localhost:3000` for now and add
   `http://localhost:3000/**` under **Redirect URLs**. (The live URL gets added after deploy.)

Then tell Claude "Supabase is set up." Don't paste the keys into chat: they go in `.env.local` and in Vercel.

## 2. Google sign-in: needed for step 2

1. **console.cloud.google.com** → project picker (top left) → **New project** → `fridge-cig-report`.
2. Search bar → **Google Auth Platform** → **Get started**. App name "Fridge Cig Report", your email,
   audience **External**. While testing, add yourself under **Audience → Test users**.
3. **Clients → Create client** → type **Web application**.
   - Authorized JavaScript origins: `http://localhost:3000`
   - Authorized redirect URIs: `https://<your-project-ref>.supabase.co/auth/v1/callback`
     (copy the exact URL from Supabase → **Authentication → Sign In / Providers → Google**)
4. Copy the **Client ID** and **Client secret** into that Supabase Google provider page, switch it on, **Save**.

## 3. Apple sign-in: optional, can come later

This needs the Apple Developer Program ($99/yr, developer.apple.com/programs). The suggestion is to launch with email +
Google, then add Apple before any App Store submission. When you're ready: Certificates, IDs & Profiles →
create a **Services ID** and a **Sign in with Apple key** → paste them into Supabase → **Sign In / Providers → Apple**.

## 4. Email magic links

These work out of the box, but Supabase's built-in mailer only sends a few emails per hour and is meant for
testing. Before inviting friends: make a free **resend.com** account, verify a domain you own, then fill in
Supabase → **Authentication → Emails → SMTP Settings** with Resend's SMTP details.

## 5. Google Places (establishment search): needed for step 3

Use the same Google Cloud project as above.
1. **Billing** → link a billing account (a card is required; Google's monthly free usage covers a small app).
   Then **Billing → Budgets & alerts** → create a $5 budget alert so nothing surprises you.
2. **APIs & Services → Library** → enable **Places API (New)** and **Maps JavaScript API**.
3. **APIs & Services → Credentials → Create credentials → API key**. Then edit it:
   - Application restrictions: **Websites** → `http://localhost:3000/*` (add the live URL later)
   - API restrictions: only the two APIs above
4. It goes in `web/.env.local` as `NEXT_PUBLIC_GOOGLE_MAPS_API_KEY=`. Browsers can see this key by design;
   the restrictions are what keep it safe.

## 6. Vercel (hosting): needed for deploy

1. **vercel.com** → sign up with GitHub → **Add New… → Project** → import `fridge_cigs`
   (if asked, give the Vercel GitHub app access to that repo).
2. **Root Directory** → **Edit** → choose `web`. Vercel detects the framework as Next.js.
3. **Environment Variables**: add the same keys as `.env.local`. **Deploy**.
4. Copy the live URL (e.g. `https://fridge-cig-report.vercel.app`) and add it to:
   the Supabase Site URL and Redirect URLs (`https://…/**`), the Google OAuth JavaScript origins, and the Places key's
   website restrictions.
5. Pick a domain without "Coke" in it (README §5).

## Making yourself an admin

After you sign in once: Supabase → **Authentication → Users** → copy your User UID → **SQL Editor**:
`insert into public.admins values ('<your-uid>');`
