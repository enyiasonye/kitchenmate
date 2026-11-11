# iPhone Duo SDK facts: size classes and posture APIs

Issue #30. Researched 2026-11-11.

**Source tags:** [SDK] = local header/swiftinterface; [SIM] = local CoreSimulator device profile; [WEB] = developer.apple.com search-result summary (page not fully read); [UNVERIFIED] = not confirmed.

> Note: the installed toolchain is **Xcode 27.2 (27B52), iPhoneOS27.2.sdk**, not 27.1. Every API below is annotated `API_AVAILABLE(ios(27.1))` / `@available(anyAppleOS 27.1, *)`, so it was introduced in 27.1.

## Display sizes [SIM]
From `/Library/Developer/CoreSimulator/Profiles/DeviceTypes/iPhone Duo.simdevicetype/Contents/Resources/capabilities.plist` (model `iPhone19,4`, min runtime 27.1):

| Display | deviceName | Pixels | Scale | Points | ppi |
|---|---|---|---|---|---|
| Outer | `primary` | 1398 x 2034 | 3 | **466 x 678** | 460 |
| Inner | `primary-1` | 2007 x 2853 | 3 | **669 x 951** | 460 |

Both are about 1.45:1 in pixels, not the issue's ~1.41:1. Points come from dividing pixels by the scale; nobody checked them in a running app.

## Size classes
- Outer display: compact width, like other iPhones. Inner display: regular width **and** regular height. [WEB: [Preparing your app for iPhone Duo](https://developer.apple.com/documentation/technologyoverviews/preparing-your-app-for-iphone-duo)]
- Vertical size class on the outer display: [UNVERIFIED]. Presumably regular in portrait and compact in landscape, like other iPhones.
- In a multitasking window: [UNVERIFIED]. The profile has `DeviceSupportsSingleDisplayEnhancedMultitasking = false` and a `resizableScene` display [SIM]. A forum post reports that a pinned PiP reduces height while the vertical size class stays regular. That post is low trust.

## Fold state and posture detection [SDK]
UIKit (`UIHinge.h`, `UIHingeInteraction.h`):
- `UIHingeInteraction(updateHandler: (UIHingeInteraction, UIHingeInteraction.Update) -> Void)`. Add it to a view with `view.addInteraction`. The handler fires once with the initial state and again on every change. It has an `isEnabled` property.
- `UIHingeInteraction.Update.hinge: UIHinge?`. This is nil when the view leaves a hierarchy that provides hinge updates.
- `UIHinge.status: UIHinge.Status` (`.unknown`, `.closed`, `.partiallyOpen`, `.fullyOpen`) and `UIHinge.angle: CGFloat` in radians. The header warns that angle update rate and precision are system policy and tells apps to prefer `status`.

SwiftUI (`SwiftUICore.swiftinterface`):
- `View.onHingeChange(isEnabled: Bool = true, _ action: (DeviceHingeContext, DeviceHingeContext) -> Void)`, which passes the old and new context.
- `DeviceHingeContext.hinge: DeviceHinge?`, `DeviceHinge.status` (`.closed`, `.partiallyOpen`, `.fullyOpen`), and `DeviceHinge.angle: Angle`.

The SDK has no other `Fold`/`Posture` symbols in UIKit or SwiftUI headers.

## What SwiftUI preserves across fold/unfold — [UNVERIFIED]
The headers don't document this. Apple says a fold can **resize the app mid-session**, and that apps must re-read sizes on change instead of using `UIScreen.main` or reading once in `viewIsAppearing` [WEB]. That points to a resize of the same scene, not a reconnect, but nothing here confirms it. Whether navigation path, scroll position, `@State`, `@SceneStorage` and view identity survive is unconfirmed. The Tech Talk "Leverage multiple displays and scenes on iPhone Duo" (https://developer.apple.com/videos/play/tech-talks/111464/) is the likely source. To confirm, test in the iPhone Duo simulator.

## Adaptation APIs and fixing a 27.0-SDK build [WEB, partly SDK]
- An app built with the iOS 26 SDK runs at a familiar iPhone size instead of filling the inner display. An app built with the iOS 27 SDK resizes dynamically. **An app built with the iOS 27.1 SDK extends to the edge of the screen, and standard navigation and toolbar buttons lay out vertically under the status bar.** [WEB: [Three steps](https://developer.apple.com/iphone-duo/prepare/), [Preparing your app](https://developer.apple.com/documentation/technologyoverviews/preparing-your-app-for-iphone-duo)]. So the fix for the blank right-hand strip is mostly **rebuilding with the 27.1 SDK**. The claim that the blank strip is the 27.0 behaviour comes from the issue; I did not confirm it.
- Related APIs new in 27.1 [SDK]: `UIBarButtonItem.AxisBehavior` (`horizontalOnly`, `verticalPreferred`) / `axisBehavior`, a `UIVerticalBarEdge` (leading/trailing), `UIViewController.childForPreferredVerticalBarBehavior`, and the hinge APIs above. Whether Apple formally calls these the "adaptation APIs": [UNVERIFIED].
- Guidance [WEB]: drive layout from size classes, not idiom or orientation. Avoid `UIScreen.main`. Size from the view or window and respond to changes. Test poses in the Xcode 27.1 iPhone Duo simulator (Device Hub).

## Sources
- Local: `iPhoneOS27.2.sdk/.../UIKit.framework/Headers/UIHinge.h`, `UIHingeInteraction.h`, `UIBarButtonItem.h`; `SwiftUICore.swiftmodule/arm64e-apple-ios.swiftinterface` (lines ~16799–16831, ~24305); the simulator device profile above.
- https://developer.apple.com/documentation/technologyoverviews/preparing-your-app-for-iphone-duo
- https://developer.apple.com/iphone-duo/prepare/
- https://developer.apple.com/videos/play/tech-talks/111461/ , /111463/ , /111464/
