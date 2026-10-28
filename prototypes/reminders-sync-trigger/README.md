# Sync Probe — PROTOTYPE, throwaway

Answers [Reminders sync trigger prototype](https://github.com/enyiasonye/kitchenmate/issues/23): on the owner's real iPhone, does the Shortcuts Time of Day automation fire reliably every day, and how often do the opportunistic triggers fire on their own?

Every trigger runs the same "sync": read the incomplete reminders in the Synced List and log the trigger, time, app state, whether the phone had been unlocked since boot, Low Power Mode, boot time, and build. **Read-only — nothing on the shared list is completed or changed.** Background runs post a local notification so you see them happen (toggle in Setup).

## Install (TestFlight — work MDM blocks developer installs)

```sh
cd prototypes/reminders-sync-trigger
xcodegen generate
xcodebuild -project SyncTriggerProbe.xcodeproj -scheme SyncTriggerProbe -destination 'generic/platform=iOS' \
  -archivePath build/SyncTriggerProbe.xcarchive -allowProvisioningUpdates archive
xcodebuild -exportArchive -archivePath build/SyncTriggerProbe.xcarchive -exportOptionsPlist ExportOptions.plist \
  -exportPath build -allowProvisioningUpdates
```

## Setup (once)

1. Open **Sync Probe** → **Grant Reminders access** (also asks for notifications).
2. Pick the grocery list as **Synced List**; leave **Daily sync time** at 7:00 AM.
3. Shortcuts → Automation → **+** → Time of Day → 7:00 AM, Daily → **Run Immediately** → action **Run Grocery Sync Probe**. On the shortcut, turn on **Allow Running When Locked**. Note how long this took and anything confusing.
4. Tap **Inspect Synced List** → share the dump (answers how sections/auto-categories look through EventKit).

## Test script (about a week)

Use the phone normally; open the app only when a step says so. The **Days** list shows each day's Shortcut run (red if missed) and counts for the other triggers.

| Day | Condition to test the 7 AM Shortcut under |
|---|---|
| 1 | Normal, phone locked on the nightstand |
| 2 | **Force-quit** the app (swipe it away) the night before |
| 3 | **Reboot** the phone the night before and *don't unlock* until after 7 AM (expect "No Synced List" / access errors: data is locked before first unlock) |
| 4 | **Low Power Mode** on overnight |
| 5 | Phone **off** from ~6:30 to ~7:30 AM — does the missed run catch up when it boots? |
| 6 | **Reinstall** from TestFlight (bump build: `CURRENT_PROJECT_VERSION` in `project.yml`) the night before — does the automation survive? |
| 7+ | Normal; an iOS update, if one arrives, counts as a test |

**Silent push (optional):** create an APNs key (developer.apple.com → Keys → Apple Push Notifications service), tap **Copy push token**, then once a day run
`APNS_KEY=… APNS_KEY_ID=… DEVICE_TOKEN=… ./send-silent-push.sh` (or schedule it). HTTP 200 means APNs accepted it; the app's log shows whether it was delivered.

**Background refresh** asks to run hourly; whatever iOS actually grants is logged.

At the end tap **Export results** and AirDrop the JSON to the Mac (save as `results-<date>.json` here).
