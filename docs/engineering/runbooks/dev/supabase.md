# Supabase Login, Corporate Auth UI, and Table Observability

## CLI Login (Non-Interactive)

Requirements:
- Supabase account + Personal Access Token
- Supabase CLI (macOS): `brew install supabase/tap/supabase`

Steps:
"""bash
# 1) Login without browser (token-only)
SUPABASE_ACCESS_TOKEN=<YOUR_TOKEN> supabase login --no-open

# 2) List projects (copy the project ref)
supabase projects list

# 3) Link this directory to a project (optional but recommended)
supabase link --project-ref <PROJECT_REF>

# 4) App environment (never commit secrets)
export SUPABASE_URL="https://<PROJECT_REF>.supabase.co"
export SUPABASE_ANON_KEY="<ANON_PUBLIC_KEY>"
# Optional (server-only):
# export SUPABASE_SERVICE_ROLE_KEY="<SERVICE_ROLE_KEY>"
"""

Helper script in this repo:
"""bash
./scripts/supabase_login.sh <YOUR_TOKEN>
# or
SUPABASE_ACCESS_TOKEN=<YOUR_TOKEN> ./scripts/supabase_login.sh
"""

## Serve a UI for Corporate Login

Use Supabase Auth UI or your own login page, backed by OAuth providers.

1) In Supabase Dashboard
- Authentication → Providers: enable e.g. Google (or your IdP)
- Configure OAuth app credentials; restrict to your company domain
- Authentication → URL settings: set Site URL and allowed Redirect URLs

2) Frontend (example: React)
- Install: `npm i @supabase/supabase-js @supabase/auth-ui-react @supabase/auth-ui-shared`
- Ensure `SUPABASE_URL` and `SUPABASE_ANON_KEY` are exposed to the frontend
- Render Auth UI (e.g., with Google button). Protect routes using session state

Notes
- For strict corporate-only access, enforce domain restriction in the OAuth provider
- For SAML/Entra/Okta (Enterprise), use Supabase SSO (SAML) setup

## Basic Table Observability (UI)

Use Supabase Studio (Table Editor):
- Hosted: open your project in the Supabase Dashboard → Table Editor
- CLI: `supabase projects list` and open from dashboard

Local stack (optional):
"""bash
# Start local Supabase (Docker required)
supabase start
# Open Studio
supabase open studio   # usually http://127.0.0.1:54323
# Inspect status / ports
supabase status
"""

With Studio you can:
- Browse tables/schemas/relations
- Inspect and edit rows
- View auth users and policies
- Run SQL via the editor

## Quick Verification
"""bash
# Verify CLI login
supabase projects list

# Verify app envs are set (example for web apps)
# SUPABASE_URL=https://<PROJECT_REF>.supabase.co
# SUPABASE_ANON_KEY=eyJhbGciOi...
"""
