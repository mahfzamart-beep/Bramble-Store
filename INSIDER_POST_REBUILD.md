# Insider Post — Rebuild in Progress

## Status
- Development branch: `insider-post-dev`
- Base: `main` (Bramble production source preserved)
- Language: Bengali + English
- Audience: Bangladesh-first
- Prototype path: `src/insider-post/index.html`

## Safeguards
- This prototype is intentionally isolated in a new folder.
- No Bramble production files have been modified.
- No deployment, domain switch, or production publish is performed.
- Prototype copy/headlines are illustrative and are NOT real news.
- Newsroom CMS and authentication are not yet implemented.

## Planned phases
1. UX/design preview and mobile QA
2. News categories and article route structure
3. Secure admin authentication and CMS
4. Database and image-storage schema, RLS policies
5. Editorial workflow (draft, review, publish), attribution and source tracking
6. SEO metadata, sitemap, search, related stories, corrections/contact policies
7. Test preview deployment; release only after explicit approval

## Architecture decision pending
Current Vercel Hobby deployment has commercial-use limitations. Before production launch/monetization, choose a hosting setup compatible with intended use and verify current free-tier terms. Supabase project is currently inactive; database restore/activation and schema setup will be reviewed separately. No service has been reactivated and no costs incurred.
