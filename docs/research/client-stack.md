# Client stack: SwiftUI vs React Native

Research for issue #3. Researched 2026-09-29. Versions and repo statistics are as observed on that date.

## Summary

**Recommendation: SwiftUI, as a single multiplatform (iOS + macOS) Xcode target.** Confidence: moderate. **Credible fallback: Expo (React Native) for iPhone, run on the Mac as a "Designed for iPad" app.**

The reasoning in five points:

1. **Every KitchenMate feature is a first-party Apple API in SwiftUI.** Share extension, EventKit Reminders, Vision text recognition, background tasks, notifications and video all ship in the OS SDK and are all available on both iOS and native macOS (with one exception: `BGTaskScheduler` is not a native macOS API; macOS uses `NSBackgroundActivityScheduler`).
2. **In Expo most features are covered by Expo's own maintained packages** (`expo-calendar` for Reminders, `expo-notifications`, `expo-video`, `expo-background-task`). This path is genuinely viable on iPhone.
3. **The share sheet is the weak point in React Native.** Expo's own receive-share support is marked experimental and relies on a mechanism that Expo's docs say "is not officially supported by Apple". The community library that renders a React Native view inside the share sheet has an open crash report on the current Expo SDK. The robust option in an Expo app is a share extension written in Swift.
4. **There is no good React Native route to a native Mac app today.** `react-native-macos` is at 0.81 while React Native is at 0.87; Expo does not support macOS as an app platform and an Expo maintainer has said maintaining it "would be too expensive for us". The realistic Mac option for an Expo app is "Designed for iPad", which works only on Apple silicon Macs.
5. **The usual reason to choose React Native, which is sharing code with Android, does not apply.** The remaining advantage is the owner's TypeScript fluency. That advantage is real, and it is the main reason the fallback is credible, but it is reduced by the fact that an AI agent writes most of the code and that the heavy logic lives in the TypeScript cloud backend.

What would change the recommendation: if the owner values being able to read, review and debug the client code personally above native Mac support and share-sheet robustness, choose the Expo fallback. Neither path has been validated by a build; the spikes in [Open questions](#open-questions-and-suggested-spikes) should be run before the ADR is final.

## How to read this document

- **Verified** means the claim was read on the cited primary source on 2026-09-29.
- **Inference** means a conclusion drawn from verified facts, not stated by the source. Inferences are labelled.
- Nothing in this document was tested by building an app.

## Versions as of 2026-09-29

| Item | Version | Source |
|---|---|---|
| Xcode | 27, includes Swift 6.4 and the iOS 27 and macOS 27 SDKs; requires macOS Tahoe 26.6 or later | [Xcode 27 release notes](https://developer.apple.com/documentation/xcode-release-notes/xcode-27-release-notes) |
| Expo SDK | 57 (released 2026-06-30, React Native 0.86, React 19.2); npm `expo` `latest` is 57.0.26, `next` is 58.0.0 | [Expo SDK 57 changelog](https://expo.dev/changelog/sdk-57), [npm expo](https://www.npmjs.com/package/expo) |
| React Native | 0.87.1 (npm `latest`) | [npm react-native](https://www.npmjs.com/package/react-native) |
| react-native-macos | 0.81.9 (npm `latest`); latest GitHub release v0.81.8 on 2026-06-26 | [npm react-native-macos](https://www.npmjs.com/package/react-native-macos), [releases](https://github.com/microsoft/react-native-macos/releases) |
| supabase-swift | v2.55.3, released 2026-09-29 | [supabase-swift](https://github.com/supabase/supabase-swift) |

## Feature-by-stack comparison

Legend: **1P** = first-party API from the platform or framework owner. **Lib** = third-party library. **Custom** = native code you write yourself.

| Feature | SwiftUI (multiplatform) | Expo / React Native (iOS) | React Native on Mac |
|---|---|---|---|
| Share sheet extension | 1P. Share extension target, iOS and macOS | Experimental 1P (`expo-sharing`, opens the main app) or Lib (`expo-share-intent`, `expo-share-extension`) or Custom Swift extension through `@bacons/apple-targets` | "Designed for iPad": share extensions are supported per Apple. react-native-macos: Custom |
| Reminders read and mark completed | 1P. EventKit, iOS and macOS | 1P Expo. `expo-calendar`, iOS only | "Designed for iPad": expected to work, unverified. react-native-macos: Custom module |
| Text recognition (cookbook photos) | 1P. Vision `RecognizeTextRequest`, VisionKit | Lib. `expo-text-extractor` (small) or ML Kit wrapper; or do it in the cloud | Same library under "Designed for iPad", unverified |
| Background execution | 1P. `BGTaskScheduler` on iOS; `NSBackgroundActivityScheduler` on macOS | 1P Expo. `expo-background-task` (wraps `BGTaskScheduler`) | "Designed for iPad": background app refresh supported per Apple |
| Push and local notifications | 1P. UserNotifications + APNs, iOS and macOS | 1P Expo. `expo-notifications`, Android and iOS | "Designed for iPad": user notifications supported per Apple. react-native-macos: open issue for local notifications |
| Video playback (files, HLS) | 1P. AVKit `VideoPlayer`, iOS and macOS | 1P Expo. `expo-video` (AVKit underneath) | `expo-video` does not list macOS |
| Embedded YouTube/Instagram/TikTok players | 1P. SwiftUI `WebView` (iOS 26 and macOS 26 or later) | Lib. `react-native-webview` | Same library |
| Native Mac app | 1P. Same target, Mac destination | Not available | react-native-macos, lagging six minor versions |
| Supabase client | Official `supabase-swift` | Official `supabase-js` | Same |

## Feature detail

### Share sheet extension

**Platform facts (verified).**

- A share extension is a separate target bundled with the app. Apple documents share extensions for both iOS and macOS. [App Extension Programming Guide: Share](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/Share.html)
- The React Native docs state memory limits for extensions: share extensions are limited to 120 MB, and "Debug-configured builds are more likely to exceed the memory limits". [React Native: App Extensions](https://reactnative.dev/docs/app-extensions)

**SwiftUI.** First-party. The extension is a Swift target in the same Xcode project and can share code with the app.

**Expo / React Native.** Four options, all verified on their own pages:

| Option | What it is | Status |
|---|---|---|
| `expo-sharing` receive support | Expo's own package, configured by config plugin | "This functionality is currently experimental. On iOS the share extension opens the main target, instead of processing the share in a sharing ViewController, which is not officially supported by Apple and may stop working in a future iOS release." [Expo Sharing docs](https://docs.expo.dev/versions/latest/sdk/sharing/) |
| [`expo-share-intent`](https://github.com/achorein/expo-share-intent) | Community library. Redirects the user to the main app, which handles the shared data. No custom share view | v8.0.1 released 2026-07-10. README lists SDK 57 as supported by 8.0+. 607 stars, 39 open issues |
| [`expo-share-extension`](https://github.com/MaxAst/expo-share-extension) | Community library. Renders a React Native view inside the share sheet | v5.0.6 released 2026-02-23; last commit 2026-04-12. README compatibility table stops at SDK 54. Open issue [#121](https://github.com/MaxAst/expo-share-extension/issues/121) reports a crash on boot with SDK 57. 554 stars, 25 open issues |
| [`@bacons/apple-targets`](https://github.com/evanbacon/expo-apple-targets) | Config plugin that adds native Apple targets, including a Share extension, written in Swift | v5.0.0 on npm, 2026-07-17. Requires Expo SDK 53 or later and Xcode 16 or later. 1,392 stars, 48 open issues |

Older libraries are effectively unmaintained: `react-native-share-menu` had its last commit on 2023-09-19 ([repo](https://github.com/Expensify/react-native-share-menu)), and `react-native-receive-sharing-intent` was last published in 2022 ([npm](https://www.npmjs.com/package/react-native-receive-sharing-intent)).

**Inference.** The two options that stay in TypeScript (`expo-sharing`, `expo-share-intent`) both open the main app from the extension, which is the mechanism Expo's docs flag as unsupported by Apple. The option that avoids that and stays in TypeScript (`expo-share-extension`) is a single-maintainer library that currently lags the Expo SDK. The robust choice in an Expo app is therefore a Swift share extension, which means the Expo path includes some Swift regardless.

### Reminders (EventKit)

**Platform facts (verified).**

- `EKEventStore`, `EKReminder` and `fetchReminders(matching:completion:)` are available on iOS, Mac Catalyst and macOS. [EKEventStore](https://developer.apple.com/documentation/eventkit/ekeventstore), [EKReminder](https://developer.apple.com/documentation/eventkit/ekreminder), [fetchReminders](https://developer.apple.com/documentation/eventkit/ekeventstore/fetchreminders(matching:completion:))
- "Your app can't request read-only access to either events or reminders. To read events or reminders from the event store, your app needs full access." The app must include `NSRemindersFullAccessUsageDescription`; on iOS 17 or later a missing key causes automatic denial. [Accessing the event store](https://developer.apple.com/documentation/eventkit/accessing-the-event-store)

**SwiftUI.** First-party on both iPhone and Mac.

**Expo / React Native.** `expo-calendar` is Expo's own package. It provides `calendar.listReminders(startDate, endDate, status)`, `reminder.update(details)` and a `completed` property, and its config plugin sets the usage description keys. Reminders functions are iOS only and need a development build, not Expo Go. [Expo Calendar docs](https://docs.expo.dev/versions/latest/sdk/calendar/). The object-oriented Calendar API became stable in SDK 56. [Expo SDK 56 changelog](https://expo.dev/changelog/sdk-56)

The community alternative `react-native-calendar-events` was last published to npm in 2022 and is not needed. [npm](https://www.npmjs.com/package/react-native-calendar-events)

**Inference.** `expo-calendar` does not list macOS, so a react-native-macos app would need a custom native module for Reminders.

### Text recognition for cookbook photos

**Platform facts (verified).**

- Vision `RecognizeTextRequest` is available on iOS 18 or later and macOS 15 or later. The older `VNRecognizeTextRequest` is available from iOS 13 and macOS 10.15. [RecognizeTextRequest](https://developer.apple.com/documentation/vision/recognizetextrequest), [VNRecognizeTextRequest](https://developer.apple.com/documentation/vision/vnrecognizetextrequest)
- VisionKit `ImageAnalyzer` (Live Text) is available on iOS 16 or later and macOS 13 or later. [ImageAnalyzer](https://developer.apple.com/documentation/visionkit/imageanalyzer)
- The document scanner `VNDocumentCameraViewController` is available on iOS and Mac Catalyst but is not listed for native macOS. [VNDocumentCameraViewController](https://developer.apple.com/documentation/visionkit/vndocumentcameraviewcontroller)

**SwiftUI.** First-party.

**Expo / React Native.** No Expo first-party OCR package was found. Community options:

- [`expo-text-extractor`](https://github.com/pchalupa/expo-text-extractor): uses Apple Vision on iOS and ML Kit on Android. v2.0.0 released 2026-02-28. 72 stars, so a small project.
- [`@react-native-ml-kit/text-recognition`](https://github.com/a7medev/react-native-ml-kit): v2.0.0, last published 2025-09-01; last commit 2025-09-06.

**Inference.** The map for this project places import processing in the cloud and accepts AI-backed import. If cookbook photos are sent to a vision-capable model in the backend, on-device OCR is optional in either stack and this feature does not separate the two. That is a decision for the import tickets, not this one.

### Background execution

**Platform facts (verified).**

- `BGTaskScheduler` and `BGAppRefreshTask` are available on iOS, Mac Catalyst, tvOS and visionOS. Native macOS is not listed. [BGTaskScheduler](https://developer.apple.com/documentation/backgroundtasks/bgtaskscheduler), [BGAppRefreshTask](https://developer.apple.com/documentation/backgroundtasks/bgapprefreshtask)
- "The system decides the best time to launch your background task, and provides your app up to 30 seconds of background runtime." [Choosing Background Strategies for Your App](https://developer.apple.com/documentation/backgroundtasks/choosing-background-strategies-for-your-app)
- Background pushes are not guaranteed: "the system doesn't guarantee their delivery", and the guidance is "don't try to send more than two or three per hour". [Pushing background updates to your App](https://developer.apple.com/documentation/usernotifications/pushing-background-updates-to-your-app)
- Native macOS has `NSBackgroundActivityScheduler` for repeating deferrable work. [NSBackgroundActivityScheduler](https://developer.apple.com/documentation/foundation/nsbackgroundactivityscheduler)

**SwiftUI.** First-party. SwiftUI also has a `backgroundTask(_:action:)` scene modifier. [BackgroundTask](https://developer.apple.com/documentation/swiftui/backgroundtask)

**Expo / React Native.** `expo-background-task` is Expo's own package and wraps `BGTaskScheduler` on iOS. The minimum interval is 15 minutes, "the system may choose to run the task at a later time", and the API is unavailable on iOS simulators. [Expo BackgroundTask docs](https://docs.expo.dev/versions/latest/sdk/background-task/)

**Inference.** The scheduling limits are the operating system's and are the same in both stacks. A "daily read" on iPhone is best-effort in either stack; the exact time cannot be chosen. A native Mac app is not suspended in the way an iPhone app is, so a Mac that is usually on is the more reliable host for the daily Reminders read. Only the SwiftUI path produces a native Mac app. This affects the sync design and should be raised with the Reminders sync ticket.

### Push and local notifications

**Platform facts (verified).** `UNUserNotificationCenter` is available on iOS, Mac Catalyst and macOS. [UNUserNotificationCenter](https://developer.apple.com/documentation/usernotifications/unusernotificationcenter)

**SwiftUI.** First-party. The backend sends to APNs directly.

**Expo / React Native.** `expo-notifications` is Expo's own package. It supports Android and iOS, push requires a development build and Apple Developer credentials, and background remote notifications are enabled with the `enableBackgroundRemoteNotifications` plugin property. [Expo Notifications docs](https://docs.expo.dev/versions/latest/sdk/notifications/)

react-native-macos has an open issue titled "Native local notifications in macOS" (#2122). [react-native-macos issues](https://github.com/microsoft/react-native-macos/issues)

### Video playback

**Platform facts (verified).**

- AVKit `VideoPlayer` is a SwiftUI view available on iOS 14 or later and macOS 11 or later. [VideoPlayer](https://developer.apple.com/documentation/avkit/videoplayer)
- SwiftUI `WebView` is available on iOS 26 or later and macOS 26 or later. [WebView](https://developer.apple.com/documentation/webkit/webview-swift.struct)

**SwiftUI.** First-party for both direct video and embedded web players.

**Expo / React Native.**

- `expo-video` is Expo's own package, built on AVKit on iOS, and supports Android, iOS, tvOS and web. It supports picture in picture, background playback and HLS. macOS is not listed. [Expo Video docs](https://docs.expo.dev/versions/latest/sdk/video/)
- [`react-native-video`](https://github.com/TheWidlarzGroup/react-native-video): v6.19.3 released 2026-09-18, 7,718 stars, 103 open issues.
- [`react-native-webview`](https://github.com/react-native-webview/react-native-webview): v16.0.0 released 2026-07-11, 7,193 stars, 25 open issues.
- [`react-native-youtube-iframe`](https://github.com/LonelyCpp/react-native-youtube-iframe): last release v2.4.1 on 2025-07-01, with no commits since.

**Inference.** YouTube, Instagram and TikTok content would normally play through each service's embedded web player inside a web view, in either stack. Whether each service's embed works and is permitted was not researched here.

## Mac support options

| Option | What you get | Works on Intel Macs | Status for KitchenMate |
|---|---|---|---|
| SwiftUI multiplatform target | Native Mac app from the same target as the iPhone app | Yes | Available. All feature APIs exist on macOS except `BGTaskScheduler` and the document camera |
| Mac Catalyst | iPad app rebuilt for Mac | Yes | Available for a UIKit or SwiftUI iOS app. Not an Expo-supported target |
| "Designed for iPad" (iOS app on Mac) | The unmodified iOS app running on the Mac | No, Apple silicon only | Available to both stacks. The only practical Mac route for Expo |
| react-native-macos | Native Mac app from React Native | Yes | Lagging and outside Expo's support |

### SwiftUI multiplatform (verified)

"iOS, iPadOS, macOS, tvOS, and visionOS apps can share a single target." Platform-specific code is separated with conditional statements. [Configuring a multiplatform app](https://developer.apple.com/documentation/xcode/configuring-a-multiplatform-app-target)

TestFlight supports macOS apps. [TestFlight overview](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview)

### Mac Catalyst (verified)

"With Mac Catalyst, you can make a Mac version of your iPad app." Catalyst apps "can only use AppKit APIs marked as available in Mac Catalyst". [Mac Catalyst](https://developer.apple.com/documentation/uikit/mac-catalyst)

For Expo, an Expo maintainer suggested Mac Catalyst as a possible alternative to macOS support, but no official Expo documentation for building a Catalyst app was found. [expo/expo discussion #22273](https://github.com/expo/expo/discussions/22273). Treat Catalyst with Expo as unsupported.

### "Designed for iPad" on Apple silicon Macs

Verified:

- "iOS Apps on Mac runs your unmodified iPhone and iPad apps on Apple silicon with no porting process. Your apps use the same frameworks and infrastructure that Mac Catalyst apps use to run". [Running your iOS apps in macOS](https://developer.apple.com/documentation/apple-silicon/running-your-ios-apps-in-macos)
- Distribution for personal use is supported: "Use TestFlight to distribute your app to your testers, or create an archive and export it using the ad-hoc or development distribution method." Same source.
- Extensions: "A variety of extensions are also supported. For example, share extensions, WidgetKit widgets, photo editing extensions, VPN network extensions, audio units, and more." Supported functionality includes "background app refresh, user notifications, camera access, Siri intents, and more." [WWDC21: Qualities of great iPad and iPhone apps on Macs with M1](https://developer.apple.com/videos/play/wwdc2021/10056/)
- "macOS provides versions of all iOS frameworks for your app to link with, but some features of those frameworks may be unavailable in macOS." [Adapting iOS code to run in the macOS environment](https://developer.apple.com/documentation/apple-silicon/adapting-ios-code-to-run-in-the-macos-environment)
- iPhone-only apps run in a fixed-size window. An app must adopt iPad multitasking to get a resizable window. [Running your iOS apps in macOS](https://developer.apple.com/documentation/apple-silicon/running-your-ios-apps-in-macos)
- The app reports an iPad or iPhone idiom, not Mac. [Adapting iOS code to run in the macOS environment](https://developer.apple.com/documentation/apple-silicon/adapting-ios-code-to-run-in-the-macos-environment)

Inference, not verified:

- EventKit Reminders access should work in this mode, because EventKit is available on Mac Catalyst and this mode uses the same frameworks. No Apple source states this directly for Reminders.
- The share extension statement is from a 2021 session. Whether an iOS share extension appears in the share menu of Mac apps such as Safari on macOS 26 or 27 was not confirmed.
- No source was found confirming that an Expo-built app behaves correctly in this mode.

### react-native-macos

Verified:

- The React Native docs list React Native macOS under "From Partners"; it is maintained by Microsoft, not by the React Native core team. [Out-of-tree platforms](https://reactnative.dev/docs/out-of-tree-platforms)
- Latest version is 0.81.9 against React Native 0.87.1, a gap of six minor versions. [npm react-native-macos](https://www.npmjs.com/package/react-native-macos), [npm react-native](https://www.npmjs.com/package/react-native)
- The repository is active: last commit 2026-09-29, 4,386 stars, 87 open issues, 27 open pull requests. [react-native-macos](https://github.com/microsoft/react-native-macos)
- A tracker for versions 0.83 to 0.87 was opened on 2026-09-21. It reports pull requests passing CI and that no merges or npm publications have occurred yet. [Issue #3098](https://github.com/microsoft/react-native-macos/issues/3098)
- Open New Architecture bugs include "useNativeDriver: true animations never run on the New Architecture" (#3079) and "Multiline TextInput does not scroll in Fabric" (#2905). [Issues](https://github.com/microsoft/react-native-macos/issues)
- "macOS support for Expo modules is currently experimental." [Install Expo modules](https://microsoft.github.io/react-native-macos/docs/guides/installing-expo-modules)
- Expo maintainer statement, 2025-11-22: "We've already put a lot of efforts into supporting the macOS platform, but at the moment maintaining this platform would be too expensive for us." [expo/expo discussion #22273](https://github.com/expo/expo/discussions/22273)
- The Expo packages this app needs do not list macOS: `expo-calendar` reminders (iOS), `expo-notifications` (Android, iOS), `expo-video` (Android, iOS, tvOS, web). Sources are the package docs linked above.

Inference: a react-native-macos app would be a second app project on an older React Native version, outside Expo's tooling, with custom native modules for Reminders and notifications. It is not a sensible choice for this project.

## Owner background and AI-written code

Verified:

- React Native's own guidance is to use a framework for new apps, and it names Expo. [React Native: Get started](https://reactnative.dev/docs/environment-setup)
- Expo apps can be built locally without Expo's paid build service: `npx expo run:ios` runs prebuild and compiles with Xcode. [Expo local app development](https://docs.expo.dev/guides/local-app-development/). Xcode is therefore required in both stacks.
- Expo Go cannot be used for this app. Reminders, push notifications and share extensions each require a development build. Sources are the package docs linked above.
- Supabase publishes an official Swift client covering database, auth, realtime, storage and edge functions. [Supabase Swift reference](https://supabase.com/docs/reference/swift/introduction)
- Xcode 26.3 added agentic coding with Anthropic's Claude Agent and OpenAI's Codex, and exposes Xcode capabilities through the Model Context Protocol. [Apple Newsroom, 2026-02-03](https://www.apple.com/newsroom/2026/02/xcode-26-point-3-unlocks-the-power-of-agentic-coding/)
- Expo UI lets a React Native app use SwiftUI components and is described as production-ready from SDK 56. [Expo UI docs](https://docs.expo.dev/versions/latest/sdk/ui/), [Expo SDK 56 changelog](https://expo.dev/changelog/sdk-56)

Assessment (inference):

| Consideration | Favours | Why |
|---|---|---|
| Owner can read and debug the code | Expo | TypeScript and React are familiar; Swift is not |
| Shared types and logic with the backend | Expo | One language across client and server |
| Fewest moving parts for an agent to keep working | SwiftUI | One toolchain and one vendor; no JavaScript-to-native bridge, config plugins or prebuild step |
| Stability over time | SwiftUI | No dependency on community libraries tracking Expo SDK releases, which occur several times a year |
| Platform fit | SwiftUI | Both targets are Apple platforms and most features are Apple-specific |
| Swift still required | Neutral to SwiftUI | The robust share extension in Expo is written in Swift anyway |

The owner's lean toward React Native is reasonable and the Expo path would work on iPhone. The lean is weighed against two facts: the project has no Android target, and the Mac is a stated target. How well an AI agent performs in Swift compared with TypeScript for this app was not measured and is not claimed here.

## Other candidates

None is recommended. Each adds a layer between the app and the Apple APIs it depends on without an offsetting benefit for a single-user Apple-only app.

| Candidate | Verified | Why not (inference) |
|---|---|---|
| Flutter | Version 3.47 supports iOS 15 to 27 and macOS 12 to 27. [Supported platforms](https://docs.flutter.dev/reference/supported-platforms) | Native Mac support is real, but Dart is new to the owner and the share extension, Reminders and OCR all need plugins or Swift |
| Kotlin Multiplatform with Compose Multiplatform | Compose Multiplatform is stable for iOS and desktop (JVM). [Supported platforms](https://kotlinlang.org/docs/multiplatform/supported-platforms.html) | The Mac target is a JVM desktop app, and Kotlin is new to the owner |
| Capacitor | Version 8. Officially documents iOS, Android and web. [Capacitor docs](https://capacitorjs.com/docs) | Web UI in a web view; native features and the share extension still need Swift; no native Mac target |
| Tauri 2 | Targets "all major desktop and mobile platforms"; web frontend with Rust, Swift and Kotlin for native logic. [Tauri docs](https://v2.tauri.app/start/) | Adds Rust, and the Apple features still need Swift plugins |

## Recommendation

**Choose SwiftUI with a single multiplatform target for iPhone and Mac, and keep the client thin.**

1. All seven features in the ticket are first-party APIs with Apple documentation, on both target platforms.
2. It is the only option that gives a native Mac app, which also gives the most reliable host for the daily Reminders read.
3. The share extension, which is the main entry point for recipe import, is built with the supported mechanism on both platforms.
4. There are no third-party client libraries to keep in step with framework releases, other than the official Supabase client.
5. The owner's TypeScript skills stay fully used in the cloud backend, where the map already places import processing, weekly picks, HEB calls and push.

**Costs of this choice, stated plainly:**

- The owner cannot easily review Swift code and depends more on the AI agent and on tests.
- No shared types between client and backend. An API contract or generated types would be needed.
- No hot reload of the React Native kind; SwiftUI previews are the nearest equivalent.

**Fallback: Expo SDK 57 or later for iPhone, run on the Mac as "Designed for iPad".** Choose this if reading and maintaining the client in TypeScript matters more than the points above. Accept these conditions:

- The Mac must be Apple silicon.
- The Mac app is the iPad layout in a window, not a native Mac app.
- Write the share extension in Swift through `@bacons/apple-targets`, or accept the experimental open-the-main-app mechanism.
- Do not plan on react-native-macos.

## Open questions and suggested spikes

1. **Is the owner's Mac Apple silicon?** The fallback depends on it.
2. **Which device performs the daily Reminders read?** iPhone background scheduling is best-effort. A native Mac app is a more reliable host. This belongs to the Reminders sync ticket.
3. **Is on-device OCR needed**, or will cookbook photos go to a cloud model? This belongs to the import tickets.
4. **Does the share extension need its own UI** (for example a confirmation or tag picker inside the share sheet), or is a silent save enough? This decides how much the share extension differs between stacks.
5. **Spike, either stack:** confirm an iOS share extension appears in the Mac share menu under "Designed for iPad", and that Reminders access works there. Apple's sources are general, not specific to these cases.
6. **Spike, Expo only:** confirm `expo-calendar` can read Reminders from inside an `expo-background-task` run. No source confirmed this.
7. **Distribution:** TestFlight builds expire after 90 days ([TestFlight overview](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview)). A personal app needs a routine for re-uploading or for installing development builds directly. This applies to both stacks.

## Sources not reached

- Apple's statement on share extensions under "Designed for iPad" comes from a WWDC 2021 session transcript, not from current reference documentation. No current reference page stating it was found.
- The Xcode 27 release date was not confirmed on an Apple page; only the release notes content was read.
- Maintainer responsiveness on `expo-share-extension` issues was not assessed beyond commit and release dates.
