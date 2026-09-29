# Backend hosting options and cost

Research for issue #8. All prices and limits retrieved **2026-09-29** from each provider's own pages unless marked otherwise. Prices in USD unless noted.

Claims are tagged:

- **[V]** verified on the provider's own page on the retrieval date (source linked).
- **[I]** inference or judgement by the researcher, not stated by a primary source.
- **[U]** could not be verified from a primary source; treat as an open question.

## Summary

- **Recommendation: Supabase** as the primary backend. It covers every need in one product (Postgres, storage, auth, cron, TypeScript functions), has official SDKs for both Swift and React Native, and the owner already knows it.
- **The cost depends on one fact I could not determine: what plan the owner's existing Supabase organization is on.**
  - Existing org is on **Pro**: adding KitchenMate as a second project costs about **$10/month** (one more Micro compute instance). This is the best case.
  - Starting on the **Free plan**: **$0/month**, but the project is paused after 1 week of inactivity and functions are limited to 150 s wall-clock. Workable while building; a risk in steady use.
  - A **new Pro org just for KitchenMate** is **$25/month**, which consumes the whole ceiling before any AI spend. In that case prefer the runner-up.
- **Runner-up: Cloudflare Workers Paid at $5/month** (Workers + D1 + R2 + Cron Triggers + Queues + Workflows). Cheapest always-on option with no pausing and the best long-job story, but it has no auth product, no client SDK, and no sync layer, so more must be hand-built.
- **Ruled out:** CloudKit as the backend (no server-side code or scheduled jobs; server keys reach only the public database), Fly Managed Postgres (from $38/month), Hetzner US (cheapest US server now about $20/month), a fresh Supabase Pro org if the ceiling is firm.
- **Neither recommended platform can run native binaries** (for example `ffmpeg` or `yt-dlp`). If recipe import from video needs them, add a small scale-to-zero container (Fly.io, about $2-4/month) alongside the primary. This is a decision for the import ticket.
- **Estimated total: $5-10/month for hosting**, leaving $15-20/month of the ceiling for AI usage (ticket #7). The $99/year Apple Developer Program fee ($8.25/month) is not included; whether it counts against the ceiling is an open question.

## Requirements recap

Single user. iPhone and Mac clients. Backend must provide: database, file storage (recipe images, possibly some video), scheduled jobs (weekly picks, daily work), APNs push, outbound calls to HEB and AI providers including possibly long-running import jobs, and auth for one user. Total budget $10-25/month including AI. Owner background is Node/TypeScript/Supabase. Client stack (SwiftUI or React Native) undecided.

## What sending an Apple push requires

This constrains every option, so it comes first.

- **[V]** APNs requires HTTP/2 with TLS 1.2 or later. Endpoints are `api.push.apple.com:443` (production) and `api.sandbox.push.apple.com:443` (development); port 2197 is an alternative. Requests are `POST /3/device/<device_token>` with an `apns-topic` header (the bundle ID). Payload maximum is 4 KB (5 KB for VoIP). Source: <https://developer.apple.com/documentation/usernotifications/sending-notification-requests-to-apns>
- **[V]** Token-based auth uses a `.p8` key from the developer account, signed as a JWT with ES256, with `kid` (key ID) and `iss` (team ID). The token must be refreshed no more often than every 20 minutes and no less often than every 60 minutes; older tokens are rejected with `ExpiredProviderToken (403)`. Source: <https://developer.apple.com/documentation/usernotifications/establishing-a-token-based-connection-to-apns>
- **[V]** Apple Developer Program membership is $99 USD per year and includes push notifications and TestFlight. Source: <https://developer.apple.com/programs/whats-included/>
- **[I]** So the backend needs only: outbound HTTP/2, ES256 signing, and a secret store for the `.p8` key. No persistent connection or dedicated server is required at single-user volume.
- **[V]** Cloudflare Workers: a bug report states the same `fetch()` call to APNs works when deployed but fails in local development on macOS; the issue was open with no Cloudflare response when retrieved. Source: <https://github.com/cloudflare/workerd/issues/4841>. **[I]** Expect to test push against a deployed Worker rather than locally.
- **[U]** Supabase Edge Functions calling APNs directly: Supabase's own push guide covers only Expo Push and FCM, not direct APNs (<https://supabase.com/docs/guides/functions/examples/push-notifications>). I found no primary statement that Edge Function `fetch` negotiates HTTP/2 to APNs. This needs a 30-minute spike before committing. Fallbacks: route through FCM (free, see Firebase below) or Expo Push.

## Comparison table

| | Supabase | Cloudflare | Fly.io | Railway | Firebase | CloudKit | Small VPS |
|---|---|---|---|---|---|---|---|
| Database | Postgres | D1 (SQLite) | Self-run Postgres/SQLite on a volume; managed from $38 | Postgres as a service container | Firestore (NoSQL) | CloudKit records | Self-run |
| File storage | Yes, 1 GB free / 100 GB Pro | R2, 10 GB free | Volume, $0.15/GB | Volume, $0.15/GB | Cloud Storage | Assets, in user's iCloud quota | Local disk |
| Scheduled jobs | pg_cron (Supabase Cron) | Cron Triggers | Scheduled Machines (fuzzy hourly/daily/weekly/monthly) | Cron services, 5 min minimum | Scheduled functions (Blaze) | None | System cron |
| Long-job limit | 150 s free / 400 s paid wall-clock, 2 s CPU | 15 min cron/queue; Workflows unlimited wall-clock per step; 5 min CPU | None (container) | None stated (container) | 30 min scheduled, 60 min HTTP (2nd gen) | n/a | None |
| APNs | Direct unverified; FCM/Expo documented | Works deployed; local dev bug | Any Node library | Any Node library | FCM built in, free | Built-in silent sync pushes only | Any Node library |
| Auth | Built in | None; hand-rolled | None | None | Built in | iCloud account | None |
| Swift SDK | Official | None | n/a | n/a | Official | Native | n/a |
| React Native SDK | Official (JS, Expo quickstart) | None | n/a | n/a | Not verified here | None official | n/a |
| Offline/sync | None built in; PowerSync add-on | None | None | None | Built in, on by default on Apple | Built in | None |
| Free-tier gotcha | Paused after 1 week inactivity; 2 projects | 10 ms CPU per invocation | No free tier; 2 h / 7 day trial | $1/month credit after trial | No Functions on free plan | Not a backend | None free |
| Ops effort | Low | Low-medium | Medium | Low-medium | Low | Low, but incomplete | High |
| Monthly cost | $0, ~$10, or $25 | $0 or $5 | ~$4-8 | $5+ | ~$0 on Blaze at this scale | $0 | ~$5-8 |

Sources for each cell are in the per-provider sections below.

## Supabase

Pricing and limits:

- **[V]** Free plan: 500 MB database, 1 GB file storage, 5 GB egress, 500,000 Edge Function invocations, 50,000 MAU, limit of 2 active projects. "Free projects are paused after 1 week of inactivity." Source: <https://supabase.com/pricing>
- **[V]** Pro plan: $25/month, includes $10/month compute credits, 8 GB disk per project (then $0.125/GB), 100 GB file storage (then $0.0213/GB), 250 GB egress, 2 million function invocations. "Projects on paid plans are not paused for inactivity." Source: <https://supabase.com/pricing>
- **[V]** Compute: Micro is $0.01344/hour, about $10/month, 1 GB RAM. Nano (0.5 GB) exists only on Free. Source: <https://supabase.com/docs/guides/platform/compute-and-disk>
- **[V]** Billing is per organization, and every project adds compute cost. Supabase's own example: 3 projects in a Pro org = $25 + $30 compute - $10 credits = $45/month. So each additional project is about $10/month. Pro has a spend cap on by default. Paused projects are not charged and do not count toward the free project limit. Sources: <https://supabase.com/docs/guides/platform/billing-faq>, <https://supabase.com/docs/guides/platform/billing-on-supabase>
- **[V]** A paused project can be restored from the dashboard within a restore window; after that, the backup and storage objects can be downloaded. The page retrieved states a "1-year window". Source: <https://supabase.com/docs/guides/platform/upgrading>
- **[V]** File upload size limit: 50 MB maximum on Free; configurable up to 500 GB on Pro. Source: <https://supabase.com/docs/guides/storage/uploads/file-limits>

Compute and scheduling:

- **[V]** Edge Functions: wall-clock 150 s on Free, 400 s on paid; CPU time 2 s per request; memory 256 MB; request idle timeout 150 s. Source: <https://supabase.com/docs/guides/functions/limits>
- **[V]** Background tasks via `EdgeRuntime.waitUntil` let a function respond immediately and keep working, capped by the same wall-clock, CPU and memory limits. Source: <https://supabase.com/docs/guides/functions/background-tasks>
- **[V]** Supabase Cron is built on `pg_cron`; jobs can run SQL, database functions, or HTTP requests such as calling an Edge Function; schedules from every second to yearly. Recommended no more than 8 concurrent jobs and 10 minutes per job. Source: <https://supabase.com/docs/guides/cron>
- **[U]** The Cron page did not state plan availability or price. **[I]** `pg_cron` is a database extension, so it is expected to work on Free.
- **[U]** Whether a cron job firing daily counts as "activity" that prevents pausing is not documented on the pages retrieved. Do not rely on it.

Clients:

- **[V]** Official Swift SDK with an iOS SwiftUI quickstart, and an Expo React Native quickstart using the JavaScript client. Source: <https://supabase.com/docs/guides/getting-started>
- **[I]** No built-in offline sync. Options are hand-rolled local cache plus refetch, or PowerSync.
- **[V]** PowerSync free plan: 2 GB synced/month, 500 MB hosted, 50 concurrent clients, and "Free projects are deactivated after 1 week of inactivity." Pro is from $49/month. A free self-hosted Open Edition exists. Source: <https://www.powersync.com/pricing>. **[I]** PowerSync Pro is outside the budget.

Assessment **[I]**:

- Fit is the best of all options; one vendor covers database, storage, auth, cron, and functions in TypeScript (Deno).
- The weak points are the 2 s CPU limit and 150/400 s wall-clock limit. AI and HEB calls are mostly waiting on network, which uses wall-clock but little CPU, so typical imports should fit. A multi-minute video import may not.
- Long jobs should be modelled as a job table in Postgres, advanced in steps by cron, rather than one long function call.

## Cloudflare (Workers, D1, R2, Cron Triggers, Queues, Workflows)

- **[V]** Workers Free: 100,000 requests/day, 10 ms CPU per invocation. Workers Paid: $5/month minimum, 10 million requests and 30 million CPU-ms included. Paid includes D1 (25 billion rows read, 50 million rows written, 5 GB), KV, Queues (1 million operations), and Durable Objects allowances. Source: <https://developers.cloudflare.com/workers/platform/pricing/>
- **[V]** Limits: CPU per request 10 ms free, up to 5 minutes paid (default 30 s). HTTP request wall-clock has no limit while the client is connected. Cron Triggers and Queue consumers: 15 minutes wall-clock. Cron Triggers per account: 5 free, 250 paid. Memory 128 MB. Subrequests 50 per request free, 10,000 paid. Source: <https://developers.cloudflare.com/workers/platform/limits/>
- **[V]** D1 Free: 5 million rows read/day, 100,000 rows written/day, 5 GB total. Source: <https://developers.cloudflare.com/d1/platform/pricing/>
- **[V]** R2: $0.015/GB-month, free tier 10 GB-month, 1 million Class A and 10 million Class B operations per month, egress free. Source: <https://developers.cloudflare.com/r2/pricing/>
- **[V]** Queues are available on Workers Free with 10,000 operations/day and 24 hour retention; paid includes 1 million operations/month. Source: <https://developers.cloudflare.com/queues/platform/pricing/>
- **[V]** Workflows: wall-clock per step is unlimited; CPU per step 10 ms free, 30 s default up to 5 minutes paid; sleep up to 365 days; available on Free and Paid. Source: <https://developers.cloudflare.com/workflows/reference/limits/>

Assessment **[I]**:

- Best long-job story among serverless options, and no pausing on either plan.
- The Free plan's 10 ms CPU limit is tight for ES256 signing and parsing large AI responses, so plan on Paid at $5.
- Costs: no auth product, no official Swift or React Native client, SQLite instead of Postgres, no sync. For a single user, auth can be a static bearer token or a signed device token. The clients talk to a plain HTTP API the owner writes.
- TypeScript throughout, which suits the owner.

## Fly.io

- **[V]** shared-cpu-1x: about $1.80/month at 256 MB, $3.60 at 512 MB, $7.20 at 1 GB (Ashburn). Volumes $0.15/GB-month. Stopped machines are charged $0.15/GB of root filesystem per 30 days. Dedicated IPv4 $2/month. Egress from $0.02/GB in North America and Europe. Source: <https://fly.io/docs/about/pricing/>
- **[V]** Managed Postgres starts at $38/month (Basic, shared-2x, 1 GB). Source: <https://fly.io/pricing/>
- **[V]** No ongoing free tier; the free trial is 2 hours of machine runtime or 7 days, whichever comes first. Source: <https://fly.io/docs/about/free-trial/>
- **[V]** Machines can be scheduled to start on a "fuzzy hourly, daily, weekly, or monthly cycle"; Fly's docs add that host resource constraints may prevent a scheduled start. Source: <https://fly.io/docs/machines/flyctl/fly-machine-run/>

Assessment **[I]**:

- As the whole backend: a 512 MB machine plus a small volume running SQLite or self-managed Postgres is roughly $4-8/month, but backups, upgrades, auth and storage are all the owner's job.
- Better used as a companion: a scale-to-zero container for jobs that need native binaries or run for many minutes.
- Scheduling granularity is coarse and not exact; an in-process scheduler would be needed for precise times.

## Railway

- **[V]** Hobby $5/month, includes $5 of usage that does not roll over. Rates: RAM $10/GB/month, vCPU $20/vCPU/month, volumes $0.15/GB/month, egress $0.05/GB. Hobby volume limit 5 GB. Source: <https://docs.railway.com/reference/pricing/plans>
- **[V]** Trial is a one-time $5 for up to 30 days, then the Free plan with $1/month credit. Volumes from trial accounts are deleted 30 days after credits expire unless upgraded. Source: <https://docs.railway.com/reference/pricing/free-trial>
- **[V]** Cron: runs a service's start command on a schedule; minimum 5 minutes apart, UTC, not guaranteed to the minute; the process must exit; an overlapping run is skipped. Source: <https://docs.railway.com/reference/cron-jobs>

Assessment **[I]**:

- An always-on 0.5 GB Node service is about $5/month of RAM alone, and Postgres is a second container of similar size, so realistic cost is $5-12/month, above the included credit.
- Good developer experience, no execution limits, but no auth, storage product, or client SDK. 5 GB volume cap on Hobby limits video storage; pair with R2 if needed.

## Firebase

- **[V]** Spark (free): Firestore 1 GiB stored, 50,000 reads, 20,000 writes and 20,000 deletes per day. Cloud Functions are not available on Spark. Cloud Messaging is no-cost on both plans. Auth is no-cost to 50,000 MAU. Blaze: Functions 2 million invocations, 400,000 GB-seconds and 200,000 CPU-seconds free per month. Source: <https://firebase.google.com/pricing>
- **[V]** Function timeouts: 1st gen 540 s; 2nd gen 60 minutes for HTTP, 1,800 s for scheduled and task queue functions, 540 s for event-driven. Functions require the Blaze plan. Source: <https://firebase.google.com/docs/functions/quotas>
- **[V]** Firestore offline persistence caches data, queues writes, and syncs on reconnect with last-write-wins; enabled by default on Apple and Android. Source: <https://firebase.google.com/docs/firestore/manage-data/enable-offline>
- **[V]** FCM delivers to Apple devices after an APNs authentication key is uploaded to Firebase. Source: <https://firebase.google.com/docs/cloud-messaging/ios/certs>

Assessment **[I]**:

- Strongest built-in offline sync and the simplest push path. Likely about $0/month at single-user volume on Blaze, which is pay-as-you-go and needs a budget alert.
- Costs: NoSQL data model is an awkward fit for recipes, ingredients, item mappings and grocery lists, which are relational; it is a new platform for the owner; and the stack is tied to Google.
- **[U]** React Native support was not verified from a primary source in this research.

## Apple CloudKit

- **[V]** Syncs across Apple platforms and the web. Private database data is stored in the user's iCloud account and counts against their iCloud quota; the public database offers up to 1 PB. Source: <https://developer.apple.com/icloud/cloudkit/>
- **[V]** CloudKit is not a replacement for local storage. Three integration levels: `NSPersistentCloudKitContainer`, `CKSyncEngine`, and raw `CKDatabase`. Source: <https://developer.apple.com/documentation/cloudkit/deciding-whether-cloudkit-is-right-for-your-app>
- **[V]** "Use a server-to-server key to access the public database of a container as the developer who created the key." Private database access over web services requires a user sign-in web token. Source: <https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/SettingUpWebServices.html>
- **[V]** The CloudKit overview describes storage, sync and a console; it lists no server-side code execution or scheduled jobs. Source: <https://developer.apple.com/icloud/cloudkit/>

Assessment **[I]**:

- Cannot be the backend: no place to run weekly picks, imports, or HEB calls, and a cloud job cannot cleanly write to the user's private database.
- Requires SwiftUI/native; there is no official React Native SDK. Choosing CloudKit would decide the client stack.
- Could serve as a free device-to-device sync layer in a SwiftUI build, but that creates two sources of truth alongside a cloud backend. Not recommended.

## Small VPS (Hetzner, DigitalOcean)

- **[V]** Hetzner raised prices on 15 June 2026. New prices excluding VAT and IPv4: CX23 (2 vCPU, 4 GB) EUR 5.49 / $6.49 and CAX11 EUR 5.99 / $6.99 in EU locations; CPX11 in US locations EUR 17.49 / $20.49. Source: <https://docs.hetzner.com/general/infrastructure-and-availability/price-adjustment/>
- **[V]** Hetzner IPv4 primary IP is EUR 0.50/month excluding VAT; IPv6 is free. Source: <https://docs.hetzner.com/cloud/servers/overview/>
- **[V]** Hetzner's cost-optimized plan page showed "This product is currently unavailable" for its plans when retrieved. Source: <https://www.hetzner.com/cloud/cost-optimized/>. **[U]** This may be a rendering artifact; check the console before relying on it.
- **[V]** DigitalOcean Basic droplets: $4/month (512 MB, 1 vCPU, 10 GB SSD, 500 GB transfer) and $6/month (1 GB, 25 GB SSD, 1,000 GB transfer). Backups are 20% (weekly) or 30% (daily) of droplet cost. Source: <https://www.digitalocean.com/pricing/droplets>

Assessment **[I]**:

- No limits of any kind, and can run `ffmpeg`, headless browsers, and long jobs. About $5-8/month with backups.
- Highest operational effort: OS patching, TLS, Postgres backups and restores, monitoring, deploys. For a solo developer who wants to spend time on the app, this is the wrong trade unless native binaries become essential.
- Hetzner's cheap plans are in the EU; the owner and HEB are in Texas. Latency is tolerable for background jobs. **[U]** Whether HEB blocks or challenges non-US or data-centre IP addresses is unknown and affects every option here; it belongs to the HEB integration ticket.

## Data sync and offline

| Option | Built-in offline | Notes |
|---|---|---|
| Firebase Firestore | Yes, default on Apple **[V]** | Last-write-wins |
| CloudKit | Yes **[V]** | Apple-only; needs local store |
| Supabase | No **[I]** | PowerSync free tier deactivates after 1 week inactivity **[V]**; Pro from $49 **[V]** |
| Cloudflare, Fly, Railway, VPS | No **[I]** | Hand-built |

**[I]** For one user on two devices, conflicts are rare. A local cache with refetch on foreground, plus queued writes for the grocery list (the one place offline matters, in the store), is likely enough and avoids a sync product. This is a decision for the sync ticket, not settled here.

## Recommendation

**Primary: Supabase.**

- Covers all six needs in one product with TypeScript functions and Postgres the owner already knows.
- Official SDKs for both candidate client stacks, so it does not force that decision.
- Cost is $0 on Free, or about $10/month as an added project in an existing Pro org.

Conditions and risks:

1. Confirm the plan of the existing Supabase org. If it is Free and a new Pro org would be needed, the $25 price removes all AI headroom; choose Cloudflare instead or accept the Free plan's pausing risk.
2. Spike direct APNs from an Edge Function before committing. If it fails, send through FCM.
3. Design imports as resumable steps so they fit in 150/400 s wall-clock and 2 s CPU.

**Runner-up: Cloudflare Workers Paid, $5/month.**

- Cheapest always-on option, no pausing, best long-job limits, generous storage.
- Choose it if Supabase would cost $25, or if imports prove too long for Edge Functions.
- Costs more build effort: hand-written API, auth, and client data layer.

**Companion if needed: a Fly.io scale-to-zero machine, about $2-4/month**, only if import requires native binaries.

## Monthly cost estimate

| Line | Supabase (added to existing Pro org) | Supabase Free | Cloudflare Paid |
|---|---|---|---|
| Hosting platform | ~$10 | $0 | $5 |
| Storage overage | $0 (within 100 GB) | $0 (within 1 GB) | $0 (within 10 GB R2) |
| Push (APNs) | $0 | $0 | $0 |
| Optional Fly job runner | $0-4 | $0-4 | $0-4 |
| **Hosting subtotal** | **~$10-14** | **$0-4** | **$5-9** |
| AI usage | _placeholder: see ticket #7_ | _placeholder: see ticket #7_ | _placeholder: see ticket #7_ |
| **Headroom left for AI under $25** | ~$11-15 | ~$21-25 | ~$16-20 |

Not included: Apple Developer Program at $99/year ($8.25/month) **[V]**. If it counts against the ceiling, subtract $8.25 from every headroom figure.

## Open questions

1. What plan is the owner's existing Supabase organization on? This decides $0, $10 or $25.
2. Does the $10-25 ceiling include the Apple Developer Program fee?
3. Does direct APNs over HTTP/2 work from Supabase Edge Functions? (Needs a spike.)
4. Does scheduled cron activity prevent Free-plan pausing? (Undocumented.)
5. Does recipe import need native binaries or jobs longer than 400 s? (Import ticket.)
6. Does HEB treat data-centre IP addresses differently? (HEB ticket.)
7. How much video will be stored? 1 GB on Supabase Free is small; R2's 10 GB free tier can be paired with any option.

## Method note

Pages were retrieved with an automated fetch tool that summarises page content, on 2026-09-29. Figures quoted here were reported as direct quotes from the linked pages, but anyone making a purchase decision should re-open the linked page, since providers change prices often (Hetzner changed twice in 2026).
