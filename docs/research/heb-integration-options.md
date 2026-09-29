# HEB integration options

Research for [issue #2](https://github.com/enyiasonye/kitchenmate/issues/2). Researched 2026-09-29.

## Summary

- **There is no official way to write to an H-E-B account.** No public H-E-B developer API, portal, or partner feed for consumers/third-party apps was found. Every working option uses undocumented endpoints or browser automation, and every one of them conflicts with H-E-B's Terms of Use.
- **Two unofficial paths exist, and they behave very differently:**
  - **Web path** (`www.heb.com/graphql`, cookie auth). Sits behind Imperva bot protection. Two independent reports from 2026 say it is not usable from a headless server: the login cookie lasts about 30 minutes, automated re-login is blocked, and plain Node requests are rejected even with fresh cookies.
  - **Mobile-app path** (H-E-B's mobile GraphQL host, OAuth bearer tokens + refresh token). This is the only path with evidence of unattended server-side use. It supports product search, product detail, and cart writes in the `heb-sdk-unofficial` TypeScript SDK. It works by presenting itself as the official iOS app.
- **Cart writes are well supported; shopping-list writes are not.** The best-fit SDK only *reads* shopping lists. List writes exist only in an unmerged PR (web path) and a small unmaintained repo.
- **All clients break periodically** because H-E-B rotates GraphQL persisted-query hashes on deploys. Expect hand maintenance.
- **Instacart is the only sanctioned API**, but it puts items in an *Instacart* cart, not the owner's H-E-B account, so it does not meet the stated requirement.
- **Recommendation:** build on the mobile bearer-token path via `heb-sdk-unofficial`, target the **cart** rather than the shopping list, isolate it behind a store adapter, and design a manual fallback (checklist of matched products) for the periods when it is broken. Accept in an ADR that this violates H-E-B's terms and could lead to account suspension.

Confidence labels used below: **Verified** = read directly in the primary source. **Reported** = claimed by a third party in an issue/README, not reproduced here. **Inference** = my conclusion. Nothing in this document was tested against a live H-E-B account.

---

## 1. Official and semi-official options

### 1.1 H-E-B itself

- **No public API found.** Searches for an H-E-B developer portal, affiliate program, or product feed turned up only supplier and employee portals ([Supplier Portal](https://supplierportal.heb.com/s/), [Partner Services](https://www.heb.com/static-page/H-E-B-partner-services)) and an affiliate program for H-E-B *Mexico* run through a third-party network ([FlexOffers](https://www.flexoffers.com/affiliate-programs/heb-mx-affiliate-program/)). None of these expose catalog search or cart/list writes for a US customer account. (Verified that these pages exist; absence of an API is a negative finding and cannot be fully proven.)
- The unofficial SDK's own FAQ confirms it is not official: "This SDK is unofficial and maintained independently" ([faq.mdx](https://github.com/iHildy/heb-sdk-unofficial/blob/main/packages/docs/src/content/docs/docs/faq.mdx)).
- **Not verified:** whether H-E-B would grant written consent or API access on request. The Terms of Use repeatedly carve out "H-E-B's express prior written consent", so asking is possible, but no process for it is published.

### 1.2 Instacart Developer Platform

- Instacart has a public API that creates a hosted shopping-list or recipe page and returns a link: `POST /idp/v1/products/products_link` ([Create shopping list page](https://docs.instacart.com/developer_platform_api/api/products/create_shopping_list_page)). Line items are matched by name, with optional UPCs or product IDs. (Verified.)
- The user then picks a store, adds items to their cart, and checks out on Instacart, logging in to Instacart if needed ([Shopping list concept](https://docs.instacart.com/developer_platform_api/guide/concepts/shopping_list/)). (Verified.)
- A nearby-retailers endpoint returns `retailer_key` values ([Get nearby retailers](https://docs.instacart.com/developer_platform_api/api/retailers/get_nearby_retailers)). The changelog is reported to include a preferred-retailer option for recipe pages ([Changelog](https://docs.instacart.com/developer_platform_api/api/changelog/)). (Endpoint verified; preselection mechanics not verified.)
- H-E-B has a storefront on Instacart, labelled "Higher than in-store prices" ([Instacart H-E-B storefront](https://www.instacart.com/store/h-e-b/storefront)). (Verified the storefront exists. **Not verified** that H-E-B is returned by the Developer Platform API for the owner's postal code.)
- A production key requires a review: Instacart checks terms compliance, request formatting, and error handling, and asks for a demo ([Approval process](https://docs.instacart.com/developer_platform_api/guide/concepts/launch_activities/approval_process)). Access is at Instacart's discretion ([Developer terms](https://docs.instacart.com/developer_platform_api/guide/terms_and_policies/developer_terms/)). (Verified.) Whether a single-user personal app would be approved is **not verified**.

**Why it does not meet the requirement:** items land in an Instacart cart and are fulfilled by Instacart at marked-up prices. Nothing is written to the owner's H-E-B account, cart, or shopping list. (Inference from the verified flow above.)

### 1.3 Other

- H-E-B owns Favor Delivery ([Wikipedia: Favor Delivery](https://en.wikipedia.org/wiki/Favor_Delivery)). No public Favor API was found. One open-source project reports Favor checkout needs an SMS code only the account owner can complete ([menderle/grocery-agent README](https://github.com/menderle/grocery-agent)). (Reported.)
- Recipe apps with retailer integrations (Samsung Food/Whisk, AnyList) were checked; no H-E-B integration was found ([Samsung Food partners](https://samsungfood.com/partners/)). (Negative finding, not exhaustive.)

---

## 2. How the unofficial H-E-B API works

All facts here come from reading the source of [`iHildy/heb-sdk-unofficial`](https://github.com/iHildy/heb-sdk-unofficial) unless noted.

### 2.1 Two hosts, two auth modes

| | Web path | Mobile path |
|---|---|---|
| Host | `www.heb.com/graphql` | H-E-B mobile GraphQL edge host |
| Auth | Browser cookies: a session JWT plus bot-protection cookies | OAuth bearer access token |
| How you get it | Log in with a real browser, copy cookies | OAuth Authorization Code + PKCE against `accounts.heb.com`, using the iOS app's client ID and redirect scheme |
| Refresh | None without a browser | `refresh_token` grant |
| Source | [`types.ts` ENDPOINTS](https://github.com/iHildy/heb-sdk-unofficial/blob/main/packages/heb-sdk/src/types.ts), [`session.ts`](https://github.com/iHildy/heb-sdk-unofficial/blob/main/packages/heb-sdk/src/session.ts) | [`heb-auth/src/oauth.ts`](https://github.com/iHildy/heb-sdk-unofficial/blob/main/packages/heb-auth/src/oauth.ts) |

- Both use **GraphQL persisted queries**: the client sends an operation name and a SHA-256 hash rather than query text ([`api.ts`](https://github.com/iHildy/heb-sdk-unofficial/blob/main/packages/heb-sdk/src/api.ts)). The hashes are hardcoded in the SDK. (Verified.)
- The SDK was built by capturing iOS app traffic with mitmproxy and website traffic with browser dev tools ([CONTRIBUTING.md](https://github.com/iHildy/heb-sdk-unofficial/blob/main/CONTRIBUTING.md)). (Verified.)
- The mobile path sends a user agent string identifying itself as the official "MyHEB" iOS app ([`session.ts`](https://github.com/iHildy/heb-sdk-unofficial/blob/main/packages/heb-sdk/src/session.ts)). The project's own README describes this plainly: "Since we are a third-party, we impersonate the H-E-B mobile OAuth client" ([heb-mcp README](https://github.com/iHildy/heb-sdk-unofficial/blob/main/packages/heb-mcp/README.md)). (Verified.)

### 2.2 Which path supports what

Per the SDK's [sessions doc](https://github.com/iHildy/heb-sdk-unofficial/blob/main/packages/docs/src/content/docs/docs/sessions.mdx) and [troubleshooting doc](https://github.com/iHildy/heb-sdk-unofficial/blob/main/packages/docs/src/content/docs/docs/troubleshooting.mdx):

- **Bearer (mobile) required for:** product search, product details, buy-it-again, homepage, orders, account, weekly ad.
- **Cookie (web) suits:** cart, typeahead, store search, shopping lists.
- **Cart also works on bearer.** The request layer maps the web cart operations to mobile equivalents (`cartItemV2` to `addItemToCartV2`, `cartEstimated` to `cartV2`) when the session is a bearer session ([`api.ts` MOBILE_QUERY_MAP](https://github.com/iHildy/heb-sdk-unofficial/blob/main/packages/heb-sdk/src/api.ts)), and `cart.ts` parses the mobile cart shape ([`cart.ts`](https://github.com/iHildy/heb-sdk-unofficial/blob/main/packages/heb-sdk/src/cart.ts)). (Verified in source.)
- **Shopping-list reads on bearer:** the mobile hash table contains `GetShoppingListsV2` but not the single-list read `getShoppingListV2`, so reading one list's items falls back to the web hash sent to the mobile host. Whether that works is **not verified**.

### 2.3 Session lifetime and refresh

- **Bearer:** tokens are created with a 1800-second expiry in the docs example, and the SDK refreshes automatically near expiry if a `refresh` hook is set ([`session.ts` ensureFreshSession](https://github.com/iHildy/heb-sdk-unofficial/blob/main/packages/heb-sdk/src/session.ts), [sessions doc](https://github.com/iHildy/heb-sdk-unofficial/blob/main/packages/docs/src/content/docs/docs/sessions.mdx)). The maintainer recommends this path "because tokens can be refreshed on the server and don't require an active browser". (Verified.)
- **Initial login is manual.** The owner signs in (with one-time passcode) in a browser and the redirect to the app's custom URL scheme is captured to get the authorization code ([heb-mcp README](https://github.com/iHildy/heb-sdk-unofficial/blob/main/packages/heb-mcp/README.md)). (Verified.)
- **Refresh token lifetime: not verified.** No source states how long a refresh token lasts or what invalidates it. A downstream project rotates refresh tokens and writes them back to disk ([dkaygithub/heb-mcp README](https://github.com/dkaygithub/heb-mcp)), which implies rotation on use. (Reported.)
- **Cookie:** the session cookie is a JWT with a hard 30-minute lifetime, and the bot-protection cookie renews about every 11 minutes through page JavaScript ([texas-grocery-mcp issue #22](https://github.com/mgwalkerjr95/texas-grocery-mcp/issues/22), [PR #20](https://github.com/mgwalkerjr95/texas-grocery-mcp/pull/20), [README](https://github.com/mgwalkerjr95/texas-grocery-mcp)). (Reported, consistent across three sources.)

---

## 3. Survey of open-source clients

Repository metadata was read from the GitHub API on 2026-09-29.

| Project | Lang | Path | Search | Price | Aisle | Cart write | List read | List write | Stars | Last code change on main |
|---|---|---|---|---|---|---|---|---|---|---|
| [iHildy/heb-sdk-unofficial](https://github.com/iHildy/heb-sdk-unofficial) | TypeScript | Mobile bearer + web cookie | Yes | Yes | Not verified | Yes | Yes | **No** | 7 | 2026-08-31 |
| [mgwalkerjr95/texas-grocery-mcp](https://github.com/mgwalkerjr95/texas-grocery-mcp) | Python | Web cookie + Playwright | Yes | Yes | Yes | Yes | No (open PR) | No (open PR) | 63 | 2026-02-03 |
| [dkaygithub/heb-mcp](https://github.com/dkaygithub/heb-mcp) | TypeScript | Mobile bearer (wraps iHildy SDK) | Yes | Yes | - | Yes | - | - | 0 | 2026-05-20 |
| [gigq/HEBMCP](https://github.com/gigq/HEBMCP) | Node | Web cookie (manual export) | Yes | Yes | - | Yes | No | No | 0 | 2026-01-19 |
| [assumednormal/everyday-mcp-servers](https://github.com/assumednormal/everyday-mcp-servers) | TypeScript | Not verified | - | - | - | - | Yes | Yes | 0 | 2026-02-16 |
| [michellemayes/heb-grocery-agent](https://github.com/michellemayes/heb-grocery-agent) | TypeScript | Chrome extension driving heb.com | Yes | - | - | Yes | No | No | 4 | 2026-07-27 |
| [menderle/grocery-agent](https://github.com/menderle/grocery-agent) | Python | Real browser on a Mac + texas-grocery-mcp | Yes | Yes | - | Yes (and checkout) | - | - | 1 | 2026-08-06 |
| [Physicschick73/heb-grocery-order-skill](https://github.com/Physicschick73/heb-grocery-order-skill) | Shell + agent skill | Hosted browser automation | Yes | - | - | Yes | No | No | 0 | 2026-08-08 |
| [ayushdeshmukh/heb-automation](https://github.com/ayushdeshmukh/heb-automation) | Python | Browser automation | Yes | - | - | Yes | Yes | No | 2 | 2020-08-09 (dead) |
| [billcobbler/heb-to-go](https://github.com/billcobbler/heb-to-go) | Go | Old API | - | - | - | - | - | - | 0 | 2020-04-27 (dead) |

"-" means not checked or not applicable. Feature cells are from each project's README or source, not from running the code.

### 3.1 iHildy/heb-sdk-unofficial (best fit)

- **What it is:** a TypeScript monorepo with an SDK, an OAuth helper package, an MCP server, and a browser extension that forwards cookies ([README](https://github.com/iHildy/heb-sdk-unofficial)). Published to npm as `heb-sdk-unofficial` 1.0.1 and `heb-auth-unofficial` 0.1.1, both last published 2026-02-16 (npm registry). MIT licensed per [`package.json`](https://github.com/iHildy/heb-sdk-unofficial/blob/main/packages/heb-sdk/package.json); the repo itself has no license file detected by GitHub.
- **Capabilities (verified in [`client.ts`](https://github.com/iHildy/heb-sdk-unofficial/blob/main/packages/heb-sdk/src/client.ts)):** search, typeahead, product detail, SKU lookup, get cart, add/update/remove cart item, orders, account, shopping list reads, delivery/curbside slots and reservation, store search and set store, weekly ad.
- **Cart semantics:** cart mutations set the quantity rather than incrementing it, so adding relative quantities needs a cart read first (SDK skill docs, surfaced via [search result](https://lobehub.com/skills/ihildy-heb-sdk-unofficial-heb-sdk)). (Reported; secondary source.)
- **Shopping list writes are missing.** [`shopping-list.ts`](https://github.com/iHildy/heb-sdk-unofficial/blob/main/packages/heb-sdk/src/shopping-list.ts) exports only `getShoppingLists` and `getShoppingList`. The mobile hash table does contain `AddShoppingListItemsV2` and `CreateShoppingListV2`, but no code calls them ([`types.ts`](https://github.com/iHildy/heb-sdk-unofficial/blob/main/packages/heb-sdk/src/types.ts), confirmed by GitHub code search). So the operations were observed in app traffic but the variable shapes are undocumented. (Verified.)
- **Checkout is deliberately excluded.** The maintainer confirmed it is intentional ([issue #40](https://github.com/iHildy/heb-sdk-unofficial/issues/40)). A contributor PR adding checkout has been open since 2026-04-19 ([PR #41](https://github.com/iHildy/heb-sdk-unofficial/pull/41)).
- **Maintenance:** heavy activity January to mid-February 2026, then one merged community fix in June and one maintainer fix on 2026-08-31 ([commit history](https://github.com/iHildy/heb-sdk-unofficial/commits/main)). Two community PRs have sat open since April and May. Single maintainer. (Verified.) Inference: lightly maintained; do not count on upstream fixing breakage quickly.
- **Maintainer background:** the FAQ says the author "used to work for H-E-B Digital but developed this SDK without using any internal knowledge" ([faq.mdx](https://github.com/iHildy/heb-sdk-unofficial/blob/main/packages/docs/src/content/docs/docs/faq.mdx)). (Verified.)
- **Takedown-adjacent history:** in February 2026 the maintainer merged PRs titled "Remove H-E-B IP assets from documentation" and "Repository IP compliance", which removed H-E-B logos and also removed committed request files containing live session cookies and tokens ([PR #31](https://github.com/iHildy/heb-sdk-unofficial/pull/31), [PR #32](https://github.com/iHildy/heb-sdk-unofficial/pull/32)). Whether H-E-B requested this is **not verified**; nothing in the PRs says so.
- **Cookie bridge extension:** documented as "functional but no longer maintained" ([sessions doc](https://github.com/iHildy/heb-sdk-unofficial/blob/main/packages/docs/src/content/docs/docs/sessions.mdx)). (Verified.)
- **Evidence it works unattended:** a user reported on 2026-04-16 that it "Works great" driving an agent, and built a Docker deployment that refreshes tokens inside a long-running container ([issue #40](https://github.com/iHildy/heb-sdk-unofficial/issues/40), [dkaygithub/heb-mcp](https://github.com/dkaygithub/heb-mcp)). A contributor reported placing a real curbside order end to end ([PR #41](https://github.com/iHildy/heb-sdk-unofficial/pull/41)). (Reported; both are from April-May 2026, before the September breakage report below.)

### 3.2 mgwalkerjr95/texas-grocery-mcp (most popular, poor fit)

- **What it is:** a Python MCP server using heb.com's web GraphQL plus an embedded Playwright browser to refresh the session ([README](https://github.com/mgwalkerjr95/texas-grocery-mcp)). On PyPI as `texas-grocery-mcp`, latest 0.1.3 published 2026-02-03 (PyPI registry).
- **Capabilities:** store search, product search and batch search, product detail including aisle location, cart add/remove/get, coupons ([README](https://github.com/mgwalkerjr95/texas-grocery-mcp), [CHANGELOG](https://github.com/mgwalkerjr95/texas-grocery-mcp/blob/main/CHANGELOG.md)). (Verified in docs.)
- **Shopping list writes:** an open, unmerged PR adds list get/add/remove using web operations `addToShoppingListV2` and `deleteShoppingListItems` ([PR #13](https://github.com/mgwalkerjr95/texas-grocery-mcp/pull/13), open since 2026-04-16). This is the only place the list-write variable shape is visible: list ID, product ID, and quantity. (Verified in the PR diff.)
- **Maintenance:** the last commit on main is 2026-02-03, five days after the first commit ([commit history](https://github.com/mgwalkerjr95/texas-grocery-mcp/commits/main)). Seventeen issues and PRs are open, including fixes for stale hashes, with no maintainer response ([issues](https://github.com/mgwalkerjr95/texas-grocery-mcp/issues)). (Verified.) Inference: effectively abandoned; the 63 stars and 30 forks reflect interest, not health.
- **Stores the account password:** it offers to save the H-E-B email and password in the system keyring for auto-login ([README](https://github.com/mgwalkerjr95/texas-grocery-mcp)). (Verified.)

### 3.3 Browser-driving projects

- The Chrome extension, the Mac-hosted agent, and the hosted-browser skill all work by driving the real heb.com site in a browser where the owner has logged in by hand ([heb-grocery-agent](https://github.com/michellemayes/heb-grocery-agent), [grocery-agent](https://github.com/menderle/grocery-agent), [heb-grocery-order-skill](https://github.com/Physicschick73/heb-grocery-order-skill)). (Verified in READMEs.)
- The Mac-hosted agent states: "H-E-B blocks automated logins, so this is done by hand once", and requires "A Mac to run it on (kept awake)" ([grocery-agent README](https://github.com/menderle/grocery-agent)). (Reported.)
- Notable overlap with KitchenMate: the hosted-browser skill does Apple Reminders to H-E-B cart, and marks reminders complete only for items successfully carted ([heb-grocery-order-skill README](https://github.com/Physicschick73/heb-grocery-order-skill)). Useful as a behavior reference, not as code.

---

## 4. Breakage history

| Date | What broke | Source |
|---|---|---|
| 2026-04-17 | Cart persisted-query hashes stale in texas-grocery-mcp | [PR #15](https://github.com/mgwalkerjr95/texas-grocery-mcp/pull/15) |
| 2026-05-20 | Pickup fulfillment hash stale; "break whenever HEB ships new frontend code" | [issue #19](https://github.com/mgwalkerjr95/texas-grocery-mcp/issues/19) |
| 2026-05-23 | Session refresh reported success while the bot-protection token had not renewed | [PR #20](https://github.com/mgwalkerjr95/texas-grocery-mcp/pull/20) |
| 2026-07-29 | Typeahead and cart hashes stale; automated login blocked; 30-minute session makes unattended use impractical | [issue #22](https://github.com/mgwalkerjr95/texas-grocery-mcp/issues/22) |
| 2026-09-22 | Web cart hash in heb-sdk-unofficial stale; Node requests to the web host rejected even with fresh cookies | [issue #45](https://github.com/iHildy/heb-sdk-unofficial/issues/45) |

- **Pattern:** hash rotation on the web path was reported roughly every one to two months in 2026. (Inference from the table.)
- **Every report above is about the web path.** No issue reporting stale *mobile* hashes or bot blocking on the mobile host was found in either repo. This may mean the mobile path is more stable (mobile app versions in the field need their hashes to keep working), or simply that fewer people use it. (Inference; **not verified**.)
- The SDK's mobile user agent pins a specific iOS app version ([`session.ts`](https://github.com/iHildy/heb-sdk-unofficial/blob/main/packages/heb-sdk/src/session.ts)). If H-E-B retires support for that app version, the mobile path would break until hashes are re-captured from a newer app. (Inference.)
- Proposed mitigation in the community: detect the "persisted query not found" error, rediscover the hash from a real page load, cache it, and retry ([issue #19](https://github.com/mgwalkerjr95/texas-grocery-mcp/issues/19), [PR #21](https://github.com/mgwalkerjr95/texas-grocery-mcp/pull/21)). Unmerged. This only works where a real browser is available.

---

## 5. Bot detection

- **heb.com uses Imperva (Incapsula) bot protection.** The bot-protection cookie names used throughout both SDKs are Imperva's, and the block response quoted in issues is Imperva's error format ([issue #45](https://github.com/iHildy/heb-sdk-unofficial/issues/45), [troubleshooting doc](https://github.com/iHildy/heb-sdk-unofficial/blob/main/packages/docs/src/content/docs/docs/troubleshooting.mdx)). One issue author calls it Akamai; the evidence in the same issue points to Imperva. (Reported; vendor attribution is inference from cookie names and error format.)
- **Non-browser clients are rejected on the web host.** Same request, same fresh cookies: succeeds from a page inside a logged-in browser tab, fails from Node with HTTP 401. The reporter concludes this is client fingerprinting ([issue #45](https://github.com/iHildy/heb-sdk-unofficial/issues/45)). (Reported, 2026-09-22, single source.)
- **Automated login is blocked behaviorally.** A scripted browser is blocked before the login form loads, while a human driving the same browser window from the same IP gets through ([issue #22](https://github.com/mgwalkerjr95/texas-grocery-mcp/issues/22)). A second user confirms Playwright is detected ([issue #22 comment](https://github.com/mgwalkerjr95/texas-grocery-mcp/issues/22)). (Reported, two sources.)
- **CAPTCHA challenges occur** under rapid requests; the documented remedy is for a human to solve it ([TROUBLESHOOTING.md](https://github.com/mgwalkerjr95/texas-grocery-mcp/blob/main/docs/TROUBLESHOOTING.md)). (Verified in docs.)
- **Mobile host protection: not verified.** No source describes bot protection on the mobile GraphQL host. The SDK sends only a bearer token and a user agent there, with no bot-protection cookies ([`session.ts` buildBearerHeaders](https://github.com/iHildy/heb-sdk-unofficial/blob/main/packages/heb-sdk/src/session.ts)), and users reported that working in April-May 2026. H-E-B could add app attestation or similar at any time.
- **Cloud IP reputation: not verified.** A comment on issue #22 claims datacenter IPs are scored more harshly, but it comes from a proxy vendor promoting its product and conflicts with the issue author's own same-IP test. Treat as unreliable.
- **Not recommended:** stealth browser plugins, fingerprint spoofing, or residential proxies. They escalate from "unsupported client" to actively defeating a security control, which raises both the legal exposure and the chance of account action. (Judgment.)

---

## 6. Terms-of-service risk

Source: [H-E-B Terms of Use](https://www.heb.com/terms), effective date August 8, 2024. Quotes verified against the page text on 2026-09-29. This is a reading of the terms, not legal advice.

Relevant rules of conduct. Users shall not:

- "Use any robot, spider, site search/retrieval application or other manual or automatic device to retrieve, index, 'scrape,' 'data mine' or otherwise gather Service content, or reproduce or circumvent the navigational structure or presentation of the Service, without H-E-B's express prior written consent."
- "Systematically download and store Service content."
- "Reverse engineer, decompile or disassemble any portion of the Service, except where such restriction is expressly prohibited by applicable law."
- "Frame or mirror any portion of the Service, or otherwise incorporate any portion of the Service into any product or service, without H-E-B's express prior written consent."

Other relevant terms:

- **License scope:** the site may be viewed "solely for your personal, non-commercial use", and the app license is to "install and use the App on a mobile device that you own or control" (section 3.2).
- **Account:** "Your account name and password are for your personal use only", and the account holder is responsible "for all activities, including purchases, that occur in connection with your account" (section 5).
- **Termination:** "We may terminate or suspend your use of the Service at any time and without prior notice, including if we believe that you have violated or acted inconsistently with the letter or spirit of these Terms" (section 22).
- **robots.txt** disallows `/graphql`, `/cart/`, `/search`, and `/my-account/` for all user agents ([robots.txt](https://www.heb.com/robots.txt)). (Verified.)

Assessment (inference):

- **Every unofficial approach violates these terms.** Product search from a backend is automated retrieval of Service content. Caching matched products is arguably systematic storage. Using captured hashes and app identity relies on reverse engineering. Building it into KitchenMate incorporates the Service into a product.
- **The mobile path adds a distinct issue:** it presents itself as H-E-B's own iOS app, using that app's OAuth client identity. That is a misrepresentation of the client, beyond merely being automated.
- **Realistic consequence for a single user on their own account:** suspension or termination of the H-E-B account, which would also take out curbside ordering, order history, and saved payment setup. No reports of H-E-B suspending accounts over these tools were found, but absence of reports is weak evidence.
- **Mitigating factors:** one user, own account, own credentials, low volume, human-paced, no resale or redistribution of data, no checkout automation. These reduce the likelihood of detection and the severity of the conduct. They do not make it permitted.
- **Public-repo exposure:** KitchenMate is a public repository. Publishing captured hashes, client identifiers, or session material increases visibility. The upstream SDK already had to purge committed session tokens ([PR #32](https://github.com/iHildy/heb-sdk-unofficial/pull/32)).

---

## 7. Ranked approaches

Ranked by fit to the requirement (items in the owner's real H-E-B account, backend in the cloud, owner's stack is Node/TypeScript, cost ceiling $10-25/month).

### 1. Mobile bearer-token path via `heb-sdk-unofficial`, cart as the target (recommended)

- **How:** one-time manual OAuth login by the owner; backend stores the encrypted refresh token, refreshes access tokens, and calls search, product detail, and cart add.
- **Why first:** the only path with evidence of unattended server-side operation; TypeScript, matching the owner's stack; no browser needed on the server; no extra hosting cost.
- **Risks:**
  - Violates H-E-B terms, including presenting as the official app. Account suspension is possible.
  - Lightly maintained upstream with a single maintainer. Plan to vendor or fork and to re-capture hashes yourself.
  - Refresh-token lifetime unknown. The owner may need to re-login periodically.
  - No evidence more recent than May 2026 that it still works. Must be validated by a spike before committing.
  - A stored refresh token grants full access to the account, including saved payment methods. Encrypt at rest and never log it.
- **Shopping list variant:** possible only by implementing list writes yourself from the observed mobile operations, with variable shapes you would have to capture from your own app traffic. Higher effort and more fragile than cart. Treat as a later enhancement.

### 2. On-device or in-browser execution on the owner's Mac (fallback)

- **How:** a helper on the Mac (browser extension or an app with an embedded web view) where the owner is logged in to heb.com normally; the backend queues items and the Mac helper performs the cart adds from inside the real browser session.
- **Why second:** requests that originate inside a real logged-in browser tab are the one thing reported to pass the web bot protection ([issue #45](https://github.com/iHildy/heb-sdk-unofficial/issues/45)). It also supports shopping-list writes using the web operations seen in [PR #13](https://github.com/mgwalkerjr95/texas-grocery-mcp/pull/13).
- **Risks:**
  - Breaks the "cloud does HEB calls" hosting shape in the map: sync only happens while the Mac is awake and logged in.
  - Web hashes rotate every one to two months, so it needs a hash rediscovery step.
  - Still violates the automated-access terms.
  - Whether the same works inside an iPhone app web view is **not verified**.

### 3. Manual-assist handoff (always-available floor)

- **How:** KitchenMate produces the matched product list and the owner adds items themselves, helped by deep links to product pages or a checklist view. Product matching data comes from approach 1 or 2 when available, or from the owner's saved item mappings.
- **Why third:** near-zero terms risk if no automated calls are made, and it cannot break. It does not satisfy the requirement on its own, but it is the fallback every other approach needs when it is broken.
- **Risks:** manual effort; product links may go stale. Whether H-E-B product URLs open the H-E-B iOS app directly is **not verified**.

### 4. Instacart Developer Platform (sanctioned, wrong destination)

- **How:** backend creates a shopping-list link; owner opens it and checks out on Instacart with H-E-B selected.
- **Why fourth:** the only option with a documented API and published terms, but items never reach the owner's H-E-B account, prices are marked up, and fulfillment is Instacart's.
- **Risks:** production approval is discretionary and built around commercial partners; H-E-B availability through the API for the owner's postal code is unverified.

### 5. Headless browser automation in the cloud (not recommended)

- **How:** run Playwright or a hosted browser service in the cloud to log in and drive heb.com.
- **Why last:** automated login is reported blocked, sessions last 30 minutes, and making it work means stealth tooling or proxies. It needs storing the account password, costs more to host, and carries the highest terms exposure.

### Not viable

- Plain server-side requests to the web host with copied cookies: reported blocked regardless of cookie freshness ([issue #45](https://github.com/iHildy/heb-sdk-unofficial/issues/45)).
- Adopting `texas-grocery-mcp` as a dependency: Python, abandoned on main, web path only.

---

## 8. Open questions

These need a hands-on spike or an owner decision. None could be settled from sources.

1. Does the mobile bearer path work today (search, cart add, token refresh) from a cloud host? All positive reports date from April-May 2026.
2. How long does a refresh token last, and does H-E-B require the one-time passcode again on re-login?
3. Cart or shopping list as the destination? Cart is supported today. List writes need new work and have no maintained implementation.
4. Does the owner accept the terms risk, including possible loss of the H-E-B account? This should be recorded as an ADR.
5. Should H-E-B-specific identifiers and hashes live outside the public repo (private config or a private package)?
6. Is sync that depends on the Mac being awake an acceptable fallback, given the map's hosting shape?
7. Is store and aisle location available on the mobile product detail response? It is confirmed only for the web path in `texas-grocery-mcp`.
