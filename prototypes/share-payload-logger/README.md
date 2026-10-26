# Share sheet payload logger — PROTOTYPE, throwaway

Answers [Share sheet payload logger](https://github.com/enyiasonye/kitchenmate/issues/21): what does the iOS share sheet hand an extension from each source app?

## Run

```sh
cd prototypes/share-payload-logger
xcodegen generate && open PayloadLogger.xcodeproj
```

Plug in the iPhone, pick the **PayloadLogger** scheme and your iPhone, press Run. (First run: trust the developer profile in Settings → General → VPN & Device Management.)

## Test script

For each source, share a **recipe post/page** and pick **Log Payload** in the share sheet (it may be under *More*/*Edit Actions* the first time). Wait for "Captured", then tap the source app's name.

1. **YouTube** — a recipe video (also try a Short).
2. **Instagram** — a recipe Reel *and* a photo post with the recipe in the caption.
3. **TikTok** — a recipe video.
4. **Tasty** — a recipe.
5. **Safari** — a recipe site (e.g. a NYT Cooking / AllRecipes / Tasty web page). Check the JS preprocessing results row appears with `jsonLdHasRecipe` and an HTML byte count.
6. **Chrome** — the same recipe site.
7. **Photos** — one photo, then three photos at once.

Then open the Payload Logger app, tap **Export**, and AirDrop/save the JSON to the Mac (or paste it into the issue).

Each share is saved as JSON in the app group container (`PROTOTYPE-wipe-me-logs`). Big media files are measured, never loaded.
