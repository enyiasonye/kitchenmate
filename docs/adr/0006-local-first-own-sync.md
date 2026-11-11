# 6. Local-first client with our own sync, not a sync service

Date: 2026-11-10
Status: Accepted
Ticket: [Local cache, offline and optimistic writes](https://github.com/enyiasonye/kitchenmate/issues/27)

## Context

Supabase ([ADR 2](0002-backend-supabase-free-gemini-free.md)) has no built-in offline sync, but the iPhone app must stay fast and let the owner cook, tick grocery entries and edit the plan with no connection. A managed sync layer (PowerSync: Swift SDK, Supabase connector, free tier) would provide a local SQLite copy, write queue and sync out of the box, at the cost of another service, another free tier to watch against the $10–25/month ceiling, and another moving part. The data set is a few MB for one user.

## Decision

Build sync ourselves: a full SwiftData mirror of the owner's data, read local-first; a local ordered outbox of idempotent writes retried with backoff; delta pulls by `updated_at` on launch, foreground and pull-to-refresh, plus Supabase Realtime while foregrounded; soft deletes via `deleted_at` (purged server-side after 30 days); last-write-wins per field, with no conflict UI.

## Consequences

- Every synced table carries `updated_at` and `deleted_at`; every write path must be idempotent.
- No third-party sync service or its limits; the sync code is ours to write and test.
- Switching to a sync service later means replacing the local store and outbox.
