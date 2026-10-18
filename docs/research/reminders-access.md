# Reminders access and background execution

Research for issue #4. Researched 2026-09-29 against Apple documentation current for iOS 27 / macOS 27 (the SDK pages already list 27.0 availability and deprecations).

Conventions: **[Verified]** = stated by the cited primary source. **[Inference]** = my conclusion from verified facts; not stated by Apple. **[Unverified]** = could not confirm in a primary source; needs a prototype.

## Summary

- Reading a chosen Reminders list and marking items completed is fully supported on both iPhone and Mac through EventKit, with one permission ("full access to reminders"). There is no read-only or per-list permission.
- **iOS gives no way to guarantee code runs daily at a given time from inside the app.** Apple says so explicitly. `BGAppRefreshTask` and silent push are both best-effort, both are disabled by force-quit, and background refresh is off in Low Power Mode.
- The only user-schedulable, clock-based trigger on iPhone is a **Shortcuts "Time of Day" automation** set to run without asking, which runs an **App Intent** exposed by the app. Background intents get 30 seconds (extendable on iOS 27 with `LongRunningIntent`).
- The **Mac is the most dependable executor while awake**: a launch agent registered with `SMAppService` and scheduled with `StartCalendarInterval` has no background time limit, and launchd runs a missed job on the next wake.
- iCloud propagates completion state between devices automatically, but with no documented latency, so the backend must de-duplicate.
- **Recommended combination:** iPhone Shortcuts automation -> App Intent (primary); Mac launch agent (second executor); `BGAppRefreshTask` + run-on-foreground + silent push as opportunistic extras; a backend watchdog that sends a *visible* push if no sync has arrived by a deadline. Backend idempotency keyed on the reminder's external identifier.
- Write the sync core as a small native Swift module regardless of client stack; App Intents and the Mac agent must be Swift either way.

## 1. EventKit: permissions and list selection

| Claim | Status | Source |
|---|---|---|
| `EKEventStore` is the single access point for reminder data; the app must request access before fetching. | Verified | https://developer.apple.com/documentation/eventkit/ekeventstore |
| Reminders access is requested with `requestFullAccessToReminders(completion:)` (iOS 17+, macOS 14+). The system prompts only the first time. | Verified | https://developer.apple.com/documentation/eventkit/ekeventstore/requestfullaccesstoreminders(completion:) |
| There is no read-only access: "To read events or reminders from the event store, your app needs full access." Full access allows create, view, edit, delete. Write-only exists for events only. | Verified | https://developer.apple.com/documentation/eventkit/accessing-the-event-store |
| `NSRemindersFullAccessUsageDescription` is required in Info.plist. On iOS 17+ a missing usage description means the request is automatically denied. | Verified | https://developer.apple.com/documentation/eventkit/accessing-the-event-store , https://developer.apple.com/documentation/bundleresources/information-property-list/nsremindersfullaccessusagedescription |
| The old `requestAccess(to:)` is deprecated; when linked against the iOS 17 / macOS 14 SDK it does not prompt and errors. | Verified | https://developer.apple.com/documentation/technotes/tn3152-migrating-to-the-latest-calendar-access-levels |
| Sandboxed macOS apps need the `com.apple.security.personal-information.calendars` entitlement (enabled via App Sandbox or Hardened Runtime > Calendar). Apple's page describes it for calendar data; it is the entitlement the EventKit access article names for macOS. | Verified | https://developer.apple.com/documentation/eventkit/accessing-the-event-store , https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.security.personal-information.calendars |
| Reminders lists are `EKCalendar` objects; enumerate them with `calendars(for: .reminder)`. | Verified | https://developer.apple.com/documentation/eventkit/ekeventstore/calendars(for:) |
| Fetch open items in one list with `predicateForIncompleteReminders(withDueDateStarting:ending:calendars:)` passing `nil` dates, then `fetchReminders(matching:completion:)` (asynchronous). | Verified | https://developer.apple.com/documentation/eventkit/ekeventstore/predicateforincompletereminders(withduedatestarting:ending:calendars:) , https://developer.apple.com/documentation/eventkit/retrieving-events-and-reminders |
| Mark complete by setting `isCompleted = true` (sets `completionDate` to now) and saving. | Verified | https://developer.apple.com/documentation/eventkit/ekreminder/iscompleted |
| `calendarIdentifier` and `calendarItemIdentifier` are *local* identifiers and "a full sync with the calendar will lose this identifier"; Apple tells you to cache other properties as a fallback. | Verified | https://developer.apple.com/documentation/eventkit/ekcalendar/calendaridentifier , https://developer.apple.com/documentation/eventkit/ekcalendaritem/calendaritemidentifier |
| `calendarItemExternalIdentifier` "allows you to access the same event or reminder across multiple devices" (caveats: Exchange accounts differ per device; duplicates possible in edge cases). | Verified | https://developer.apple.com/documentation/eventkit/ekcalendaritem/calendaritemexternalidentifier |
| The store posts `EKEventStoreChanged` when the database changes; refetch on receipt. | Verified | https://developer.apple.com/documentation/eventkit/updating-with-notifications |

Implications:

- **[Inference]** Permission is all-or-nothing across every Reminders list. "Choosing a list" is an in-app setting, not a system permission scope.
- **[Inference]** Because list identifiers are local, each device should persist its own selected `calendarIdentifier` plus the list title and source as a fallback, and the iPhone and Mac should each resolve the list locally (match by title) rather than sharing one identifier through the backend.
- **[Inference]** Use `calendarItemExternalIdentifier` as the backend idempotency key for a reminder, since it is the only identifier Apple documents as cross-device for iCloud.
- **[Unverified]** Whether EventKit exposes newer Reminders features (sections, tags, the "Groceries" list type and its auto-categories). Nothing in the EventKit reference covers them. Items in a Groceries-type list are expected to appear as ordinary `EKReminder`s, but this needs a prototype.

## 2. What iOS background execution actually guarantees

Short answer: nothing time-based.

| Claim | Status | Source |
|---|---|---|
| Apple DTS: "There's no general-purpose mechanism for: running code continuously in the background; running code at some specific time in the background; running code periodically at a guaranteed interval; resuming in the background in response to a network or IPC request." | Verified (Apple DTS engineer post, last revised 2026-01-09) | https://developer.apple.com/forums/thread/685525 |
| App refresh is not regular: "The system applies a range of heuristics to decide which apps get app refresh time and when... there are common scenarios where it won't grant you *any* background execution time at all." | Verified | https://developer.apple.com/forums/thread/685525 |
| `earliestBeginDate` is a lower bound only: "the system doesn't guarantee launching the task at the specified date, but only that it won't begin sooner." | Verified | https://developer.apple.com/documentation/backgroundtasks/bgtaskrequest/earliestbegindate |
| "The delay between the time you schedule a background task and when the system launches your app to run the task can be many hours." | Verified | https://developer.apple.com/documentation/backgroundtasks/starting-and-terminating-tasks-during-development |
| `BGAppRefreshTask`: system picks the time and "provides your app up to 30 seconds of background runtime." | Verified | https://developer.apple.com/documentation/backgroundtasks/choosing-background-strategies-for-your-app |
| `BGProcessingTask` can run for minutes but "only when the device is idle"; the system terminates it when the user starts using the device. | Verified | https://developer.apple.com/documentation/backgroundtasks/bgprocessingtask |
| At most 1 refresh task and 10 processing tasks may be pending; resubmitting replaces the prior request. | Verified | https://developer.apple.com/documentation/backgroundtasks/bgtaskscheduler/submit(_:) |
| Background App Refresh "is disabled automatically when a device is operating in low-power mode"; the user can also switch it off. | Verified | https://developer.apple.com/documentation/uikit/uiapplication/backgroundrefreshstatus |
| Force-quit (swipe up in the app switcher) terminates the app and sets a flag that prevents background launches until the user next opens the app manually. | Verified | https://developer.apple.com/forums/thread/685525 |
| An extension can schedule a task, but the main app must register it and is what the system launches. | Verified | https://developer.apple.com/documentation/uikit/using-background-tasks-to-update-your-app |
| Background tasks do not run in the Simulator; a physical device is required. | Verified | https://developer.apple.com/documentation/backgroundtasks/bgtaskscheduler/error/code/unavailable |

### Changes in recent releases

| Claim | Status | Source |
|---|---|---|
| iOS 27: `BGTaskScheduler.submit(_:)` is deprecated (deprecated at 27.0), replaced by `submitTaskRequest(_:completionHandler:)`. Limits are unchanged. Scheduling guarantees are unchanged. | Verified | https://developer.apple.com/documentation/backgroundtasks/bgtaskscheduler/submittaskrequest(_:completionhandler:) |
| iOS 26: `BGContinuedProcessingTask` added. It "starts in the foreground and can continue running in the background" and shows a Live Activity. It is not a scheduler and does not help a daily unattended run. | Verified | https://developer.apple.com/documentation/backgroundtasks/bgcontinuedprocessingtask , https://developer.apple.com/documentation/updates/backgroundtasks |

## 3. Silent (background) push as a trigger

| Claim | Status | Source |
|---|---|---|
| "The system treats background notifications as low priority... the system doesn't guarantee their delivery." May be throttled; "don't try to send more than two or three per hour." | Verified | https://developer.apple.com/documentation/usernotifications/pushing-background-updates-to-your-app |
| Payload: `aps` with only `content-available: 1`; headers `apns-push-type: background`, `apns-priority: 5`; requires the Remote notifications background mode. | Verified | https://developer.apple.com/documentation/usernotifications/pushing-background-updates-to-your-app |
| The system may hold and delay delivery; only the newest held notification is kept; a force-quit discards it. | Verified | https://developer.apple.com/documentation/usernotifications/pushing-background-updates-to-your-app |
| The app gets 30 seconds. | Verified | https://developer.apple.com/documentation/usernotifications/pushing-background-updates-to-your-app |
| Not delivered to a force-quit app until the user relaunches it or restarts the device. | Verified | https://developer.apple.com/documentation/uikit/uiapplicationdelegate/application(_:didreceiveremotenotification:fetchcompletionhandler:) |
| Apps that use significant power processing pushes "may not always be woken up early to process future notifications." | Verified | https://developer.apple.com/documentation/uikit/uiapplicationdelegate/application(_:didreceiveremotenotification:fetchcompletionhandler:) |
| On macOS, `application(_:didReceiveRemoteNotification:)` is delivered "when the application is running." | Verified | https://developer.apple.com/documentation/appkit/nsapplicationdelegate/application(_:didreceiveremotenotification:) |

**[Inference]** One silent push per day is well inside the rate guidance, so it is a reasonable *nudge* from the backend cron, but it shares the same failure modes as app refresh (force-quit, Low Power Mode, system discretion). It cannot be the only trigger.

## 4. Shortcuts automations running an App Intent

This is the only clock-based trigger available on iPhone.

| Claim | Status | Source |
|---|---|---|
| Time of Day trigger: specific time, sunrise or sunset; repeat Daily, Weekly or Monthly. | Verified | https://support.apple.com/guide/shortcuts/event-triggers-apd932ff833f/ios |
| By default an automation sends a notification asking to run. "Some personal automations can run without asking you for confirmation", and **Time of Day is on the list** of those that can. When set this way "the automation will not notify you when it's triggered." | Verified | https://support.apple.com/guide/shortcuts/create-a-new-personal-automation-apdfbdbd7123/ios |
| **iOS 27 changed the UI**: automations are attached to a shortcut (Edit > Automation), and running without asking is enabled under the shortcut's Privacy settings with **"Allow Running When Locked"**. In iOS 17 through 26 the control was "turn off Ask Before Running, then tap Don't Ask" on the automation. | Verified | iOS 27: https://support.apple.com/guide/shortcuts/create-a-new-personal-automation-apdfbdbd7123/ios ; iOS 26: https://support.apple.com/guide/shortcuts/apd602971e63/9.0/ios/26 |
| "You also may need to set individual actions to run automatically." | Verified | https://support.apple.com/guide/shortcuts/create-a-new-personal-automation-apdfbdbd7123/ios |
| Automations are per-device: they back up to iCloud but sync to other devices disabled. | Verified | https://support.apple.com/guide/shortcuts/intro-to-personal-automation-apd690170742/ios |
| An `AppIntent` is what exposes an app action to Shortcuts. Intents are discoverable by default (`isDiscoverable`). | Verified | https://developer.apple.com/documentation/appintents/appintent , https://developer.apple.com/documentation/appintents/appintent/isdiscoverable |
| An intent implemented in the app runs in the background unless it asks for the foreground: "your app will launch in a special mode without scenes being brought up." Apple calls in-app implementation the simplest option, with higher memory limits than an extension. | Verified (WWDC22 session 10032) | https://developer.apple.com/videos/play/wwdc2022/10032/ |
| iOS 26+: `supportedModes` (`IntentModes`) replaces the deprecated `openAppWhenRun`. `.background` runs entirely in the background. | Verified | https://developer.apple.com/documentation/appintents/appintent/supportedmodes , https://developer.apple.com/documentation/appintents/appintent/openappwhenrun |
| Default `authenticationPolicy` is `.alwaysAllowed`, "which allows the intent to run without authentication, including when the device is locked." | Verified | https://developer.apple.com/documentation/appintents/appintent/authenticationpolicy |
| Background intent runtime is 30 seconds on iOS; the system can cancel an intent that "didn't report progress and exceeded its 30-second runtime limit." macOS has no limit. | Verified | https://developer.apple.com/documentation/appintents/longrunningintent , https://developer.apple.com/documentation/appintents/cancellableintent |
| **iOS 27 / macOS 27**: `LongRunningIntent` extends background runtime via `performBackgroundTask`, provided the intent reports progress regularly. | Verified | https://developer.apple.com/documentation/appintents/longrunningintent , https://developer.apple.com/documentation/updates/appintents |
| iOS 27: `allowedExecutionTargets` lets an intent be pinned to the main app, the App Intents extension or a widget extension. | Verified | https://developer.apple.com/documentation/appintents/appintent/allowedexecutiontargets |
| macOS 26 (Tahoe) added automations to Shortcuts on Mac, including time-of-day. The Mac guide lists the same run-without-asking setting and trigger list. | Verified | https://support.apple.com/en-us/125148 , https://support.apple.com/guide/shortcuts-mac/add-automations-apdfbdbd7123/mac |

Caveats:

- **[Inference]** Setup is manual and one-time: the owner must create the automation in the Shortcuts app. An app cannot install an automation programmatically; no API for that appears in the App Intents documentation. Acceptable for a single-user app.
- **[Unverified]** Apple does not document what happens when the phone is powered off, or in its pre-first-unlock state, at the trigger time, nor whether a missed Time of Day automation runs later. Assume a missed trigger is skipped.
- **[Unverified]** Apple does not document whether force-quitting the app blocks an intent launched by Shortcuts. The force-quit flag is documented as blocking background launches in general, so treat it as a risk and test it.
- **[Inference]** Keep the on-device work small enough for 30 seconds: fetch the reminders, POST them to the backend, mark them complete on acknowledgement. The slow HEB work belongs on the backend. `LongRunningIntent` is a safety margin on iOS 27, not something to depend on.

## 5. Mac: app or login-item agent while awake

| Claim | Status | Source |
|---|---|---|
| macOS 13+: `SMAppService` registers login items, launch agents and launch daemons that live inside the app bundle. | Verified | https://developer.apple.com/documentation/servicemanagement/smappservice |
| `SMAppService.agent(plistName:)` uses a plist in `Contents/Library/LaunchAgents`. On `register()` the agent "is immediately bootstrapped and may begin running" and bootstraps on each subsequent login. | Verified | https://developer.apple.com/documentation/servicemanagement/smappservice/agent(plistname:) , https://developer.apple.com/documentation/servicemanagement/smappservice/register() |
| `SMAppService.mainApp` launches the main app at login; a LoginItem helper is relaunched if it crashes. | Verified | https://developer.apple.com/documentation/servicemanagement/smappservice/mainapp , https://developer.apple.com/documentation/servicemanagement/smappservice/register() |
| The user can revoke consent in System Settings; status becomes `requiresApproval`. | Verified | https://developer.apple.com/documentation/servicemanagement/smappservice/status-swift.enum/requiresapproval |
| launchd `StartCalendarInterval`: cron-like schedule, and "unlike cron which skips job invocations when the computer is asleep, launchd will start the job the next time the computer wakes up." Multiple missed intervals coalesce into one. | Verified | `man launchd.plist` (macOS 26 local copy) |
| launchd `StartInterval`, by contrast, misses firings that fall during sleep. | Verified | `man launchd.plist` |
| `NSBackgroundActivityScheduler` schedules repeating deferrable work inside a running app, at a time the system chooses within a tolerance. | Verified | https://developer.apple.com/documentation/foundation/nsbackgroundactivityscheduler |
| "In macOS, the system allows background tasks to run without time limits." | Verified | https://developer.apple.com/documentation/appintents/longrunningintent |
| A menu-bar-only app is possible with `MenuBarExtra` plus `LSUIElement`. | Verified | https://developer.apple.com/documentation/swiftui/menubarextra |
| Privacy prompts are attributed to the "responsible code"; a helper should be attributed to its containing app. If a launchd agent is not attributed correctly, add `AssociatedBundleIdentifiers` to its plist. | Verified (Apple DTS engineer post, last revised 2026-09-18) | https://developer.apple.com/forums/thread/678819 |

Implications:

- **[Inference]** The strongest Mac option is a launch agent registered through `SMAppService` with `StartCalendarInterval`. It runs at the set time if the Mac is awake and the user logged in, and on the next wake otherwise. It does not run while the Mac is asleep or shut down, or before login.
- **[Inference]** A simpler alternative is the main app as a login item (menu bar app) with an internal timer or `NSBackgroundActivityScheduler`. It only works while the app is running, and a plain timer does not catch up after sleep unless the app checks on wake.
- **[Unverified]** Whether the Reminders permission granted to the main app is honoured for a separate agent executable without a second prompt. Apple's guidance implies it should be, but this is heuristic-based and must be prototyped.
- **[Inference]** The Shortcuts Time of Day automation on Mac (macOS 26+) is a no-code alternative to the launch agent, but Apple does not document catch-up after sleep for it, so the launch agent is the better-specified choice.

## 6. iCloud sync of completion state

| Claim | Status | Source |
|---|---|---|
| With iCloud Reminders on, "changes you make on one device, like creating a new to-do list or marking an item as complete, automatically appear on all your devices." | Verified | https://support.apple.com/guide/icloud/what-you-can-do-with-icloud-and-reminders-mmc591432bd9/icloud |
| Requires the same Apple Account with Reminders enabled in iCloud settings on each device. | Verified | https://support.apple.com/guide/icloud/set-up-reminders-mmbf52194b5a/icloud |
| A reminder completed by another client may have `isCompleted == true` with a `nil` `completionDate`. | Verified | https://developer.apple.com/documentation/eventkit/ekreminder/iscompleted |
| `refreshSourcesIfNecessary()` "pulls new data from remote sources, if necessary." Availability lists iOS, macOS and visionOS. | Verified | https://developer.apple.com/documentation/eventkit/ekeventstore/refreshsourcesifnecessary() |

- **[Inference]** A completion written through EventKit lands in the same local database the Reminders app uses, so the system syncs it to iCloud like any other edit. The app needs no iCloud credentials or CloudKit code.
- **[Unverified]** Sync latency. Apple publishes no figure. An item added on the phone may not yet be on the Mac when the Mac agent runs, and an item the Mac completed may still look open on the phone for a while.
- **[Unverified]** Whether `refreshSourcesIfNecessary()` has any effect on iCloud reminders and whether it completes within a background window.
- **[Inference]** Consequence for design: both devices can submit the same reminder. The backend must treat submissions as idempotent, keyed on `calendarItemExternalIdentifier`.

## 7. Locked device and extensions

| Claim | Status | Source |
|---|---|---|
| "Calendar (excluding attachments), Contacts, Reminders, Notes, Messages, and Photos implement the Data Protection entitlement Protected Until First User Authentication." | Verified | https://support.apple.com/guide/security/app-protection-and-app-groups-sec1a976c067/web |
| In that class the key "isn't removed from memory when the device is locked." It protects against attacks involving a reboot. It is also the default for third-party app data. | Verified | https://support.apple.com/guide/security/data-protection-classes-secb010e978a/web |
| App intents run while locked by default; Shortcuts has an explicit "Allow Running When Locked" setting. | Verified | https://developer.apple.com/documentation/appintents/appintent/authenticationpolicy , https://support.apple.com/guide/shortcuts/create-a-new-personal-automation-apdfbdbd7123/ios |

- **[Inference]** Reminders data is readable and writable while the phone is locked, as long as it has been unlocked once since boot. After a reboot and before first unlock, the sync cannot work. Keep the app's own token storage and files at the same protection level (not `complete`), or a locked-device run will fail on the app's own data.
- **[Unverified]** EventKit from inside app extensions (share extension, App Intents extension, widget). I found no Apple statement forbidding it and no statement confirming that the containing app's permission carries over. Avoid the question: implement the intent in the main app target, which Apple describes as the simplest route, and do not plan on a share extension touching Reminders.
- **[Verified]** For `BGTaskScheduler`, extensions can schedule but only the app runs the task. https://developer.apple.com/documentation/uikit/using-background-tasks-to-update-your-app

## 8. Realistic reliability of a daily cadence

All ratings below are **[Inference]** from the verified facts above. Apple publishes no success rates.

| Trigger | Device | Fires at a set time? | Main failure modes | Rating |
|---|---|---|---|---|
| Shortcuts Time of Day automation -> App Intent | iPhone | Yes | Phone off or not unlocked since reboot; automation disabled or deleted; 30 s limit; force-quit (untested) | High. Best available on iOS. |
| `BGAppRefreshTask` | iPhone | No, system chooses | Low Power Mode; Background App Refresh off; force-quit; rarely-opened app gets little or no time | Low to medium. May skip days. |
| Silent push | iPhone | Roughly, system may delay | Same as above plus APNs non-delivery | Low to medium. |
| Run on app foreground | iPhone | Only when opened | Depends on the owner opening the app | Reliable when it happens. |
| Launch agent, `StartCalendarInterval` | Mac | Yes, or at next wake | Mac asleep all day, shut down, logged out; consent revoked | High on a Mac that is used daily. |
| Login-item app with timer | Mac | While running | App quit; no catch-up after sleep unless coded | Medium. |
| Shortcuts automation | Mac | Yes | Sleep behaviour undocumented | Medium. |

An aggravating factor on iPhone: this app will be opened rarely, and app refresh scheduling favours apps the user actually uses. So the system-discretion triggers are weakest for exactly this kind of app.

Distribution also affects reliability:

- **[Verified]** TestFlight builds stop working for testers after 90 days. https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview
- **[Verified]** An expired provisioning profile must be regenerated and the app re-signed. https://developer.apple.com/help/account/provisioning-profiles/edit-download-or-delete-profiles/
- **[Unverified]** The commonly cited one-year lifetime of development and ad hoc profiles; I did not find the duration stated on the Apple help pages I read.
- **[Inference]** Either route means the daily sync silently stops unless the app is re-installed periodically (every 90 days on TestFlight). The backend watchdog below covers this.

## 9. Recommended trigger combination

All **[Inference]**.

1. **iPhone primary: Shortcuts Time of Day automation**, daily, set to run without asking, running a `SyncGroceryReminders` App Intent implemented in the main app target with `supportedModes = .background`. One-time manual setup, guided by an in-app onboarding screen.
2. **Mac second executor: launch agent** registered via `SMAppService.agent(plistName:)` with `StartCalendarInterval`, sharing the same Swift sync core.
3. **Opportunistic extras on iPhone**: `BGAppRefreshTask` re-submitted after each run, a sync whenever the app comes to the foreground, and one daily silent push from the backend cron. Cheap to add once the sync core exists; none is relied on.
4. **Backend watchdog**: if no sync has been recorded by a cutoff time, send a *visible* push ("Grocery sync hasn't run today, tap to sync"). Visible pushes are not subject to the background-push throttling, and tapping opens the app, which syncs in the foreground.
5. **Idempotent backend**: each device sends the reminders with their `calendarItemExternalIdentifier`; the backend ignores any it has already accepted. This makes it safe for every trigger on both devices to fire on the same day.

Shape of one run, sized for the 30-second window: fetch incomplete reminders in the chosen list -> POST to backend -> on acknowledgement set `isCompleted = true` and save -> backend does the HEB work asynchronously and sends the result notification.

## 10. Stack-dependent notes

| Claim | Status | Source |
|---|---|---|
| `expo-calendar` supports reminders on iOS only (permissions, list, update, `completed` field) and targets Android and iOS; no macOS. | Verified | https://docs.expo.dev/versions/latest/sdk/calendar/ |
| `expo-background-task` uses `BGTaskScheduler` on iOS, so it inherits every limit in section 2. Minimum interval 15 minutes, and "the system may choose to run the task at a later time." | Verified | https://docs.expo.dev/versions/latest/sdk/background-task/ |
| App Intents are Swift types conforming to `AppIntent`. | Verified | https://developer.apple.com/documentation/appintents/appintent |

- **[Inference]** With React Native, foreground Reminders access is available through `expo-calendar`, but the recommended trigger (App Intent) and the Mac launch agent both require native Swift. A background intent launches the app without scenes, and whether a JavaScript runtime starts dependably and finishes inside 30 seconds in that mode is **[Unverified]**.
- **[Inference]** Therefore, in either stack, write the sync core (EventKit read, HTTPS POST, mark complete) as a small Swift package used by the App Intent, the background task handler and the Mac agent. With SwiftUI this is simply part of the app. With React Native it is a native module plus native targets, and the Mac side is Swift regardless.
- This weakens one argument for React Native: the feature with the hardest platform constraints needs Swift either way.

## Open questions

1. When should a reminder be marked completed: when the backend accepts the item, or only after HEB confirms it? The 30-second window pushes toward "on backend acceptance", which then needs a defined behaviour for items HEB cannot match (re-open the reminder on the next run, or report in the notification only).
2. Prototype needed: does a Shortcuts automation still run the intent after the app has been force-quit, and what happens to a trigger missed while the phone is off?
3. Prototype needed: does a launch agent inherit the main Mac app's Reminders permission without a second prompt?
4. Prototype needed: how items from a Groceries-type list (sections, auto-categories) appear through EventKit.
5. Measure real iCloud latency for completion state between iPhone and Mac.
6. Distribution choice (TestFlight with 90-day expiry versus development signing) and how the owner is reminded to re-install.
