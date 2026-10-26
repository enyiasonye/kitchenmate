# 4. Import pipeline: sanctioned sources, layered fetch, Claude for every extraction

Date: 2026-10-25
Status: Accepted

## Context

[Recipe import techniques per source](https://github.com/enyiasonye/kitchenmate/issues/5) found that recipe websites carry schema.org `Recipe` data that is often incomplete. It found that social video beyond the caption is only reachable through unofficial means, which platform terms forbid and which are blocked from cloud IPs. It also found that Instagram has no sanctioned caption access, and that share extensions have tight memory limits and should only capture.

[ADR 3](0003-ai-claude-sonnet-primary.md) chose Claude Sonnet 5.5, which accepts text and images but not audio. [ADR 2](0002-backend-supabase-free-gemini-free.md) puts the backend on Supabase, where Edge Functions run TypeScript on Deno. [Backend hosting options and cost](https://github.com/enyiasonye/kitchenmate/issues/8) requires long imports to run as resumable steps.

## Decision

**Sources: sanctioned only in V1.**
- YouTube: the video description, through the YouTube Data API (API key in Edge Function secrets).
- TikTok: the caption, through oEmbed.
- Instagram: nothing is fetched. The import becomes a Bookmark that asks for a pasted caption or screenshots, unless the share itself carries the caption text.
- No transcripts or audio. Acquisition sits behind one interface, so a transcript source can be added later without touching the rest.
- **Linked recipe sites:** follow at most one recipe-looking link from a caption or description (not link-in-bio pages, shops or affiliate links), chosen by Claude during classification, with no chains. Precedence: the linked site's complete structured data, then a caption with both ingredients and steps, then caption plus page text together. The recipe's source is wherever the recipe came from; the video link is always the post. The raw capture keeps both.

**Page fetch: layered.**
1. Safari shares include the rendered page DOM, taken by the extension's JavaScript preprocessing file.
2. Otherwise the backend fetches the page with browser-like headers.
3. If that is blocked (4xx, a challenge page, or missing recipe data where some was expected), the import moves to `needs_device_fetch`. The next time the app is open, it loads the page in a hidden WKWebView and uploads the HTML.

**Websites: TypeScript parsing, then Claude.** The Edge Function reads JSON-LD, falling back to microdata, and checks it is complete (ingredients and steps). Claude always runs: it gets the structured data if complete, or the cleaned page text if not. It splits Ingredients into parts and finds sections. No site-specific parsers and no Python service.

**Images: straight to Claude.** Cookbook pages, screenshots and shared photos are sent to Claude as images, several per import merged into one recipe. Claude also returns the text it read, which is kept as the raw capture, so re-extraction runs without resending images.

**Flow.**
1. The share extension saves the capture (URL, text, images, Safari DOM) to the app group container. It starts a background upload straight to Supabase (files to Storage, one `imports` row), using the app's session shared through the app group keychain, then dismisses.
2. In-app entry points (paste URL, paste text, camera, photo library) create the same `imports` row.
3. Steps run as separate Edge Function calls driven by Supabase Queues (pgmq): **classify** → **acquire** → **extract** (one Claude call, JSON-schema output) → **finish** (copy the photo, write the recipe as Imported, or as a Bookmark if no recipe was found). A pg_cron sweep retries stuck steps.
4. Each step gets 3 tries with backoff. After that the import becomes a Bookmark with the error noted, so a capture is never lost.
5. The finished recipe appears in the library. No push notification for imports in V1.

## Consequences

- Groq Whisper is not used in V1; [ADR 3](0003-ai-claude-sonnet-primary.md)'s transcription choice applies only if a transcript source is added later.
- Videos whose recipe is spoken and not written in the caption or a linked site end up as Bookmarks, which need a pasted caption, screenshots, or Write with AI.
- A site that blocks the backend and isn't shared from Safari waits until the app is next opened.
- The share extension needs the app group container, a shared keychain session, and a background URLSession. It does no parsing.
- Instagram behaviour depends on what its share sheet hands over, which the Share sheet payload logger ticket will show.

## Rejected

- **Unofficial transcripts and audio (yt-dlp, transcript scrapers):** blocked from cloud IPs, constant upkeep as they change, and against platform terms.
- **Backend-only fetch:** bot protection blocks some sites (Tasty returned HTTP 406).
- **Always fetching on the device:** heavy work for the share extension, which has tight memory limits and must dismiss quickly.
- **Python `recipe-scrapers` service:** a second host and runtime beside Edge Functions; Claude covers what per-site parsers would.
- **On-device Vision text recognition, then a text model:** loses page layout (columns, ingredient lists beside steps, fractions).
- **A Mac share extension:** the Mac is out of V1 ([ADR 1](0001-client-stack-swiftui-iphone.md)).
