# Video retention: store, embed, or link

Research for issue #6. Researched 2026-09-29. This is a feasibility and policy survey, not legal advice.

## Summary

- **Storing a copy** of a platform-hosted video is technically cheap (storage for a personal library is cents per month) but is **not permitted by the terms of YouTube, TikTok, or Instagram** unless the platform itself offers the download. The platform-offered downloads that exist (YouTube Premium offline, TikTok's save button) either stay locked inside the platform's app or depend on the creator allowing it. Tasty/BuzzFeed is the exception: its user agreement grants a personal-use download licence.
- **In-app playback through official embeds** is supported and free for YouTube and TikTok, with rules attached (YouTube: identify the app via Referer, minimum player size, no overlays, no offline/caching). Instagram embeds require a Meta developer app that has passed App Review, which is heavy for a single-user app.
- **Linking out** works everywhere, needs no approval, and has no policy exposure. On iOS and macOS, standard `https` links open the platform's app when it is installed (universal links).
- **Deletion and offline**: embeds and links both die when the original is deleted, made private, or embedding is turned off. Neither works offline. Only a stored copy survives, and that is the option the terms restrict.
- **Recommendation**: treat the extracted recipe text as the durable record; embed YouTube and TikTok in-app; link out for Instagram and Tasty. **Fallback**: link out for everything. Optionally allow the owner to attach a video file they obtained themselves through a platform-provided feature.

Legend used below: **[V]** verified against the cited primary source on 2026-09-29; **[S]** seen only in a search-result excerpt of the official page (page itself could not be fetched); **[I]** inference by the researcher.

## Per-platform comparison

| | (a) Store a copy | (b) In-app playback via official embed | (c) Link out / deep link | If the original is deleted or made private | Offline |
|---|---|---|---|---|---|
| **YouTube** | Terms prohibit downloading except as authorised by the service; API policies prohibit storing copies and offline playback [V]. Premium downloads stay inside the YouTube app [V]. | Supported. IFrame player in `WKWebView`; official iOS helper library exists. Requires Referer identification, min 200x200 px, no overlays [V]. Creator can disable embedding [V]. | Works. Standard `https` URL; opens the YouTube app if installed [V for the iOS mechanism, I for YouTube specifically]. | Embed returns error 100 (removed/private) or 101/150 (embedding disabled) [V]. Link shows unavailable page [I]. | Not via embed or link. Premium offline is limited to 29 days between reconnects and lives in the YouTube app [V]. |
| **TikTok** | Terms prohibit extracting content with automated systems and circumventing restrictions [V]. In-app save button exists when the creator allows it, output is watermarked [S]. | Supported. Embed player is an iframe at `tiktok.com/player/v1/{id}`; oEmbed endpoint needs no authentication [V]. | Works. Standard `https` URL [I]. | Embed stops working: "if a video has been removed from the TikTok app, the same video in its embedded form on the web will no longer be accessible" [V]. | Not via embed or link. |
| **Instagram** | Terms prohibit accessing or collecting information in an automated way without permission [S]. No general download feature for others' posts was verified. | Possible but gated: oEmbed requires the "Meta oEmbed Read" feature, which requires App Review [V]. Public posts only; not private, inactive, age-restricted accounts, Stories, or accounts that disabled embeds [V]. | Works. Standard `https` URL [I]. Lowest-friction option for this platform. | Embed not supported for private/inactive accounts or accounts that turned embeds off [V]; deleted posts disappear from embeds [S]. | Not via embed or link. |
| **Tasty** | BuzzFeed's user agreement grants a licence to "view, print, download, and display locally Content, solely for the user's personal use" [V]. Automated scraping tools are prohibited [V]. Whether the agreement covers Tasty by name was not confirmed [V that it is not named]. | No official Tasty embed player was verified. Tasty videos that are also published on YouTube can use the YouTube embed [I]. | Works. Tasty recipes are web pages with their own app [V that the app exists]. | Not verified. | Not verified. |

## Option (a): storing a copy

### What the platforms' terms say

**YouTube**

- The Terms of Service (effective 2023-12-15) list among the restrictions that you may not "access, reproduce, download, distribute, transmit, broadcast, display, sell, license, alter, modify or otherwise use any part of the Service or any Content" except as authorised by the service or with written permission from YouTube and the rights holders, and may not "circumvent, disable, fraudulently engage with, or otherwise interfere with any part of the Service ... including security-related features" or features that restrict copying. [V] Source: https://www.youtube.com/static?template=terms
- The API Services Developer Policies (which also govern the embedded player) say API clients must not "download, import, backup, cache, or store copies of YouTube audiovisual content without YouTube's prior written approval" and must not "make content available for offline playback". [V] Source: https://developers.google.com/youtube/terms/developer-policies
- The platform-offered alternative is YouTube Premium offline downloads. These are watched in the YouTube app, "can be played offline for up to 29 days" before the device must reconnect, and are removed at the next sync if the video is no longer available. [V] Source: https://support.google.com/youtube/answer/11977233
- Consequence: Premium downloads are not files KitchenMate could hold, and they do not survive deletion of the original. [I]

**TikTok**

- The Terms of Service (last updated 2026-07-15) prohibit users to "scrape, crawl, export or otherwise extract any data or content in any form, for any purpose, from the Platform using any automated system or software" and to "interfere with, disable, or circumvent any restrictions, filters, controls or safety measures". [V] Source: https://www.tiktok.com/legal/page/us/terms-of-service/en
- TikTok's app has a save/download action. Creators can turn it off, and saved videos carry a TikTok watermark with the creator's username. [S] Source (TikTok-hosted pages surfaced by search; the help-centre article itself could not be fetched): https://support.tiktok.com/en/using-tiktok/creating-videos/downloading-videos
- The Developer Terms limit use of information obtained through developer services to "developing, maintaining, and supporting your Applications". No explicit caching clause was found on that page. [V] Source: https://www.tiktok.com/legal/page/global/tik-tok-developer-terms-of-service/en

**Instagram**

- The Terms of Use say you cannot access or collect information in unauthorised ways, including "in an automated way without our express permission", and cannot violate others' intellectual property rights. [S] The page could not be fetched directly; wording is from the search excerpt of the official page. Source: https://help.instagram.com/581066165581870
- The oEmbed documentation states: "Using metadata and page, post, or video content (or their derivations) from the endpoint for any purpose other than providing a front-end view of the page, post, or video is strictly prohibited." [V] Source: https://developers.facebook.com/docs/instagram-platform/oembed

**Tasty (BuzzFeed)**

- The BuzzFeed User Agreement grants "a worldwide, non-exclusive, revocable, non-sublicensable and non-transferable license to view, print, download, and display locally Content, solely for the user's personal use of the Services" and prohibits "use, reproduction, modification, distribution or storage of any Content for any other purpose" without written permission. It also prohibits robots, scrapers, spiders, and crawlers. [V] Source: https://www.buzzfeed.com/about/useragreement
- The agreement does not name Tasty. Whether Tasty is covered as one of BuzzFeed's "Services" was not confirmed. [V that it is unnamed]

### Copyright position at a high level (United States)

- Fair use is decided case by case on four statutory factors: purpose and character of the use, nature of the work, amount used, and effect on the market. [V] Source: https://www.copyright.gov/title17/92chap1.html (section 107)
- Separately from infringement, the law prohibits circumventing "a technological measure that effectively controls access to a work", while stating that this does not affect fair use as a defence to infringement. [V] Source: https://www.copyright.gov/title17/92chap12.html (section 1201)
- What this means in practice: a private, non-commercial copy of a whole video has arguments both for it (personal, non-commercial, no redistribution) and against it (entire work copied, creator loses views). No statute or platform term makes personal copies generally allowed. Terms-of-service breach is a contract question independent of copyright, and the practical exposure is account-level enforcement. [I]
- Videos the owner made, or has the creator's permission to keep, do not raise these questions. [I]

### Storage size and cost

Size estimate [I], based on YouTube's recommended upload bitrate of 8 Mbps for 1080p at standard frame rates (source: https://support.google.com/youtube/answer/1722171, seen via search excerpt [S]). 8 Mbps is about 60 MB per minute. Delivered streams are usually lower than upload bitrates, so this is an upper bound.

| Library | Assumption | Approximate size |
|---|---|---|
| 300 short-form videos | 1 minute each, 20-60 MB | 6-18 GB |
| 100 long-form videos | 10 minutes each, 150-600 MB | 15-60 GB |
| Mixed personal library | both of the above | 20-80 GB |

Published storage prices [V]:

| Provider | Storage price | Included | Egress | Source |
|---|---|---|---|---|
| Cloudflare R2 | $0.015 per GB-month | 10 GB-month free | Free | https://developers.cloudflare.com/r2/pricing/ |
| Backblaze B2 | $6.95 per TB-month | First 10 GB free | Free up to 3x stored volume, then $0.01/GB | https://www.backblaze.com/cloud-storage/pricing |
| Supabase Storage (Free) | n/a | 1 GB, 50 MB max upload | 5 GB | https://supabase.com/pricing |
| Supabase Storage (Pro, $25/month) | $0.0213 per GB over quota | 100 GB | 250 GB, then $0.09/GB | https://supabase.com/pricing |

Cost for an 80 GB library [I]: about $1.05/month on R2, about $0.49/month on B2, and inside the included quota on Supabase Pro. Supabase Free is too small, and its 50 MB upload cap excludes most long-form video. Storage cost is not the constraint; the $10-25/month ceiling is unaffected. On-device storage costs nothing but consumes phone space and does not sync by itself. [I]

## Option (b): in-app playback via official embeds

**YouTube**

- Google documents an official iOS helper library that "creates a `WebView` and a bridge between your application's Objective-C code and the YouTube player's JavaScript code". It cannot play private videos (unlisted is supported). [V] Source: https://developers.google.com/youtube/v3/guides/ios_youtube_helper
- Required minimum functionality for embedded players [V], source: https://developers.google.com/youtube/terms/required-minimum-functionality
  - API clients "must provide identification through the `HTTP Referer` request header"; in a WebView the app sets it (for example with `loadHTMLString:baseURL:` on iOS), using an HTTPS URL whose domain is the app's identifier.
  - Use an OS-provided web view (`WKWebView` or `SFSafariViewController` on Apple platforms).
  - Viewport at least 200 x 200 px; 480 x 270 recommended for 16:9 with controls.
  - No overlays or frames in front of any part of the player.
  - No autoplay until more than half the player is visible.
- Missing client identification produces player error 153. [V] Source: https://developers.google.com/youtube/iframe_api_reference
- Policies also forbid background playback and separating audio from video. [V] Source: https://developers.google.com/youtube/terms/developer-policies
- Embedding is covered by the API Terms of Service; a privacy-enhanced domain (`youtube-nocookie.com`) exists; creators can untick "Allow embedding". [V] Source: https://support.google.com/youtube/answer/171780
- `playsinline=1` gives inline playback in web views that have `allowsInlineMediaPlayback` enabled. [V] Source: https://developers.google.com/youtube/player_parameters

**TikTok**

- The embed player is "a TikTok post hosted inside of an inline frame (iframe) element" at `https://www.tiktok.com/player/v1/{post_id}`, with parameters for controls, autoplay, loop, description, and music info, and control via `postMessage`. [V] Source: https://developers.tiktok.com/doc/embed-player
- The oEmbed endpoint `https://www.tiktok.com/oembed?url=...` returns title, author, thumbnail URL, and embed HTML. The documentation lists no authentication requirement, and an unauthenticated request returned HTTP 200 on 2026-09-29. [V] Source: https://developers.tiktok.com/doc/embed-videos/

**Instagram**

- oEmbed is served from `graph.facebook.com` (`GET /instagram_oembed`), limited to 1,000 requests per hour, and supports photo, video, Reel, and Feed posts from public accounts. [V] Source: https://developers.facebook.com/docs/instagram-platform/oembed
- The required "Meta oEmbed Read" feature "requires successful completion of the App Review process before your app can access live data". [V] Source: https://developers.facebook.com/docs/features-reference/meta-oembed-read
- The documented sample response contains `version`, `provider_name`, `provider_url`, `type`, `width`, and `html` only, so no thumbnail or author metadata should be assumed. [V] Same oEmbed source.
- Consequence: Instagram embedding means registering a Meta developer app and passing App Review for an app with one user. That cost is out of proportion to the benefit. [I]

**Tasty**

- No official embed player or oEmbed documentation for Tasty was found. Not verified either way.

**Apple platform notes**

- `WKWebViewConfiguration.allowsInlineMediaPlayback` defaults to `false` on iPhone and `true` on iPad; it must be set to `true` for inline playback on iPhone, and HTML video elements also need the `playsinline` attribute. [V] Source: https://developer.apple.com/documentation/webkit/wkwebviewconfiguration/allowsinlinemediaplayback
- `WKWebView` is available on macOS as well as iOS, so one embed approach serves both clients. [I]

**Limits common to all embeds** [I unless cited]

- Require a network connection. YouTube policy explicitly forbids offline playback. [V, developer policies above]
- May show platform branding, ads, and login or "watch on" prompts that the app cannot remove (YouTube forbids overlays and modifying the player). [V for YouTube]
- Depend on the creator keeping the post public and embeddable.

## Option (c): linking out

- Universal links are standard `https` links. "When users tap or click a universal link, the system redirects the link directly to your app without routing through the person's default web browser"; if the app is not installed, the URL opens in the browser. [V] Source: https://developer.apple.com/documentation/xcode/allowing-apps-and-websites-to-link-to-your-content
- Opening a URL from the app uses `UIApplication.open(_:options:completionHandler:)`. [V] Source: https://developer.apple.com/documentation/uikit/uiapplication/open(_:options:completionhandler:)
- Storing the original share URL and opening it is therefore enough; no custom URL schemes are needed. That each platform's app claims its own links is expected but was not verified per platform. [I]
- Costs: leaves KitchenMate while cooking; the platform app may open its feed experience around the video; on Mac the link usually opens in the browser. [I]
- Benefits: no approval process, no policy exposure, nothing to maintain. [I]

## When the original is deleted or made private

| Platform | Documented behaviour | Source |
|---|---|---|
| YouTube | Player error 100: "The video requested was not found. This error occurs when a video has been removed (for any reason) or has been marked as private." Error 101/150 when the owner disallows embedded playback. | https://developers.google.com/youtube/iframe_api_reference |
| TikTok | "If a video has been removed from the TikTok app, the same video in its embedded form on the web will no longer be accessible." | https://developers.tiktok.com/doc/embed-videos/ |
| Instagram | Posts from private, inactive, or age-restricted accounts, and accounts that disabled embeds, are not supported. | https://developers.facebook.com/docs/instagram-platform/oembed |
| YouTube Premium downloads | Removed from the device at next sync if no longer available. | https://support.google.com/youtube/answer/11977233 |

Under options (b) and (c) the video is lost when the source goes away. The recipe survives only if its content was extracted at import time. The YouTube error codes give the app a way to detect a dead video and mark the recipe accordingly. [I]

## What existing recipe apps do

| App | Documented behaviour | Source |
|---|---|---|
| ReciMe | Imports from Instagram and TikTok through the share sheet. Extracts the recipe from the caption, then from the video's audio, then by locating the original recipe website. Help pages do not say the video file is stored. | https://recime.app/help/en/articles/11596425-import-from-instagram, https://recime.app/help/en/articles/11661452-import-from-tiktok |
| Crouton | App Store description covers import from websites, scanning with AI and OCR. It does not mention video platforms or video storage. | https://apps.apple.com/us/app/crouton-recipe-manager/id1461650987 |
| Pestle | Reported to import TikTok and Reels by reading captions with on-device machine learning. Secondary sources only; not verified against Pestle's own documentation. | https://newsgpt.ai/2024/11/25/pestle-introduces-ai-powered-recipe-conversion-from-tiktok-videos/ |
| Paprika | Reported to have no video playback; users keep video links in notes. Secondary sources only; not verified against Paprika's user guide. | https://www.paprikaapp.com/help/ios/ (guide located, claim not confirmed in it) |

Pattern [I]: the apps that document their behaviour treat the video as an input to text extraction and keep a link. None of the documentation reviewed describes storing the video file.

## Trade-offs

| | Store a copy | Embed | Link out |
|---|---|---|---|
| Survives deletion of the original | Yes | No | No |
| Works offline | Yes | No | No |
| Within platform terms | No for YouTube, TikTok, Instagram (unless platform-provided); yes for Tasty personal use | Yes, with conditions | Yes |
| Stays inside KitchenMate | Yes | Yes | No |
| Setup effort | Storage bucket, upload path, sync | Web view per platform; Meta App Review for Instagram | Minimal |
| Ongoing maintenance | Low once stored | Medium; embed rules and players change | None |
| Monthly cost | About $0-1 | $0 | $0 |

## Recommendation

1. **Make the extracted recipe the durable record.** Capture ingredients, steps, title, creator name, and source URL at import. This is what protects against deletion, and it is what the reference apps do.
2. **Embed YouTube and TikTok in-app** using the official players in a `WKWebView`, following YouTube's Referer, size, and overlay rules.
3. **Link out for Instagram and Tasty.** Instagram's App Review requirement is not worth it for one user; Tasty has no verified embed.
4. **Always show an "Open original" link** next to any embed, and fall back to it when the player reports an error.
5. **Do not build automated downloading** of platform videos into KitchenMate. It conflicts with the terms of three of the four platforms, and the repository is public.

## Fallback

Link out for all four platforms. This has no approval steps, no policy exposure, and works identically on iPhone and Mac.

An optional addition under either path: let the owner attach a video file to a recipe manually. This covers videos the owner recorded, videos saved through a platform's own save feature where the creator allows it, and Tasty content under its personal-use licence. At the sizes above, Cloudflare R2 or Backblaze B2 would cost under about $1/month.

## Open questions

- If the client is React Native rather than SwiftUI, which web view and player wrappers meet YouTube's Referer requirement? Not researched here.
- YouTube requires the Referer domain to be the app ID "registered with the store that distributed your app". How this applies to a personal, non-App-Store install was not found in the documentation.
- Instagram Terms of Use and TikTok's download help article could not be fetched directly; statements marked [S] should be re-checked in a browser.
- Whether Tasty content falls under the BuzzFeed User Agreement's personal-use download licence, given that Tasty is not named in it.
- Whether thumbnails may be cached. YouTube's policies restrict stored API data; TikTok and Instagram oEmbed terms restrict use to front-end display. Not researched in depth.
