## Insider Post — next approved phase
- Admin newsroom UI prototype: `src/insider-post/admin.html`
- CMS schema draft (NOT applied): `src/insider-post/schema.sql`
- Frontend demo uses temporary in-memory rows only. Refresh resets sample/demo rows.
- No database writes, uploads, auth, or publish actions occur.
- Next: verify Supabase project state; restore only if owner approves and costs/plan are clear; then implement auth, RLS, storage policy, and test end-to-end in staging.
