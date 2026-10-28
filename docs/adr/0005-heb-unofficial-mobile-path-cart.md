# 5. HEB: unofficial mobile path, cart only, accepting the Terms of Use risk

Date: 2026-10-27
Status: Accepted
Ticket: [Choose the HEB integration approach](https://github.com/enyiasonye/kitchenmate/issues/14)

## Context

H-E-B has no official API for writing to a customer account. [HEB integration options](https://github.com/enyiasonye/kitchenmate/issues/2) found two unofficial paths. The web path is behind bot protection. The mobile-app path (OAuth bearer and refresh tokens, `heb-sdk-unofficial`) is the only one with evidence of unattended server-side use. Existing clients write to the **cart**, not the shopping list. Both paths violate H-E-B's Terms of Use, and the mobile path presents itself as H-E-B's own iOS app. The alternatives fail the requirement that items land in the owner's real H-E-B account: Instacart fulfils through its own cart, and a browser helper on the Mac is ruled out because the Mac is deferred ([ADR 1](0001-client-stack-swiftui-iphone.md)).

[HEB mobile path spike](https://github.com/enyiasonye/kitchenmate/issues/22) confirmed on 2026-10-27 that the mobile path works from the Mac and from a Supabase Edge Function:
- login with automatic redirect capture
- search, product detail with aisle, and cart writes, which **set** the quantity
- 30-minute access tokens, and refresh tokens that change on every use
- store search fails, but the account's default pickup store can be read

This repo is public.

## Decision

**Approach.** V1's only automated HEB integration is the unofficial mobile path, called from Supabase Edge Functions. The owner accepts the Terms of Use risk, including suspension of the H-E-B account (and with it curbside ordering, order history and saved payment setup) without notice. To keep that risk low:
- no evasion tooling, and no identity beyond what the SDK already sends
- HEB traffic only on owner-driven actions, plus a periodic token refresh and a daily health check, with no catalog polling
- no checkout automation

**Destination: the cart only.** Cart writes set the quantity, so writes read the cart first and send the combined quantity. Shopping-list writes, which would mean reverse-engineering undocumented mobile operations, are a possible later addition.

**Sign-in and tokens.**
- The owner signs in inside the app's web sign-in sheet (`ASWebAuthenticationSession`), using password or one-time passcode, and the sheet captures the redirect.
- The app hands the authorization code straight to an Edge Function, which exchanges it at once.
- Tokens are stored only on the backend, encrypted at rest, in a table the app's client cannot read under RLS. Only Edge Functions use them, and they are never logged. The HEB password is never stored.
- All HEB calls go through one backend function. It refreshes under a database lock and saves the new refresh token before using the new access token, because two concurrent refreshes would break the chain.
- A scheduled refresh every few hours keeps the chain alive, since the refresh-token lifetime is unknown beyond about 10 h.
- A failed refresh sends a "Reconnect HEB" push that reopens the sign-in sheet.

**Breakage and Manual mode.**
- Auth failures lead to Reconnect. Other failures count as breakage: unknown-query errors, response-shape changes, and repeated 5xx.
- Pushes to the cart are queued per Grocery List entry (pending / sent / failed) and retried with backoff.
- During breakage the Grocery List runs in **Manual mode**. Each pending entry shows its mapped Product's name, size, aisle and HEB product link, and the owner adds it in the HEB app and ticks it off.
- One push per outage, and a daily health check catches breakage early.
- Product search needs HEB, so Items left unmapped during an outage are flagged until it recovers.
- When a health check passes again, pending entries are pushed automatically. Failed ones are retried by the owner.

**SDK dependency.**
- `heb-sdk-unofficial` and `heb-auth-unofficial` are pinned to exact versions and upgraded only on purpose.
- They are imported only by KitchenMate's own **HEB adapter**, which exposes search, product detail with aisle, cart read, set cart quantity, default pickup store, token exchange and refresh, and a health check. The adapter is also the seam where future Stores plug in.
- When upstream is slow to fix a breakage, the adapter points at a private fork.

**Store.** KitchenMate always uses the account's default pickup store, read on each run, and has no store picker. The owner changes the store in the H-E-B app. A change triggers a one-time notice. Product mappings are per Store (HEB), not per branch, so they survive a change.

**Public repo.** Client identifiers, request hashes, tokens, and product or store ids are never committed. They live in the npm package, Edge Function secrets, or the database.

## Consequences

- The H-E-B account can be lost without notice. KitchenMate's own data (recipes, Items, mappings, the Grocery List) does not depend on it, and Manual mode keeps the list usable.
- Breakage will recur, every 1–2 months on the web path and at an unknown rate on the mobile path, and fixing it is hand maintenance in the adapter or the private fork.
- The owner occasionally re-signs in when a token chain dies. How often is unknown.
- How the Grocery List and the cart stay in step (when pushes happen, whether the cart is read back, clearing) is decided in [Grocery list and store mirror](https://github.com/enyiasonye/kitchenmate/issues/29), within the cart-only, set-quantity limits here.
