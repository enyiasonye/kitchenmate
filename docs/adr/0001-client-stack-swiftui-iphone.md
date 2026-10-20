# 1. Client stack: SwiftUI, iPhone only for V1

Date: 2026-10-20
Status: Accepted
Ticket: [Choose the client stack](https://github.com/enyiasonye/kitchenmate/issues/12)

## Context

KitchenMate needs a native client. The owner's background is Node/TypeScript and they started out leaning towards React Native; they have no prior Swift or mobile experience. The research in [Client stack: SwiftUI vs React Native](https://github.com/enyiasonye/kitchenmate/issues/3) ([findings](https://github.com/enyiasonye/kitchenmate/blob/main/docs/research/client-stack.md)) recommended SwiftUI with moderate confidence. Its main argument was the Mac: there is no practical React Native route to a native Mac app.

The owner will mostly use the app on their iPhone. A Mac app would be nice to have but is not needed for V1.

## Decision

- The client is **SwiftUI**: one multiplatform Xcode target, with only iOS enabled for V1.
- **The Mac is out of scope for V1.** Keeping it in the same target means it can be switched on later without a rewrite.
- **Minimum OS: iOS 27.** It is a personal install, so there is no reason to support older versions.
- The daily Reminders read runs on the **iPhone**. The Mac launch agent in the Reminders research is dropped. Trigger reliability is tested in [Reminders sync trigger prototype](https://github.com/enyiasonye/kitchenmate/issues/23).

## Why SwiftUI holds without the Mac

- The share extension and the Reminders App Intent need Swift in either stack. Expo would mean two languages plus the code that connects them.
- Reminders (EventKit), on-device text recognition (Vision), the share sheet, notifications and video are all built-in Apple APIs in SwiftUI. In Expo, receiving shares is experimental or community-maintained.
- There is no Android target, so React Native's cross-platform benefit does not apply.
- The owner's TypeScript skills are still used in the cloud backend, which holds most of the logic.

## Consequences

- The owner cannot easily review Swift. Client code is mostly agent-written, so the owner will judge it mainly by how it behaves and by its tests.
- No types are shared between the Swift client and the TypeScript backend. How the contract is expressed (generated OpenAPI client, Supabase Swift SDK, etc.) is decided in [Choose backend hosting and AI provider](https://github.com/enyiasonye/kitchenmate/issues/13).
- With only one device running the daily read, the backend watchdog notification is the only safety net for a missed run.

## Rejected

- **Expo (React Native) on iPhone, run on the Mac as "Designed for iPad".** This was credible only as a fallback. Once the Mac was dropped, it still needed Swift for the extension and intent, and its share-extension support is the weakest part.
