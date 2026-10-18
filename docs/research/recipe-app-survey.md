# Recipe app survey

Research for issue #9. Sources fetched 2026-09-29. Feeds the UX prototypes and the standard recipe format decision.

## Summary

- **Import is a solved pattern; copy it.** Every serious app takes recipes from the share sheet, and the social-video apps run a layered fallback: caption or description text first, then the original recipe website, then subtitles or audio, and only then heavier analysis. Mealie's open-source pipeline (structured data, then video transcript, then LLM on page text, then OpenGraph) is a working reference.
- **Review before save is inconsistent across apps and matters most where AI is involved.** Honeydew and Paprika 4 put a review form at the end of every import. Flavorish openly fills gaps with an AI "suggested recipe", which is the failure mode to avoid.
- **Internal recipe models are richer than interchange formats.** schema.org/Recipe, Mela, and Paprika all store ingredients as free text. Mealie and Tandoor store quantity, unit, food, and note, and keep the original text next to the parsed values.
- **Weekly picks from your own library exist only in simple forms.** Crouton, Pestle, Mealie, and Tandoor pick at random (optionally filtered). AnyList's Ideas tab uses ratings and planning history. None sends a scheduled notification with a configurable count of picks.
- **Nobody remembers "this alias means that store product".** Aliases stop at a generic food (Mealie, Tandoor, Cooklang). Store hand-offs are one-way and re-match products each time. This is KitchenMate's clearest differentiator.
- **H-E-B is nearly absent.** AnyList is the only surveyed app whose own docs name H-E-B, and its flow is manual: the user signs in and picks each product by hand. Instacart carries H-E-B, but an Instacart hand-off creates an Instacart cart, not items in the owner's H-E-B account.
- **Reminders integration runs in three different directions.** Mela uses a Reminders list as its grocery list. Paprika exports to Reminders. AnyList imports from Reminders on app launch and then deletes the reminders. None converts reminders into store products.

## How to read this document

Each claim carries a source key in brackets, listed under [Sources](#sources). Claims are first-party unless marked otherwise.

| Marker | Meaning |
|---|---|
| (no marker) | Seen on a first-party page or in source code |
| *inferred* | My reading of the evidence; reason given |
| *unverified* | Seen only in a search snippet or a user review, or sources conflict |
| *not found* | Looked in the first-party pages and did not find it. This does not prove the app lacks the feature |

Limits of this research:

- It is desk research. No app was installed or tested.
- Many pages were read through a fetch tool that summarises content. Wording is paraphrased; re-open the source before quoting verbatim.
- Samsung Food's website and help centre refused automated requests (HTTP 403), so its coverage comes from the App Store listing and Samsung Newsroom only.
- Prices are US prices as listed on the fetch date.

## Apps surveyed

| Group | Apps |
|---|---|
| Owner's reference apps | Crouton, ReciMe |
| Apple-first recipe managers | Paprika, Mela, Pestle |
| Social video importers | Honeydew, Flavorish, Deglaze |
| Grocery and meal-plan apps | AnyList, Mealime, Samsung Food (formerly Whisk), eMeals (H-E-B note only) |
| Open source | Mealie, Tandoor |
| Formats and hand-off APIs | schema.org/Recipe, Google recipe structured data, Cooklang, recipe-scrapers, Mela format, Paprika format, Instacart Developer Platform |

## Feature comparison

"Yes" means documented first-party. "-" means not found in first-party pages.

### Import

| App | Web URL | Share sheet | Social video | What social import reads | Photo / cookbook scan | Review before save |
|---|---|---|---|---|---|---|
| Crouton | Yes (copied URL) | - | - | - | Yes (OCR and AI, multi-photo, PDF) | - |
| ReciMe | Yes | Yes | IG, TikTok, FB, Pinterest, YouTube | Caption, then audio, then original website | Yes | Photo and screenshot paths only |
| Paprika 3 | Yes (in-app browser) | Yes | - | - | - | - |
| Paprika 4 (beta) | Yes | Yes | TikTok, IG, FB, YouTube | Post text only | Yes (multi-photo) | Yes, recipe form |
| Mela | Yes (in-app browser) | Yes | YouTube, TikTok, IG | Video description text | Yes (select text blocks) | Read-only preview |
| Pestle | Yes (in-app browser) | Yes | IG, TikTok, FB, YouTube | Not stated | Yes (Pro) | Failed imports become bookmarks |
| Honeydew | Yes | Yes | TikTok, IG, YouTube, FB, Pinterest | Caption, audio, on-screen text, description, pinned comments | Yes | Yes, every path |
| Flavorish | Yes (bulk, 20 URLs) | Yes | IG, FB, TikTok, YouTube | Caption, audio, AI gap-fill | Yes | Edit after save |
| Deglaze | Yes | Yes | IG and others | Caption, audio, overlays, frames | - | Edit after save |
| AnyList | Yes | Yes | - | - | - | - |
| Mealime | Yes (paste URL) | - | - | - | - | - |
| Samsung Food | Yes | *unverified* | - | - | Yes | - |
| Mealie | Yes | Via Apple Shortcut | YouTube, Instagram named | Subtitles, then audio transcription | Yes (AI, multi-photo) | Yes (debugger, ingredient parse review) |
| Tandoor | Yes | - | YouTube metadata only | Title and description | Yes (AI: images, PDF, text) | *inferred* yes |

### Cooking, planning, grocery

| App | Cook mode | Meal plan | Picks from own library | Grocery list | Store hand-off | Remembered item preferences |
|---|---|---|---|---|---|---|
| Crouton | Yes (timers, gestures, Live Activities, SharePlay) | Yes | Random auto-generate, smart folders | Yes, Reminders integration | - | - |
| ReciMe | Yes (Plus) | Yes | - | Yes, by aisle or recipe | Redirect to unnamed partner | - |
| Paprika | Yes (timers, cross-off, scale, convert) | Yes, reusable menus | - | Yes, aisles, merging, pantry | - | Aisle per ingredient |
| Mela | Yes (timers, multi-recipe) | Yes, stored in Calendar | - | Is a Reminders list | None, by design | - |
| Pestle | Yes (hands-free, SharePlay, Live Activities) | Yes (Pro), 14 days | Random pick; Siri "what to make for dinner" | Yes, pantry auto cross-off | - | Pantry staples |
| Honeydew | - | Yes | "Smart suggestions", AI meal plan | Yes, by store section, shared | Instacart cart (Plus) | - |
| Flavorish | Yes (multi-recipe) | Yes | - | Yes, merging, roles | - | - |
| Deglaze | Yes (timers, audio) | Yes (Pro) | - | Yes, learns staples | "Delivery in select locations" | Learns manually added items |
| AnyList | Yes (timers, recipe switcher) | Yes, templates, iCal | Ideas tab (ratings and history) | Yes, merging, per-store categories | Instacart, Walmart, Kroger, Safeway, Albertsons, Amazon Fresh, H-E-B | Favourites remember photo, price, store |
| Mealime | Yes (hand-wave advance) | Yes | Auto-builder (curated recipes) | Yes, by department | Kroger, Walmart, Amazon Fresh, Instacart | Diet and dislikes only |
| Samsung Food | Yes (Premium) | Yes | AI weekly plans (Premium) | Yes, shared | "23 integrated retailers" | Preferred store (*unverified*) |
| Mealie | Yes (wake lock, split view) | Yes | Random per slot, with rules | Yes, merging, labels | - | Food and unit aliases, on hand |
| Tandoor | - | Yes | Auto-planner, random by keyword | Yes, per-supermarket category order | - | Alias automations, category per food |

### Platforms and pricing

| App | iPhone | iPad | Mac | Other | Sync | Pricing (US) |
|---|---|---|---|---|---|---|
| Crouton | Yes | Yes | Yes | Watch, Vision | iCloud | Free; Plus $24.99; Discover $1.99/mo or $14.99/yr |
| ReciMe | Yes | Yes | iPad app on Apple silicon (*inferred*) | Android, web, Chrome ext. | Account | Free, 5 imports/week; Plus $39.99/yr |
| Paprika 3 | Yes | Yes | Yes (separate purchase) | Android, Windows | Paprika Cloud Sync | iOS $4.99 one-time; desktop $29.99 regular |
| Mela | Yes | Yes | Yes (separate app) | - | iCloud | iOS $6.99, Mac $14.99, one-time |
| Pestle | Yes | Yes | iPad app on Apple silicon | Watch, Vision, Chrome ext. | Developer backend (*inferred*) | Free to 15 recipes; Pro $2.99/mo, $24.99/yr, lifetime $39.99 to $49.99 |
| Honeydew | Yes | Yes | iPad app on Apple silicon (*inferred*) | Android, Chrome ext. | Account | Free limited; $6.99/mo or $39.99/yr |
| Flavorish | Yes | Yes | - | Android, web | Account | Free, 5 social imports; $4.99/mo or $49.99/yr |
| Deglaze | Yes | Yes | - | Android, web, Vision | Account | Free, 5 imports/week; Pro $49.99/yr |
| AnyList | Yes | Yes | Yes (Complete) | Android, web, Watch | Account | Free; Complete $9.99/yr, household $14.99/yr |
| Mealime | Yes | Yes | iPad app on Apple silicon | Android | Account | Shutting down 2026-10-21 |
| Samsung Food | Yes | Yes | iPad app on Apple silicon | Android, web, Family Hub | Account | Free; Food+ $6.99/mo or $59.99/yr |
| Mealie | PWA | PWA | PWA | REST API | Self-hosted server | Free, AGPL-3.0 |
| Tandoor | PWA | PWA | PWA | REST API | Self-hosted server | Free self-hosted; hosted EUR 0 to 4.99/mo |

Only Crouton, Mela, Paprika, and AnyList document a real Mac app. The rest are iPad apps running on Apple silicon, or web apps.

## App by app

### Crouton (reference app)

Documentation is thin: one marketing page, a press kit, and the App Store listing with its version history.

| Area | Findings |
|---|---|
| Import | Imports from copied URLs [C-SITE]. Scans cookbook pages with OCR and AI; "Smart Import" takes a single photo, plain text, or several photos [C-AS]. PDF import added 2025.8.1 [C-AS]. RSS feeds of recipe sites [C-AS]. Version 2026.4 accepts schema.org Recipe JSON or JSON-LD by paste, file, or ZIP [C-AS]. Share sheet and social video import: *not found*. |
| Review | No documented review screen. Related: section suggestions, splitting long steps into smaller ones, stripping markdown from imports [C-AS]. |
| Format | Native `.crumb` files; structure is undocumented. Bulk export as Crouton files, PDF, plain text, or Markdown [C-AS]. Fields mentioned: ingredients, steps, images, folders, tags, notes, sources, servings, times, nutrition, linked recipes as ingredients [C-AS]. |
| Cook mode | One step at a time; tap an ingredient inside a step to see its quantity [C-AS]. Highlights ingredients, times, and temperatures in step text [C-AS]. Hands-free by wink [C-PRESS] or thumb gesture [C-AS]. Timers detected from step text, self-naming, Live Activities, SharePlay, multi-recipe sessions [C-AS]. |
| Planning | Weekly planner; auto-generated plans from stored recipes; random generation can draw from smart folders [C-SITE] [C-AS]. "Make-ahead" badges flag recipes needing marinating or thawing [C-AS]. Shortcuts actions to find empty dates and add recipes [C-AS]. |
| Grocery | List built from recipes; "Integrates with Reminders" [C-AS]. Direction of the Reminders sync: *not found*. Aisle grouping, merging, store integrations: *not found*. |
| Preferences | *Not found*. |
| Video | *Not found*. |

Standout ideas: tap-ingredient-in-step quantities, make-ahead badges, scale by a chosen ingredient amount, schema.org JSON-LD as a paste-in format.

### ReciMe (reference app)

| Area | Findings |
|---|---|
| Import | Instagram, TikTok, Facebook, Pinterest, YouTube via the share sheet [R-SITE] [R-IG] [R-TT] [R-YT]. Chrome extension for web [R-EXT]. Screenshots and camera scans [R-SHOT] [R-SCAN]. Imports from Paprika, Notes, Google Docs, Notion, Evernote [R-WHAT]. |
| Extraction order | Instagram and TikTok: caption, then video audio, then the original recipe website [R-IG] [R-TT]. YouTube: description, then original website, then audio [R-YT]. Limits: public posts only, caption not comments, one recipe per post [R-WHY]. |
| Review | Screenshot and camera imports show an edit screen where each ingredient and step sits on its own line [R-SHOT] [R-SCAN]. No review step is described for social imports. |
| Format | Nutrition (calories, protein, carbs, fats), scaling, unit and temperature conversion [R-AS] [R-MOST]. Source link kept in Recipe Notes [R-SRC]. PDF export and print are Plus features [R-PLUS]. Structured export: *not found*. |
| Cook mode | Step-by-step, hands-free; Plus feature [R-PLUS]. |
| Planning | Weekly planner by meal type, free [R-WHAT]. Suggestions: *not found*. |
| Grocery | Ordered by aisle or by recipe [R-SITE]. "Grocery Checkout": review the list, deselect what you own, pick a partner, get redirected to the partner's site [R-CHECKOUT]. Partner names: *not found*. |
| Preferences | *Not found*. |
| Video | Link back to the source only [R-SRC]. |
| Pricing | Free tier has 5 imports per week; planner and grocery are free [R-FREE]. Plus $39.99/yr [R-PRICE]. |

Standout ideas: the documented fallback chain, including "find the original website"; deselect-what-you-have before hand-off.

### Paprika 3 and Paprika 4 beta

Paprika 4 opened its beta to all current users on 2026-09-28. New features will need a subscription after the beta; no price is announced [P-NEWS].

| Area | Findings |
|---|---|
| Import (v3) | In-app browser with a Download button; Safari share extension; clipboard tools that let the user mark selected text as name, ingredients, or directions when parsing fails [P-IOS]. Many legacy file formats [P-MAC]. |
| Import (v4) | Scanning from camera, photos, files, or clipboard, with several photos forming one recipe; text is sorted into fields and shown in the recipe form for review [P4-SCAN]. Social import from TikTok, Instagram, Facebook, YouTube reads the post text; audio or transcript extraction is not documented [P4-BROWSER]. Pasted text is sorted into fields [P4-ADD]. Duplicate warning on clip [P4-BROWSER]. |
| Format | Name, difficulty, servings, prep/cook/total time, rating, categories, source, source URL, description, notes, nutrition, ingredients (headings by trailing colon), directions, photos [P-IOS]. Exports HTML and `.paprikarecipes`, described as a zip of gzipped JSON [P-IOS]. Documented YAML import format [P-MAC]. Ingredients are free text. |
| Cook mode | Screen stays on, cross off ingredients, tap to highlight the current step [P-SITE]. Timers detected in directions [P-IOS]. Scaling and US/metric conversion carry into the grocery list [P-IOS]. Pinned recipes keep their cook state [P-IOS]. |
| Planning | Daily, weekly, monthly planner; reusable multi-day menus; export to Calendar [P-IOS]. Suggestions: *not found*. |
| Grocery | Sorted by aisle; similar ingredients combined; pantry items start unchecked when a recipe is added [P-SITE] [P-IOS]. |
| Reminders | Export only, to a Reminders list named "Paprika" by default [P-IOS]. Siri can add items to the Paprika list [P-IOS]. |
| Store hand-off | None documented [P4-GROC]. |
| Preferences | Remembers and syncs the aisle the user assigns to an ingredient [P-IOS]. |

Standout ideas: clipboard tools as a deterministic fallback; pinned recipes that keep cook state.

### Mela

The best documented indie app. No release since 2.6.2 on 2025-06-08 [M-AS].

| Area | Findings |
|---|---|
| Import | In-app browser shows the detected recipe beside the page [M-SITE] [M-HELP]. Share extension needs only a link [M-HELP]. Extracts recipes from video descriptions on YouTube, TikTok, and Instagram, with advice to verify the result [M-AS]. RSS feeds land in an inbox, separate from the collection [M-HELP]. Site metadata first, on-device ML fallback [M-HELP]. |
| Scan | User drags over text blocks on the scanned page; Mela guesses each block's type and the user confirms [M-HELP]. |
| Format | Published spec. `.melarecipe` is JSON: id, title, text, images (base64), categories, yield, prepTime, cookTime, totalTime, ingredients, instructions, notes, nutrition, link [M-FMT]. Ingredients are one newline-separated string, `#` lines are group titles, parsed at display time [M-FMT] [M-HELP]. |
| Cook mode | Full screen, current step emphasised, check off ingredients, timers, several recipes in one session [M-SITE]. Planned recipes for today and tomorrow are offered first [M-AS]. |
| Planning | Plan entries are stored in the system Calendar [M-SITE]. Suggestions: *not found*. |
| Grocery | The grocery list is a Reminders list, named "Mela" by default and selectable in settings [M-HELP]. It syncs through Reminders and works on devices without Mela [M-SITE]. |
| Store hand-off | None; the app uses no third-party service [M-SITE]. |
| Pricing | One-time purchase per platform [M-AS] [M-AS-MAC]. |

Standout ideas: delegating grocery and plan storage to Reminders and Calendar; an open file format; the select-blocks scan flow.

### Pestle

| Area | Findings |
|---|---|
| Import | Share sheet from websites and from Instagram, TikTok, Facebook, YouTube [PE-AS]. Processing runs on the device [PE-IG]. In-app browser shows a recipe card when it detects a recipe [PE-BROWSER]. Scanner, image, and PDF import are Pro [PE-PRO]. Imports from Paprika, Crouton, Mela, Pepperplate [PE-AS]. |
| Failure handling | A failed import is saved as a bookmark. The "Highlighter" converts it: select ingredients on the page, then steps, then save [PE-DOCS]. If only the name is missing, the app asks for it [PE-DOCS]. |
| Format | Exports the cookbook as a zip of Markdown files [PE-BROWSER]. No published schema. |
| Cook mode | Guided steps, hands-free control, multiple timers, Live Activities, SharePlay step sync [PE-AS] [PE-SITE] [PE-DOCS]. "Heads Up" warns about long marinating or resting times before starting [PE-PRO]. |
| Planning | 14-day planner; add from the cookbook, pick a random recipe, or add a note [PE-PLAN]. Calendar sync [PE-SITE]. Siri "what to make for dinner" [PE-AS]. Pro feature [PE-PRO]. |
| Grocery | Add all ingredients, tap to remove those you have [PE-AS]. Pantry staples are crossed out by default on new lists [PE-PANTRY]. Reminders integration: *not found*. |
| Preferences | Pantry only. |

Standout ideas: failed import degrades to a recoverable bookmark; pantry auto cross-off; lead-time warnings.

### Honeydew

| Area | Findings |
|---|---|
| Import | TikTok, Instagram, YouTube, Facebook, Pinterest, websites, photos, screenshots, notes, cookbook scans [H-SITE] [H-DOCS]. Instagram: captions and on-image text for photos, video analysis for Reels [H-IG]. YouTube: speech, on-screen text, description, pinned comments [H-YT]. Two-page recipes are scanned separately and combined [H-SCAN]. |
| Review | Every flow ends in "Review and save" [H-IG] [H-YT]. |
| AI edit | Natural-language edits ("make this vegan") show a modified recipe to save or discard [H-AIEDIT]. |
| Assistant connector | An MCP connector lets Claude or ChatGPT search recipes, add to the meal plan, and add ingredients to the grocery list [H-MCP]. |
| Planning | Drag-and-drop calendar with suggestions based on preferences [H-SITE]; AI meal planning [H-AS]. |
| Grocery | Sorted by store section, scaled to servings, pantry check, shared in real time, works offline [H-GROC]. |
| Store hand-off | Plus subscribers export the list to an Instacart cart [H-GROC]. Product matching details: *not found*. |
| Video | Keeps a link to the original post; the saved recipe survives if the post disappears [H-SRC]. |
| Pricing | $6.99/mo or $39.99/yr [H-AS]. Honeydew's own blog quotes older prices; treated as stale. |

### Flavorish

| Area | Findings |
|---|---|
| Import | Instagram, Facebook, TikTok, YouTube via share sheet; uses the caption or the spoken audio [F-BLOG]. Bulk import of up to 20 URLs [F-HELP]. Photos and pasted text [F-SITE] [F-HELP]. |
| AI gap-fill | When the post has no complete recipe, the app may generate a suggested recipe from the dish name, caption, and hashtags [F-BLOG]. |
| Review | Edit after saving [F-BLOG]. |
| Format | Exports a zip of all recipes, images, and collections; inner format *not found* [F-HELP]. |
| Cook mode | Screen awake, strike off ingredients and steps, switch between several recipes [F-COOK]. |
| Grocery | Sort by aisle, recipe, or manual order; similar ingredients combined; viewer and editor roles [F-GROC]. Store hand-off: *not found*. |
| Pricing | Free tier: 5 social, image, or text imports; period not stated. Premium $4.99/mo or $49.99/yr [F-SITE] [F-AS]. |

### Deglaze (brief)

- Reads four signals: caption, full audio transcript, text overlays, and video frames [D-IG].
- Import runs in the background after sharing; editing happens afterwards [D-IG].
- Grocery list learns manually added items and suggests staples [D-SITE].
- Free plan has 5 imports per week; Pro is $49.99/yr [D-AS].

### AnyList

| Area | Findings |
|---|---|
| Import | Share extension from browsers and apps; desktop browser extensions; Paprika file import [A-IMPORT] [A-PAPRIKA]. Free tier limited to 5 web imports [A-IMPORT]. Photo and social import: *not found*. |
| Cook mode | Mark off ingredients, highlight a step, tap a detected time to start a timer [A-COOK] [A-AS]. Recipe switcher is pre-filled with the day's planned recipes [A-COOK]. Scaling changes only the quantity field [A-SCALE]. |
| Planning | Calendar, templates of 1 to 31 days, iCalendar subscription [A-START] [A-TEMPL] [A-ICAL]. |
| Suggestions | Ideas tab suggests the user's own recipes from ratings and planning history, in groups such as "Forgotten Favorites" [A-IDEAS]. No automatic plan generation. |
| Grocery | Autocomplete, automatic categories, recipe ingredients combined into one item with a total, link back to the source recipe [A-ADD] [A-START]. |
| Reminders | Import only. The user enables it and picks lists. On next app launch AnyList checks those Reminders lists, prompts to import, then deletes the reminders. AnyList calls this an advanced feature and recommends Siri Shortcuts instead [A-REM]. |
| Store hand-off | Instacart, Walmart, Kroger, Safeway, Albertsons, Amazon Fresh, H-E-B. US only, mobile only. The user signs in with their own retailer account, then for each list item picks a search result, adds it to the cart, and taps Next [A-SHOP]. |
| Preferences | Favourites remember changes to an item such as photo, price, and store [A-FAV]. Category sets give the same item a different category per store [A-CATS]. Remembered product choices: *not found*. |
| Pricing | Complete $9.99/yr, household $14.99/yr [A-COMPLETE]. |

Standout ideas: per-store category sets; Reminders as an inbox drained with a confirmation prompt; guided item-by-item shopping.

### Mealime

Mealime will be discontinued on 2026-10-21 and all personal data deleted. Albertsons acquired it in 2021 [ME-CLOSE]. It is included for its patterns only.

- **Auto-builder.** The user picks a meal count; the app suggests a set, shows a food-waste indicator, and lets the user swipe for alternatives. The user can seed a few recipes and let the app pick the rest [ME-START].
- **Cook mode.** One instruction at a time; advance by waving a hand over the screen [ME-COOK].
- **Grocery.** Combined by department; first step is to check off what you already have [ME-GROC].
- **Store hand-off, by depth** [ME-START]:

| Retailer | Behaviour |
|---|---|
| Kroger | Pre-selects products in the right quantities and adds them to the cart |
| Walmart | Searches each ingredient; user steps through results |
| Amazon Fresh | One-tap list transfer |
| Instacart | Transfers to Instacart's mobile site; user adjusts quantities |

### Samsung Food (formerly Whisk)

Coverage is limited; see the note under [How to read this document](#how-to-read-this-document).

- Saves recipes from any website and from photos of cookbooks or handwritten recipes [S-AS].
- "Smart Cooking Mode" with serving and unit changes inside cook mode; Premium [S-AS].
- AI-personalised weekly meal plans, prioritising pantry items near their use-by date [S-AS] [S-NEWS24].
- Grocery delivery from "23 integrated retailers across 4 regions"; retailers not named [S-AS]. H-E-B: *not found*.
- Pantry ("Food List") filled from a photo [S-NEWS24].

### Mealie (open source, AGPL-3.0)

| Area | Findings |
|---|---|
| Scraper chain | Ordered strategies; the first that returns a recipe wins: recipe-scrapers, then video transcription, then LLM on page text, then OpenGraph [MI-SCRAPER]. |
| AI import | One page accepts any mix of URL, pasted text or HTML or JSON, and images. Several photos are pages of one recipe. Pasted content wins where sources disagree [MI-AI]. Works with any OpenAI-compatible API [MI-AI]. |
| Video | Uses yt-dlp. Transcript order: existing transcript, then subtitles, then AI audio transcription. Title, description, and thumbnail are captured [MI-TRANS]. Docs name YouTube and Instagram [MI-AI]; TikTok support is *inferred* from yt-dlp coverage. |
| Review | Recipe Debugger shows raw scraper output [MI-DEBUG]. Ingredient parsing is a separate review step with per-field confidence and suggested food matches [MI-FAQ] [MI-ING]. |
| Tags | AI-suggested tags are matched to existing ones; unmatched ones are dropped unless the user opts in [MI-AI]. |
| Cook mode | Split view, keep-screen-awake switch [MI-FAQ]. Timers: *not found*. |
| Random meal | One slot at a time. Rules are `{day, entry_type, query filter}`; matching rules are merged and one recipe is drawn at random [MI-PLAN]. No recency weighting built in. |
| Shopping list | Items keep references to the recipes that produced them. Items merge when food matches and units are equal or convertible [MI-SHOP]. Ordering by label, per list [MI-SHOP]. |
| Platforms | PWA and REST API [MI-INTRO] [MI-API]. A community Apple Shortcut adds a share-sheet entry and sends the rendered page HTML [MI-SHORTCUT]. |

### Tandoor (open source, AGPL-3.0 plus Commons Clause)

| Area | Findings |
|---|---|
| Import | recipe-scrapers for URLs; bookmarklet for pages behind a login; AI import of images, PDFs, and text through LiteLLM, with a monthly spend limit per space [T-API] [T-AI]. YouTube import takes title, thumbnail, and description only [T-URLIMPORT]. Imports from 20+ apps including Mela, Paprika, Pestle, Cooklang [T-IMPORT]. |
| Model | Ingredients belong to steps, not to the recipe. Steps can be whole sub-recipes. Step text can template ingredient amounts so they scale [T-MODELS] [T-TEMPL]. |
| Auto-planner | For a date range of up to 14 days: filter by keyword, order randomly, assign one recipe per day, optionally add to the shopping list [T-API]. |
| Shopping list | A supermarket is an ordered list of categories; each food has one category; dragging a food into a category is remembered [T-MODELS] [T-SHOP]. Items can be delayed for some hours instead of deleted [T-MODELS]. Checking off can mark a food on hand [T-MODELS]. |
| Cook mode | *Not found*. |

## Recipe formats

This section feeds the standard recipe format decision.

| Format | Ingredients | Ingredient sections | Step sections | Step-to-ingredient link | Times | Video |
|---|---|---|---|---|---|---|
| schema.org / Google | Free text | None | HowToSection | None | ISO 8601 | VideoObject or Clip, also per step |
| recipe-scrapers output | Free text | `ingredient_groups` | Flattened | None | Minutes | None found |
| Mela | Free text | `#` lines | `#` lines | None | Strings | None |
| Paprika YAML | Free text | None | None | None | Strings | None |
| Cooklang | Structured, inline in steps | Via sections | `= Name =` | Inherent | Metadata strings, timers | None found |
| Mealie internal | quantity, unit, food, note, original_text | `title` on ingredient | `title` on step | `reference_id` list | Strings and seconds | None (iframe in markdown) |
| Tandoor internal | amount, unit, food, note, original_text | `is_header` rows | Step `name` | Ingredients belong to steps | Minutes | None |

Sources: [SCHEMA] [GOOGLE] [RS] [M-FMT] [P-MAC] [COOKLANG] [MI-ING] [MI-STEP] [T-MODELS].

What this implies:

- **schema.org/Recipe is the import and export boundary.** It is what recipe sites publish and what recipe-scrapers, Mealie, and Crouton accept [GOOGLE] [MI-AI] [C-AS].
- **It is too weak to be the internal model.** It has no structured ingredients and no ingredient sections [SCHEMA].
- **Both open-source apps keep `original_text` beside parsed fields** [MI-ING] [T-MODELS]. That makes re-parsing and review possible.
- **No surveyed format has a first-class video field except schema.org.** KitchenMate needs one for its video sources.
- **Licences.** recipe-scrapers is MIT [RS]. Mealie and Tandoor are AGPL [MI-LICENSE] [T-LICENSE]; use them for ideas, not copied code.

## How aliases and item preferences are modelled

| App | Model | Points to |
|---|---|---|
| Mealie | Alias rows under a food or unit. One lookup built from name, plural name, and all aliases, with fuzzy fallback (threshold 85 for foods). UI offers "add as alias" [MI-ING] [MI-MATCH] | Food id |
| Tandoor | Alias is a row in a generic automation table: match string, replacement string. Created by dragging one food onto another. Also "never unit" and "transpose words" rules [T-AUTO] | Food name (string) |
| Cooklang | Synonyms in the aisle config, separated by a pipe character [COOKLANG-CONV] | Item name |
| Paprika | Remembers aisle per ingredient [P-IOS] | Aisle |
| AnyList | Favourites remember photo, price, store; category per store [A-FAV] [A-CATS] | Item details |
| Deglaze | Learns manually added items [D-SITE] | Item |
| Pestle, Mealie, Tandoor, Paprika | Pantry or "on hand" flags [PE-PANTRY] [MI-ING] [T-MODELS] [P-IOS] | Food |

None maps an alias to a specific product at a specific store. Instacart's own guidance tells partners not to build their own product mapping [IC-FAQ].

## Store hand-off patterns

| Pattern | Example | Lands in the user's retailer account? |
|---|---|---|
| Redirect to a partner site with the list | ReciMe [R-CHECKOUT], Samsung Food [S-NEWS23] | Partner's cart |
| Instacart link | Honeydew [H-GROC], Instacart Developer Platform [IC-RECIPE] | Instacart cart, not the retailer's |
| Retailer API that pre-selects products | Mealime with Kroger [ME-START] | Yes |
| User signs in to the retailer and picks each product | AnyList, including H-E-B [A-SHOP] | Yes |

Instacart Developer Platform details:

- The app sends a title and ingredients. Each ingredient has a name used as a search term, measurements, optional brand and health filters, and optional product ids or UPCs [IC-RECIPE].
- The response is one URL to an Instacart-hosted page. The user picks a store and adds items to the cart there [IC-TUTORIAL].
- H-E-B has an Instacart storefront, marked as priced higher than in store [IC-HEB].
- Two first-party pages conflict on whether a link can preselect a retailer [IC-TUTORIAL] [IC-FAQ].

H-E-B itself offers shoppable recipes and shopping lists that push to its cart [HEB-RECIPES] [HEB-LISTS]. A public H-E-B API was *not found*. eMeals names H-E-B in its App Store description, but its website lists H-E-B only under Instacart [EM-AS] [EM-WEB].

## Patterns worth borrowing

These are recommendations, not sourced facts.

### 1. Recipe import

| Pattern | Seen in |
|---|---|
| Share sheet as the main entry point; pasting a URL as the fallback | All |
| Layered extraction: structured data, then caption or description, then the original recipe site, then subtitles, then audio transcription | ReciMe, Mealie |
| Read pinned comments and on-screen text for video | Honeydew, Deglaze |
| One review form at the end of every import path | Honeydew, Paprika 4 |
| Never invent missing quantities; flag gaps instead | Counter-example: Flavorish |
| Failed import becomes a bookmark that can be converted later | Pestle |
| Manual fallback: mark selected text as ingredients or steps | Paprika, Pestle, Mela |
| Several photos form one recipe | Paprika 4, Mealie, Crouton, Honeydew |
| Pasted user text overrides machine sources | Mealie |
| Keep the source link; keep the recipe if the source disappears | Honeydew, ReciMe |
| Duplicate warning on import | Paprika 4 |
| Background processing with progress messages | Deglaze, Mealie |
| Store parsed ingredient fields plus the original text | Mealie, Tandoor |
| Match AI-suggested tags to existing tags | Mealie |

### 2. Grocery list from recipe ingredients

| Pattern | Seen in |
|---|---|
| Choose which ingredients to add; "on hand" items start unchecked rather than dropped | Mealie, Paprika, Pestle |
| Merge by food with unit conversion; keep links to source recipes | Mealie, AnyList |
| Scaled servings carry into the list | Paprika, Honeydew |
| Review step before hand-off to deselect what you own | ReciMe, Mealime |
| Group by store section | Most |
| Show hand-off depth honestly: which items matched, which need a choice | Mealime (Kroger versus Walmart) |

### 3. Weekly picks

| Pattern | Seen in |
|---|---|
| Random draw filtered by saved rules (tag, weekday, meal type) | Mealie |
| Draw from a smart folder | Crouton |
| Use ratings and cooking history; surface "forgotten favourites" | AnyList |
| Seed a few choices, let the app fill the rest, swap any pick | Mealime |
| Flag lead-time steps such as marinating | Crouton, Pestle |
| One action to send the picks to the grocery list | Tandoor |
| Track "last made" to avoid repeats | Mealie (field exists, not used by the random pick) |

### 4. Reminders to store items

| Pattern | Seen in |
|---|---|
| User selects which Reminders list to read | AnyList, Mela |
| Treat Reminders as an inbox: import, then remove or complete the reminder | AnyList |
| Confirm before importing | AnyList |
| Reading Reminders needs the app on a device | AnyList checks on launch |
| Apply aliases when parsing free-text input | Tandoor |
| Watch for split phrases such as "mushroom soup" | AnyList's Siri note [A-SIRI] |

### 5. Item mappings

| Pattern | Seen in |
|---|---|
| Alias rows that point to an id, not a name | Mealie |
| One normalised lookup over name, plural, and aliases, with fuzzy fallback | Mealie |
| "Add as alias" offered at the moment of correction | Mealie |
| Merge or drag one item onto another to create an alias | Tandoor |
| Rules for systematic parser mistakes | Tandoor |
| Per-store data for the same item | AnyList |
| "Ignore for shopping" flag for items like water | Tandoor |

## Gaps none of them fill

1. **Alias to specific store product.** No app remembers that "milk" means one particular product at one store and reuses it next time.
2. **Automatic delivery into the owner's H-E-B account.** The only H-E-B flow found is AnyList's manual one. Instacart does not reach the H-E-B account.
3. **Scheduled weekly picks with a notification and a configurable count.** Existing features are on-demand buttons or whole-plan generators.
4. **Unattended Reminders conversion.** AnyList imports only on launch with a prompt, and produces list items, not store products.
5. **First-class video in the recipe.** Apps keep a link back. None documents embedded playback or step-level timestamps.
6. **A native Mac app with social video import.** The apps with real Mac apps (Crouton, Mela, Paprika 3, AnyList) are weak on social import; the social importers are phone-first.
7. **Recency-aware picks.** No documented picker avoids recent repeats by default.

## Open questions

| Question | Why it matters |
|---|---|
| How does Crouton's Reminders integration work, and does it have a share extension? | Reference app; first-party pages do not say. Needs hands-on testing |
| What happens in ReciMe after a social import: is there a review screen? | Reference app; undocumented |
| How does AnyList reach H-E-B: embedded web view of heb.com? | Shows what is feasible without an API |
| Does frame or on-screen text analysis add enough over caption plus transcript to justify its cost? | Affects the import cost budget |
| Should the grocery list live in Reminders, as Mela does, or in the app's own store? | Shapes features 2 and 4 |
| Does Instacart's link accept a preselected retailer? | Only relevant if Instacart becomes a fallback |

## Sources

### Crouton
- [C-SITE] https://crouton.app
- [C-PRESS] https://crouton.app/press-kit.html
- [C-AS] https://apps.apple.com/us/app/crouton-recipe-manager/id1461650987

### ReciMe
- [R-SITE] https://www.recime.app
- [R-AS] https://apps.apple.com/us/app/recime-recipes-meal-planner/id1593779280
- [R-IG] https://recime.app/help/en/articles/11596425-import-from-instagram
- [R-TT] https://recime.app/help/en/articles/11661452-import-from-tiktok
- [R-YT] https://recime.app/help/en/articles/11625001-import-from-youtube
- [R-WHY] https://recime.app/help/en/articles/14773584-why-didn-t-my-recipe-import-correctly
- [R-SHOT] https://recime.app/help/en/articles/12250372-import-from-screenshots
- [R-SCAN] https://recime.app/help/en/articles/11625316-scan-recipes-from-cookbooks
- [R-PLUS] https://recime.app/help/en/articles/11630603-what-are-the-benefits-of-recime-plus
- [R-WHAT] https://recime.app/help/en/articles/11594896-what-is-recime
- [R-EXT] https://recime.app/help/en/articles/11596278-add-the-recime-chrome-extension
- [R-MOST] https://recime.app/help/en/articles/11596272-how-can-i-get-the-most-out-of-recime
- [R-SRC] https://recime.app/help/en/articles/12381412-how-to-check-the-original-recipe-source
- [R-CHECKOUT] https://recime.app/help/en/articles/13123523-how-to-use-grocery-checkout
- [R-FREE] https://recime.app/help/en/articles/11596201-is-there-a-free-version-of-the-app
- [R-PRICE] https://recime.app/help/en/articles/11630592-how-much-does-the-recime-subscription-cost

### Paprika
- [P-SITE] https://www.paprikaapp.com/
- [P-NEWS] https://www.paprikaapp.com/news/
- [P-IOS] https://www.paprikaapp.com/help/ios/
- [P-MAC] https://www.paprikaapp.com/help/mac/
- [P-AS] https://apps.apple.com/us/app/paprika-recipe-manager-3/id1303222868
- [P4-SCAN] https://www.paprikaapp.com/help/v4/ios/scanningrecipes/
- [P4-BROWSER] https://www.paprikaapp.com/help/v4/ios/browser/
- [P4-ADD] https://www.paprikaapp.com/help/v4/ios/addingrecipes/
- [P4-GROC] https://www.paprikaapp.com/help/v4/ios/groceries/

### Mela
- [M-SITE] https://mela.recipes
- [M-HELP] https://mela.recipes/help/
- [M-FMT] https://mela.recipes/fileformat/index.html
- [M-AS] https://apps.apple.com/us/app/mela-recipe-manager/id1548466041
- [M-AS-MAC] https://apps.apple.com/us/app/mela-recipe-manager/id1568924476

### Pestle
- [PE-SITE] https://pestlechef.app
- [PE-PRO] https://pestlechef.app/pro
- [PE-AS] https://apps.apple.com/us/app/id1574776971
- [PE-DOCS] https://docs.pestlechef.app
- [PE-IG] https://pestlechef.app/blog/save-recipes-from-instagram
- [PE-BROWSER] https://pestlechef.app/blog/meet-the-in-app-browser
- [PE-PLAN] https://pestlechef.app/blog/how-to-meal-plan
- [PE-PANTRY] https://pestlechef.app/blog/introducing-pestle-pantry

### Honeydew
- [H-SITE] https://honeydewcook.com
- [H-AS] https://apps.apple.com/us/app/honeydew-capture-recipes/id6714449541
- [H-DOCS] https://honeydewcook.com/support/en/first-steps-ios
- [H-IG] https://honeydewcook.com/support/en/first-steps-ios/save-from-instagram
- [H-YT] https://honeydewcook.com/support/en/first-steps-ios/save-from-youtube
- [H-SCAN] https://honeydewcook.com/support/en/first-steps-ios/scan-from-cookbooks
- [H-AIEDIT] https://honeydewcook.com/support/en/using-the-app/ai-edit
- [H-MCP] https://honeydewcook.com/guides/cook-smarter-with-honeydew-and-ai
- [H-GROC] https://honeydewcook.com/support/en/using-the-app/grocery-checkout
- [H-SRC] https://honeydewcook.com/support/en/using-the-app/how-to-view-original-source

### Flavorish
- [F-SITE] https://www.flavorish.ai
- [F-AS] https://apps.apple.com/us/app/flavorish-save-any-recipe/id6478546136
- [F-BLOG] https://www.flavorish.ai/blog/save-recipes-from-instagram-tiktok-youtube-facebook
- [F-HELP] https://www.flavorish.ai/blog/help-center-feature-related
- [F-COOK] https://www.flavorish.ai/blog/cooking-mode-on-flavorish
- [F-GROC] https://www.flavorish.ai/blog/grocery-lists-for-sharing-collaborating-and-instant-sync

### Deglaze
- [D-SITE] https://www.deglaze.app
- [D-IG] https://www.deglaze.app/how-to/save-recipes-from-instagram
- [D-AS] https://apps.apple.com/us/app/deglaze-cooking-simplified/id6443578246

### AnyList
- [A-AS] https://apps.apple.com/us/app/anylist-grocery-shopping-list/id522167641
- [A-COMPLETE] https://www.anylist.com/complete
- [A-START] https://help.anylist.com/articles/getting-started/
- [A-IMPORT] https://help.anylist.com/articles/feature-overview-recipe-import/
- [A-PAPRIKA] https://help.anylist.com/articles/paprika-import/
- [A-COOK] https://help.anylist.com/articles/recipe-cooking-view/
- [A-SCALE] https://help.anylist.com/articles/scale-recipe/
- [A-TEMPL] https://help.anylist.com/articles/meal-plan-templates/
- [A-ICAL] https://help.anylist.com/articles/meal-plan-icalendar-overview/
- [A-IDEAS] https://help.anylist.com/articles/meal-plan-ideas/
- [A-ADD] https://help.anylist.com/articles/feature-overview-adding-items/
- [A-REM] https://help.anylist.com/articles/reminders-import/
- [A-SIRI] https://help.anylist.com/articles/siri/
- [A-SHOP] https://help.anylist.com/articles/feature-overview-online-shopping/
- [A-FAV] https://help.anylist.com/articles/favorites/
- [A-CATS] https://help.anylist.com/articles/category-sets/

### Mealime
- [ME-CLOSE] https://www.mealime.com/closing
- [ME-START] https://support.mealime.com/article/151-getting-started-guide
- [ME-COOK] https://support.mealime.com/article/88-how-to-use-cooking-mode
- [ME-GROC] https://support.mealime.com/article/75-how-the-grocery-list-works

### Samsung Food
- [S-AS] https://apps.apple.com/us/app/samsung-food-meal-planner/id1133637674
- [S-NEWS23] https://news.samsung.com/uk/samsung-announces-global-launch-of-samsung-food-an-ai-powered-personalised-food-and-recipe-service
- [S-NEWS24] https://news.samsung.com/uk/upgraded-samsung-food-raises-the-bar-for-food-experiences-at-ifa-2024

### Mealie
- [MI-INTRO] https://mealie.io/documentation/getting-started/introduction/
- [MI-FAQ] https://mealie.io/documentation/getting-started/faq/
- [MI-AI] https://mealie.io/documentation/getting-started/installation/ai-providers/
- [MI-API] https://mealie.io/documentation/getting-started/api-usage/
- [MI-SCRAPER] https://github.com/mealie-recipes/mealie/blob/mealie-next/mealie/services/scraper/recipe_scraper.py
- [MI-TRANS] https://github.com/mealie-recipes/mealie/blob/mealie-next/mealie/services/openai/transcription.py
- [MI-DEBUG] https://github.com/mealie-recipes/mealie/blob/mealie-next/frontend/app/lang/messages/en-US.json
- [MI-ING] https://github.com/mealie-recipes/mealie/blob/mealie-next/mealie/schema/recipe/recipe_ingredient.py
- [MI-STEP] https://github.com/mealie-recipes/mealie/blob/mealie-next/mealie/schema/recipe/recipe_step.py
- [MI-MATCH] https://github.com/mealie-recipes/mealie/blob/mealie-next/mealie/services/parser_services/_base.py
- [MI-PLAN] https://github.com/mealie-recipes/mealie/blob/mealie-next/mealie/routes/households/controller_mealplan.py
- [MI-SHOP] https://github.com/mealie-recipes/mealie/blob/mealie-next/mealie/services/household_services/shopping_lists.py
- [MI-SHORTCUT] https://github.com/mealie-recipes/mealie/blob/mealie-next/docs/docs/documentation/community-guide/ios-shortcut.md
- [MI-LICENSE] https://github.com/mealie-recipes/mealie/blob/mealie-next/LICENSE

### Tandoor
- [T-DOCS] https://docs.tandoor.dev/
- [T-AI] https://docs.tandoor.dev/features/ai/
- [T-AUTO] https://docs.tandoor.dev/features/automation/
- [T-IMPORT] https://docs.tandoor.dev/features/import_export/
- [T-SHOP] https://docs.tandoor.dev/features/shopping/
- [T-TEMPL] https://docs.tandoor.dev/features/templating/
- [T-MODELS] https://github.com/TandoorRecipes/recipes/blob/develop/cookbook/models.py
- [T-API] https://github.com/TandoorRecipes/recipes/blob/develop/cookbook/views/api.py
- [T-URLIMPORT] https://github.com/TandoorRecipes/recipes/blob/develop/cookbook/helper/recipe_url_import.py
- [T-LICENSE] https://github.com/TandoorRecipes/recipes/blob/develop/LICENSE.md

### Formats
- [SCHEMA] https://schema.org/Recipe
- [GOOGLE] https://developers.google.com/search/docs/appearance/structured-data/recipe
- [COOKLANG] https://cooklang.org/docs/spec/
- [COOKLANG-CONV] https://github.com/cooklang/spec/blob/main/conventions.md
- [RS] https://github.com/hhursev/recipe-scrapers

### Instacart, H-E-B, eMeals
- [IC-RECIPE] https://docs.instacart.com/developer_platform_api/api/products/create_recipe_page
- [IC-TUTORIAL] https://docs.instacart.com/developer_platform_api/guide/tutorials/create_a_recipe_page
- [IC-FAQ] https://docs.instacart.com/developer_platform_api/faq/
- [IC-HEB] https://www.instacart.com/store/h-e-b/storefront
- [HEB-RECIPES] https://www.heb.com/discover/shoppable-recipes
- [HEB-LISTS] https://careers.heb.com/blog/shopping-lists
- [EM-AS] https://apps.apple.com/us/app/emeals-healthy-meal-plans/id575756462
- [EM-WEB] https://emeals.com/grocery-delivery-pickup/
