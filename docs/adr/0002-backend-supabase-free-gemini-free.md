# 2. Backend: Supabase Free; AI: Gemini free tier

Date: 2026-10-20
Status: Accepted
Ticket: [Choose backend hosting and AI provider](https://github.com/enyiasonye/kitchenmate/issues/13)

## Context

KitchenMate has one user, the owner. The budget ceiling is $10–25/month, not counting the Apple Developer Program fee. The owner prefers to start on free tiers and upgrade only when a real limit is hit.

[Backend hosting options and cost](https://github.com/enyiasonye/kitchenmate/issues/8) recommended Supabase, with Cloudflare Workers Paid as the runner-up. The owner's existing Supabase org is on the Free plan with one active project, so KitchenMate fits as its second (and last) free project. [AI provider comparison and cost breakdown](https://github.com/enyiasonye/kitchenmate/issues/7) recommended Gemini Flash as primary, Claude Sonnet 5.5 as fallback and Groq Whisper for transcription. It also found that a small eval on real recipes, not price, should pick the final model.

[ADR 1](0001-client-stack-swiftui-iphone.md) made the client SwiftUI, so the Swift client and the TypeScript backend share no types.

## Decision

### Hosting

- **Supabase Free plan**, as a new project in the owner's existing org, region **us-east-2** (closest to the owner in Texas).
- Pausing after a week of inactivity is accepted. The daily Reminders sync and the Saturday Weekly Picks job keep the project active, and a paused project can be restored from the dashboard.
- **Upgrade to Pro only when a real limit is hit**: a pause that causes harm, imports exceeding Edge Function limits (150 s wall-clock, 2 s CPU), or the database or storage going past 500 MB or 1 GB.

### AI

- **Gemini Flash on the free tier** for extraction and grocery matching. Free-tier content may be used by Google to improve its products; what is sent (public recipes, captions, transcripts, cookbook photos, grocery item names) is not sensitive. Move to the paid tier (about $0.35–0.70/month) if rate limits bite.
- **Groq `whisper-large-v3-turbo` on the free plan** for transcription.
- **No live fallback provider in V1.** A failed or poor extraction shows in the import review form as "retry or fill in by hand". The backend calls AI through one interface and recipe fields are nullable, so adding Claude (via the API, which is billed separately from the owner's Claude Pro plan) is one adapter plus config.
- The specific model is confirmed by a small extraction eval on 10–20 real recipes per import type during the build.

### Client–backend contract

Supabase is the API layer; there is no separate API server.

1. **Plain data**: the Supabase Swift SDK reads and writes tables directly. **Row-level security on every table** is the security boundary.
2. **Atomic multi-table writes** (for example, accepting Weekly Picks into a Weekly Plan) are Postgres functions called via `rpc()`.
3. **Secrets and third parties** (Gemini, Groq, HEB, APNs, scheduled jobs) live only in Edge Functions, which validate their input. No API keys ship in the app.
4. **The schema is the contract**: it lives in `supabase/migrations` and Swift types are generated with `supabase gen types --lang=swift`. Edge Function request and response types are hand-written `Codable` structs mirroring the TypeScript types.
5. **Long jobs** (imports, HEB cart push) write progress to a status table that the client watches via Realtime.

## Consequences

- Expected running cost is about $0/month, rising to about $1 if Gemini's paid tier is needed. Supabase Pro ($25) is the main cost step if it is ever needed.
- The org's free project slots are both used.
- With no fallback provider, a Gemini outage stops imports until it recovers; recipes can still be entered by hand.
- Sending APNs directly from an Edge Function is undocumented by Supabase and still needs a spike; FCM is the fallback.
- Edge Functions cannot run native binaries such as `ffmpeg`. If import needs them, a small Fly.io machine (about $2–4/month) is the add-on; that is decided with the import pipeline.
- Supabase has no built-in offline sync. Local caching, offline use and optimistic writes are decided separately.

## Rejected

- **Supabase Pro ($25/month)**: uses the whole ceiling for limits a single user is unlikely to reach.
- **Cloudflare Workers**: no auth product or client SDK, so more to build; remains the runner-up if Supabase Free stops fitting.
- **Firebase, Fly.io, Railway, VPS, CloudKit**: see the hosting research; CloudKit cannot run server code or scheduled jobs.
- **OpenAPI spec with generated clients**: worth it with many endpoints or clients; KitchenMate has about five Edge Function endpoints and one client.
- **Claude Pro subscription as the AI provider**: the subscription does not include API access, and using its credentials from a server breaks Anthropic's terms.
