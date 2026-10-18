# Recipe import techniques per source

Research for issue #5 (part of map #1). Researched 2026-09-29.

Out of scope here, covered by sibling tickets: AI provider and cost comparison, and whether videos may be stored. This document only says *where* an AI step sits in the pipeline.

Labels used throughout:

- **[Verified]** - stated by the source that owns the claim (linked).
- **[Observed]** - seen in a one-off probe run on 2026-09-29 from a developer machine; not a guarantee.
- **[Inference]** - my reasoning; not confirmed by a primary source. Needs a prototype before it becomes a decision.

## Summary

1. **Recipe websites and Tasty**: parse schema.org `Recipe` structured data (JSON-LD first). This is the only source with a genuinely structured, high-reliability path. Use an LLM on the page text only as a fallback. Open-source apps (Mealie, Tandoor) both build on the `recipe-scrapers` library.
2. **Social video (YouTube, Instagram, TikTok)**: there is no structured recipe data. The order that both ReciMe and Mealie document is **caption/description first, then transcript/audio, then a linked website**. Every step ends in an LLM normalisation call.
3. **Official APIs only cover part of this.** YouTube Data API gives the description for 1 quota unit with an API key; TikTok oEmbed gives the caption with no auth. Neither platform offers a sanctioned way to get a third party's transcript or audio, and Instagram's oEmbed returns only embed HTML and forbids non-display use. Everything beyond captions relies on unofficial access (yt-dlp, undocumented transcript endpoints) that conflicts with platform terms and is frequently blocked from cloud IPs.
4. **Share sheet**: the extension should do almost nothing - grab the URL/text/image, put it in the app group container, start a background upload, and dismiss. Extensions have much lower memory limits than apps (120 MB is the commonly cited figure for share extensions, not an Apple-published number) and are terminated aggressively.
5. **Cookbook photos**: Apple Vision does OCR fully on-device on iOS and macOS. Two viable shapes: on-device OCR then text-only LLM, or send the image to a multimodal LLM. The choice is a cost/quality question for the AI provider ticket.
6. **Biggest risk**: Instagram. It has the weakest official surface, the strictest terms, and the most fragile unofficial tooling. A manual fallback (screenshot or pasted caption) must be a first-class import path, not an afterthought.

## Per-source table

| Source | Best content path | Fallbacks | What the share sheet hands over | Reliability | Terms / anti-scraping | Where it runs |
|---|---|---|---|---|---|---|
| Recipe websites | schema.org `Recipe` JSON-LD / microdata / RDFa | Site-specific HTML parsing (`recipe-scrapers`), then LLM over page text | Safari: web URL, and optionally page content via a JavaScript preprocessing file [Verified]. Other browsers: URL [Inference] | High where markup exists | Site-specific; bot protection on some sites | Fetch on-device or backend; parse on backend |
| Tasty (tasty.co) | Same as websites; `recipe-scrapers` ships a `tasty.co` scraper | LLM over page text | Tasty app: URL [Inference] | Medium - plain HTTP fetch got HTTP 406 [Observed] | robots.txt disallows a long list of AI crawlers [Observed] | Prefer on-device fetch, backend parse |
| YouTube | `videos.list` `snippet.description` via Data API | Transcript (unofficial only), then audio transcription (unofficial only), then linked recipe URL in description | URL [Inference] | Description: high. Transcript: medium-low from cloud IPs | API policies forbid downloading/storing audiovisual content and separating audio; ToS forbids automated access | Backend |
| Instagram | Caption - no clean official path | Audio transcription via yt-dlp (unofficial), screenshot OCR, pasted caption text | URL [Inference] | Low | oEmbed is display-only; ToS forbids automated collection; robots.txt notice | Backend for URL path; on-device for screenshot path |
| TikTok | oEmbed `title` (the caption), no auth | Audio transcription via yt-dlp (unofficial), screenshot OCR | URL [Inference] | Caption: high. Audio: medium | ToS forbids automated extraction | Backend |
| Cookbook photos | Apple Vision text recognition on-device, then LLM structuring | Multimodal LLM directly on the image | Photos/Camera: image(s) [Inference] | High for printed text | None (user's own photo; cookbook copyright is a personal-use question) | OCR on-device, structuring on backend |

## 1. Recipe websites

### What is obtainable

- schema.org defines a `Recipe` type with `recipeIngredient`, `recipeInstructions`, `recipeYield`, `cookTime`, `prepTime`, `totalTime`, `nutrition`, `recipeCategory`, `recipeCuisine` and inherited `name`, `image`, `author`. Durations are ISO 8601 (for example `PT15M`). schema.org itself marks no property as required. [Verified] https://schema.org/Recipe
- Google requires only `name` and `image` for rich-result eligibility; `recipeIngredient`, `recipeInstructions`, times, yield and `video` are *recommended*, not required. So a page can be valid and still lack ingredients or steps. [Verified] https://developers.google.com/search/docs/appearance/structured-data/recipe
- `recipeInstructions` can be `HowToStep` items, `HowToSection` groups, or a single block of text. The normaliser must handle all three. [Verified] https://developers.google.com/search/docs/appearance/structured-data/recipe
- `recipeIngredient` is free text per line ("2 cups flour"); splitting into quantity, unit and item is not part of the markup. [Verified] https://schema.org/Recipe - this matters for the grocery-list ticket.

### How open-source projects do it

- `recipe-scrapers` (MIT) extracts from "standard HTML structure, Schema markup (including JSON-LD, Microdata, and RDFa formats) or OpenGraph metadata". It is "focused exclusively on HTML parsing" - the caller fetches the HTML - and "does not circumvent or bypass any bot protection measures". [Verified] https://github.com/hhursev/recipe-scrapers
- The repository contains roughly 650 site scraper modules. [Observed] counted via the GitHub tree API on 2026-09-29; https://github.com/hhursev/recipe-scrapers/tree/main/recipe_scrapers
- Mealie pins `recipe-scrapers`, `extruct`, `openai` and `yt-dlp` and tries strategies in this order: `RecipeScraperPackage`, `RecipeScraperOpenAITranscription`, `RecipeScraperOpenAI`, `RecipeScraperOpenGraph`. [Verified] https://github.com/mealie-recipes/mealie/blob/mealie-next/pyproject.toml and https://github.com/mealie-recipes/mealie/blob/mealie-next/mealie/services/scraper/recipe_scraper.py
- Mealie's scraper accepts pre-fetched HTML and "skips the network request if `html` is provided" - the same seam KitchenMate needs for on-device fetch. [Verified] same file.
- Tandoor pins `recipe-scrapers` and `litellm`; its documented AI feature covers "Importing recipes from images, PDFs, or raw text" through any LiteLLM-supported provider. [Verified] https://github.com/TandoorRecipes/recipes/blob/develop/requirements.txt and https://docs.tandoor.dev/features/ai/

### Implication for KitchenMate

`recipe-scrapers` is Python; the owner's stack is Node/TypeScript. [Inference] Options are a small Python service/function, or a TypeScript JSON-LD parser plus LLM fallback, giving up the per-site scrapers. This is a new decision (see Open questions).

## 2. Tasty

- `recipe-scrapers` has a dedicated `tasty.co` scraper that adds ingredient grouping on top of the generic schema path. [Verified] https://github.com/hhursev/recipe-scrapers/blob/main/recipe_scrapers/tasty.py
- A single plain HTTP GET of a Tasty recipe page from a developer machine returned **HTTP 406 with an empty body**. [Observed] I did not attempt to work around it, so I could not confirm the presence of JSON-LD on Tasty pages first-hand.
- `tasty.co/robots.txt` disallows many AI-related user agents (including `ChatGPT-User`, `ClaudeBot`, `anthropic-ai`, `Google-Extended`). [Observed] https://tasty.co/robots.txt
- [Inference] Tasty should be treated as "a recipe website with bot protection". The most robust path is fetching the page on the device (real user, residential IP, real browser stack) and sending the HTML to the backend for parsing. In Safari, the share extension can receive page content directly through the JavaScript preprocessing mechanism (section 6).

## 3. YouTube

### Official surface

- `videos.list` returns `snippet.title`, `snippet.description` (up to 5000 bytes), `thumbnails`, `channelTitle`, `tags`, and `contentDetails.caption` (whether captions exist). [Verified] https://developers.google.com/youtube/v3/docs/videos
- It costs 1 quota unit; default quota is 10,000 units/day; an API key is sufficient for public data. [Verified] https://developers.google.com/youtube/v3/docs/videos/list and https://developers.google.com/youtube/v3/getting-started
- **Captions cannot be downloaded for other people's videos.** `captions.download` needs OAuth and "requires the user to have permission to edit the video"; it costs 200 units. [Verified] https://developers.google.com/youtube/v3/docs/captions/download
- YouTube oEmbed returns title, author and thumbnail but no description. [Observed] `https://www.youtube.com/oembed?url=...&format=json`

### Unofficial surface

- `youtube-transcript-api` "uses an undocumented part of the YouTube API, which is called by the YouTube web-client", needs no API key, and warns that "YouTube has started blocking most IPs that are known to belong to cloud providers", producing `RequestBlocked`/`IpBlocked` when deployed to cloud hosts. [Verified] https://github.com/jdepoix/youtube-transcript-api
- yt-dlp can write subtitles and auto-subtitles without downloading video (`--write-subs`, `--write-auto-subs`, `--skip-download`) and extract audio with ffmpeg. Full YouTube support now needs an external JavaScript runtime, and some content needs PO tokens. [Verified] https://github.com/yt-dlp/yt-dlp

### Terms

- API Developer Policies prohibit: to "download, import, backup, cache, or store copies of YouTube audiovisual content without YouTube's prior written approval", to "scrape YouTube Applications ... or obtain scraped YouTube data or content", and to "separate, isolate, or modify the audio or video components". API data may be stored no longer than 30 calendar days without refresh. [Verified] https://developers.google.com/youtube/terms/developer-policies
- YouTube ToS prohibits accessing the service "using any automated means (such as robots, botnets or scrapers)" except for public search engines or with written permission. [Verified] https://www.youtube.com/static?template=terms
- [Inference] The 30-day storage rule applies to API data as such. A recipe the LLM derives from a description is arguably a new work, but this is not a legal opinion; the video-storage ticket should own the conclusion.

## 4. Instagram

### Official surface

- Instagram oEmbed is `GET graph.facebook.com/instagram_oembed`. Documented response fields are only `html`, `provider_name`, `provider_url`, `type`, `version`, `width`. There is no caption, author or thumbnail field. [Verified] https://developers.facebook.com/docs/graph-api/reference/instagram-oembed/
- The reference lists an OAuth access token requirement (error 190 for an invalid token). The "Meta oEmbed Read" feature "Requires App Review". [Verified] https://developers.facebook.com/docs/graph-api/reference/instagram-oembed/ and https://developers.facebook.com/docs/features-reference/meta-oembed-read
- A tokenless request returned HTTP 200 with those six fields in my probe; the embed HTML for the test post contained no caption text. [Observed] This contradicts the documented token requirement, so do not rely on it.
- Use is restricted: "Using metadata and page, post, or video content (or their derivations) from the endpoint for any purpose other than providing a front-end view of the page, post, or video is strictly prohibited." Limits: no private, inactive or age-restricted accounts, no Stories, 1,000 requests/hour. [Verified] https://developers.facebook.com/docs/instagram-platform/oembed
- **Conclusion: no official API gives a third party's Reel caption for recipe extraction.** [Inference from the above]

### Unofficial surface

- yt-dlp supports Instagram but has a long history of "Requested content is not available, rate-limit reached or login required" failures, with the suggested fix being to supply account cookies. [Verified] https://github.com/yt-dlp/yt-dlp/issues/7221 , https://github.com/yt-dlp/yt-dlp/issues/11151 , https://github.com/yt-dlp/yt-dlp/issues/14241
- [Inference] Supplying the owner's own Instagram cookies to a backend scraper puts the owner's personal account at risk of restriction. I recommend against it.

### Terms

- Instagram's Terms of Use prohibit "creating accounts or accessing or collecting information in an automated way without our express permission". [Verified] https://help.instagram.com/581066165581870 (the page did not render for my fetcher; the quote is from the search-engine excerpt of that page)
- Meta's Automated Data Collection Terms require "Meta's express written permission". [Verified] https://www.facebook.com/legal/automated_data_collection_terms
- `instagram.com/robots.txt` opens with a notice that automated collection is prohibited without express written permission. [Observed] https://www.instagram.com/robots.txt

## 5. TikTok

- TikTok oEmbed is `https://www.tiktok.com/oembed?url=<video URL>`, needs no authentication, and returns `title` (the caption, including hashtags), `author_name`, `author_url`, `thumbnail_url` and embed `html`. [Verified] https://developers.tiktok.com/doc/embed-videos/ ; confirmed [Observed].
- The documentation presents this endpoint for embedding. It does not state a restriction equivalent to Meta's display-only clause, and it does not grant permission for other uses either. [Verified absence on that page; interpretation is Inference]
- TikTok ToS prohibits users to "scrape, crawl, export or otherwise extract any data or content in any form, for any purpose, from the Platform using any automated system or software". [Verified] https://www.tiktok.com/legal/page/us/terms-of-service/en
- `tiktok.com/robots.txt` disallows a list of AI user agents entirely. [Observed] https://www.tiktok.com/robots.txt
- Audio or on-screen text requires downloading the video with unofficial tools (yt-dlp), which falls under the ToS clause above. [Inference]

## 6. Share sheet extension (iOS and macOS)

### What Apple documents

- Activation is declared with `NSExtensionActivationRule` keys: `NSExtensionActivationSupportsWebURLWithMaxCount`, `...SupportsWebPageWithMaxCount`, `...SupportsImageWithMaxCount`, `...SupportsMovieWithMaxCount`, or a predicate string for finer control. `TRUEPREDICATE` is for development only and causes App Store rejection. [Verified] https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/ExtensionScenarios.html
- **Safari page content**: in Share extensions on both platforms, Safari can run a bundled JavaScript file (`NSExtensionJavaScriptPreprocessingFile`, global `ExtensionPreprocessingJS`, `run()` with a `completionFunction`) and pass results to the extension. This gives access to the live DOM, including JSON-LD, with the user's own session. [Verified] same page, "Accessing a Webpage"
- **Memory and time**: "Memory limits for running app extensions are significantly lower than the memory limits imposed on a foreground app ... the system may aggressively terminate extensions". Extensions should launch in "well under one second". [Verified] https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/ExtensionCreation.html
- Apple does not publish a numeric limit. React Native's documentation states "Share extensions are limited to 120 MB" and warns that debug builds exceed limits more easily. [Verified as React Native's claim, not Apple's] https://reactnative.dev/docs/app-extensions
- **Long work**: use a background `NSURLSession`; "the transfer can continue, as a low priority task, after your extension completes the host app's request and gets terminated". A shared container (`sharedContainerIdentifier`, app group) is mandatory for this. Other background modes are unavailable to extensions. [Verified] ExtensionCreation.html and ExtensionScenarios.html above
- **Sharing data with the app**: app groups with shared `NSUserDefaults` and shared container. [Verified] ExtensionScenarios.html

### What each app hands over

I found no primary documentation from Instagram, TikTok, YouTube or Tasty describing their share payloads. Everything in this subsection is **[Inference]** and must be confirmed with a throwaway extension that logs `registeredTypeIdentifiers`:

- YouTube, Instagram, TikTok and Tasty apps are expected to share a URL (possibly with accompanying text), not the media.
- Shared links are often short or tracking links (for example `vm.tiktok.com`, `youtu.be`, links with `igsh` parameters) and must be resolved and canonicalised on the backend.
- ReciMe's help pages confirm the user flow goes through the system share sheet from inside Instagram ("Share", then "Share to", then the app) and TikTok ("Share", "More", then the app), which is consistent with URL sharing but does not prove the payload type. [Verified for the flow] https://recime.app/help/en/articles/11596425-import-from-instagram and https://recime.app/help/en/articles/11661452-import-from-tiktok
- Photos and screenshots arrive as image attachments. Decoding several full-resolution images inside the extension is the classic way to hit the memory limit, so images should be copied as files to the shared container rather than decoded. [Inference, supported by the memory guidance above]

### React Native note

React Native's own docs flag extension memory as a concern. [Verified] https://reactnative.dev/docs/app-extensions [Inference] A share extension written natively in Swift with minimal UI avoids loading a JavaScript runtime in a memory-constrained process, regardless of what the main app is built with. This feeds the client-stack decision.

## 7. Cookbook photos

- Vision's `VNRecognizeTextRequest` has a fast path and an accurate path (default, neural-network based), optional language correction and `customWords`. "All of Vision's processing happens on the user's device." [Verified] https://developer.apple.com/documentation/vision/recognizing-text-in-images
- `VNDocumentCameraViewController` provides a page-by-page document scanning UI on iOS 13+ and Mac Catalyst 13.1+. It is not listed for native macOS. [Verified] https://developer.apple.com/documentation/visionkit/vndocumentcameraviewcontroller
- VisionKit `ImageAnalyzer` (Live Text) is available on iOS 16+ and macOS 13+. [Verified] https://developer.apple.com/documentation/visionkit/imageanalyzer
- Crouton advertises "Scan ingredients and steps straight out of your recipe book". [Verified] https://crouton.app - how it is implemented is not documented.
- Mealie and Tandoor send images to an LLM rather than doing classical OCR. [Verified] https://mealie.io/documentation/getting-started/features/ and https://docs.tandoor.dev/features/ai/
- [Inference] OCR output is a flat list of text lines; two-column cookbook layouts, ingredient tables and handwritten notes lose structure. A multimodal LLM sees layout. On-device OCR is free and private; image-to-LLM costs more per import. Recommend prototyping both on five real cookbook pages before deciding.

## 8. How existing apps do social video import

| App | Documented behaviour | Source |
|---|---|---|
| ReciMe | Caption first ("works best when the recipe is written in the caption"), then "detect the recipe from the video's audio", then "locate the original recipe website". Fails on private accounts, login-gated sites, and recipes written in comments. Screenshot import is the documented workaround. | https://recime.app/help/en/articles/11596425-import-from-instagram , https://recime.app/help/en/articles/14773584-why-didn-t-my-recipe-import-correctly |
| Mealie | Classic web scraper first; if it fails, video scraper: yt-dlp fetches title, description and thumbnail; uses existing subtitles if available; otherwise downloads audio, converts to mono MP3 with ffmpeg, transcribes (default OpenAI Whisper); then an LLM builds the recipe from metadata plus transcript. Merged 2026-03-09. | https://github.com/mealie-recipes/mealie/pull/6764 |
| Crouton | Marketing mentions URL import and cookbook scanning. No technical documentation of social import found. | https://crouton.app |
| Community tools | Several independent projects use the same yt-dlp, Whisper, LLM chain. | https://github.com/mealie-recipes/mealie/discussions/5448 |

How ReciMe obtains captions and audio at the network level is not documented. [Inference] Given the official API limits in sections 3-5, commercial apps are very likely using unofficial access or third-party scraping providers.

## 9. Recommended pipeline shape

### Common shape

1. **Capture (device)**: share extension or in-app paste/camera. Extract URL, text, image files, and (Safari only) page HTML/JSON-LD. Write to the app group container. Start a background upload. Dismiss immediately.
2. **Classify (backend)**: resolve redirects, canonicalise, route by host.
3. **Acquire (backend, source-specific)**: cheapest sanctioned source first.
4. **Normalise (backend)**: one LLM step turning whatever text was acquired into the standard recipe format. Skipped or reduced to cleanup when structured data was complete.
5. **Review (device)**: the imported recipe arrives as a draft with its provenance (source URL, which method produced it), because caption and transcript imports will contain errors.

### Per source

| Source | Step 3 order |
|---|---|
| Websites | Device-supplied HTML if present, else backend fetch. JSON-LD/microdata, then site scraper, then LLM over readable text. |
| Tasty | Same, but prefer device-supplied HTML because backend fetches may be refused. |
| YouTube | Data API description. If the description links to a recipe page, run the website path on that link. If the description has no recipe, try transcript. Audio transcription last. |
| TikTok | oEmbed caption. If insufficient, audio transcription or ask the user for a screenshot. |
| Instagram | Attempt caption retrieval; on failure prompt the user immediately for a screenshot or pasted caption. Treat the manual path as the expected path. |
| Cookbook photos | On-device OCR and/or image upload, then LLM structuring. |

### On-device versus backend

| On device | On backend |
|---|---|
| Share sheet capture; Safari DOM extraction; camera and document scanning; Vision OCR; draft review | URL resolution; all platform API calls (keeps API keys off the device); HTML parsing; transcript/audio acquisition; transcription; LLM normalisation |

## 10. Main risks

1. **Terms of service for transcript and audio acquisition.** Downloading audio or fetching transcripts from YouTube, Instagram or TikTok by unofficial means conflicts with the quoted terms. Single-user personal use lowers practical exposure but does not change the terms. The owner should decide this explicitly rather than inherit it from a library choice.
2. **Cloud IP blocking.** Unofficial YouTube transcript access is documented as blocked from major cloud providers; Tasty refused a plain fetch. A backend-only design may fail where a device would succeed. Mitigation: let the device do fetches where it legitimately can.
3. **Instagram fragility.** No sanctioned caption access and unreliable tooling. Mitigation: first-class screenshot and paste-text imports.
4. **Tool churn.** yt-dlp needs frequent updates and now an external JavaScript runtime for YouTube; pinning a version will break over time.
5. **Share extension limits.** Memory ceiling and aggressive termination; a React Native extension is at higher risk than a native one.
6. **LLM errors.** Hallucinated quantities or steps from noisy transcripts. Mitigation: keep provenance and raw source text with the draft, require review.
7. **Incomplete structured data.** Google only requires `name` and `image`, so JSON-LD can be present but lack ingredients or steps; the parser must detect this and fall through.
8. **Unverified share payloads.** All per-app payload assumptions are inference until logged from a real device.

## 11. Open questions and new decisions surfaced

1. Is the owner willing to use unofficial acquisition (yt-dlp, undocumented transcript endpoints) at all, or should V1 be restricted to sanctioned sources plus manual fallbacks?
2. Python component for `recipe-scrapers`, or TypeScript JSON-LD parsing plus LLM fallback?
3. Native Swift share extension even if the app is React Native?
4. Cookbook photos: on-device OCR plus text LLM, or image straight to a multimodal LLM? (Depends on the AI cost ticket.)
5. Prototype needed: a logging share extension to record the actual payload from YouTube, Instagram, TikTok, Tasty, Safari, Chrome and Photos.
6. Mac import: is the macOS share extension required in V1, or is paste-URL enough on Mac? `VNDocumentCameraViewController` is not available on native macOS.
