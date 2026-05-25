# Clonka QA Backlog

Verification checklist: each module/feature is tested against the legacy Jobka MAUI app and Kotlin Android app and the backend API.

**Status legend:** `[ ]` todo · `[x]` done · `[~]` partial · `[!]` broken · `[-]` skipped (not in scope)

---

## Auth & Session

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| A1 | Login with personal number + access code | `[ ]` | `GET /api/Employee/Login` → `ID_Login` |
| A2 | Logout clears session + redirects to `/login` | `[ ]` | |
| A3 | 401 response → auto logout + redirect | `[ ]` | Axios interceptor |
| A4 | Session token injected in all API requests | `[ ]` | |
| A5 | Maintenance mode check on startup | `[ ]` | `GET /api/Company/CheckState` |
| A6 | Registration flow | `[ ]` | RegisterPage |
| A7 | Multi-account profile switching | `[ ]` | profilesStore + useProfileSwitch |
| A8 | App lock (timeout → PIN/biometric) | `[ ]` | AppLockPage + appLockStore |
| A9 | Biometric unlock | `[ ]` | tauri-plugin-biometric |
| A10 | Unauthenticated users blocked from protected routes | `[ ]` | Router guard |
| A11 | Authenticated users redirected away from `/login` | `[ ]` | Router guard |
| A12 | Dev routes blocked for non-developers | `[ ]` | Router guard `/dev/*` |
| A13 | QR code login (camera scan) | `[ ]` | tauri-plugin-barcode-scanner |
| A14 | QR login fallback: camera unavailable → file upload | `[ ]` | jsQR browser fallback |
| A15 | QR login fallback: manual personal number entry | `[ ]` | |
| A16 | Silent re-login when saved profile has access code | `[ ]` | profilesStore auto-relogin |
| A17 | Saved profile tapped with active session → instant switch | `[ ]` | |
| A18 | Saved profiles sorted by last-used, swipe to delete | `[ ]` | LoginPage account switcher |
| A19 | Environment badge shown on saved profile (Test/Production) | `[ ]` | |
| A20 | Session validation runs once per app load (not per route) | `[ ]` | router guard `sessionValidated` flag |
| A21 | Domain stores reset on profile switch | `[ ]` | useProfileSwitch |
| A22 | Secret developer mode (tap version 7×, enter 'skeleton') | `[ ]` | LoginPage easter egg |

---

## Navigation & Menu

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| M1 | Menu loads and renders hierarchy | `[ ]` | menuApi + XML parse |
| M2 | Badge counts shown on menu items | `[ ]` | `CompanyMenuItem/AllNumberOfNew` |
| M3 | Menu caches 30 min (no unnecessary re-fetch) | `[ ]` | menuStore TTL + ETag |
| M4 | Favorites displayed at top of menu | `[ ]` | favoritesStore |
| M5 | Favorites sync from server on session start | `[ ]` | |
| M6 | Folder navigation (drill-down + back) | `[ ]` | menuStore folder stack |
| M7 | Offline: serve cached menu | `[ ]` | isOnline check |
| M8 | All menu item types route correctly (PostList, SurveyList, Form, Contacts, ChatList, Canteen, Stream, List, Card, TrustBox, CustomPage, LicensePlate, Television, AboutApp, Settings, Url, Folder) | `[ ]` | routes.ts |
| M9 | External URL menu items open in browser | `[ ]` | type = "Url" |
| M10 | Long-press tile (500 ms) toggles favorite | `[ ]` | favoritesStore |
| M11 | Back button pops folder stack (not app back) | `[ ]` | menuStore |
| M12 | Popup posts queue shown one-at-a-time on menu mount | `[ ]` | postApi.getPopupPosts → dialog |
| M13 | Popup post marked as read on dismiss | `[ ]` | |
| M14 | Header back arrow shown on non-menu pages | `[ ]` | MainLayout |
| M15 | Incremental menu update via `CheckPrivateData` + `lastDate` | `[ ]` | menuStore |

---

## Posts / News

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| P1 | Posts list loads per module | `[ ]` | `GET /client/v1/post` |
| P2 | Post detail view | `[ ]` | |
| P3 | Mark post as read (unread dot clears immediately) | `[ ]` | |
| P4 | Mark all posts as read | `[ ]` | |
| P5 | Approve post (approval chip → confirm → API) | `[ ]` | |
| P6 | Popup posts shown on login | `[ ]` | postApi.getPopupPosts |
| P7 | Unread count badge on menu | `[ ]` | |
| P8 | Offline: cached posts served | `[ ]` | |
| P9 | Skeleton loaders shown while list fetches | `[ ]` | |
| P10 | Empty state shown when no posts | `[ ]` | SEmptyState |
| P11 | HTML content rendered in post detail (`v-html`) | `[ ]` | |
| P12 | Image attachments displayed (max 400px height) | `[ ]` | |
| P13 | Non-image attachments filtered from image display | `[ ]` | |
| P14 | Document attachment URLs constructed with `ID_Login` + `Width` | `[ ]` | userPhotoApi / frameworkApi |

---

## Surveys

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| SV1 | Survey list loads | `[ ]` | `GET /client/v1/survey` |
| SV2 | Answer progress (answered/total) shown on list card | `[ ]` | |
| SV3 | Survey intro page shown (title, question count, description HTML) | `[ ]` | |
| SV4 | Progress bar advances per page | `[ ]` | |
| SV5 | Multi-page navigation (next / back) | `[ ]` | |
| SV6 | Back on intro page is disabled | `[ ]` | |
| SV7 | All question types render: text, textarea, single-select, multi-select | `[ ]` | |
| SV8 | Required question marked with asterisk | `[ ]` | |
| SV9 | Image attachments on questions shown inline | `[ ]` | |
| SV10 | Document attachments on questions shown as links | `[ ]` | |
| SV11 | Answers preserved when navigating back/forward | `[ ]` | |
| SV12 | Answer submission on last page | `[ ]` | |
| SV13 | Survey state set to 'Answered' after submit | `[ ]` | |
| SV14 | Save as draft | `[ ]` | |
| SV15 | Draft restored on re-open | `[ ]` | |
| SV16 | Survey V2 variant works | `[ ]` | wsSurveyApi fallback |

---

## Employee Profile & Settings

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| EP1 | Profile data loads (name, photo, department) | `[ ]` | employeeApi |
| EP2 | Avatar shows photo or initials fallback | `[ ]` | SAvatar |
| EP3 | Photo upload via bottom sheet (file picker) | `[ ]` | userPhotoApi |
| EP4 | Photo delete with confirm dialog | `[ ]` | |
| EP5 | Logout button on profile page | `[ ]` | saves snapshot before clear |
| EP6 | Language settings change syncs to server | `[ ]` | employeeApi + useLocale |
| EP7 | App language switches UI immediately | `[ ]` | i18n |
| EP8 | Dark mode toggle persists | `[ ]` | themeStore |
| EP9 | PIN lock setup + timeout selection | `[ ]` | SettingsPage modal |
| EP10 | Biometric enrollment (checks device availability first) | `[ ]` | tauri-plugin-biometric |
| EP11 | Notification settings shown as admin-managed (read-only) | `[ ]` | |
| EP12 | Favorites list in settings (view + remove items) | `[ ]` | favoritesStore |
| EP13 | Developer error log link visible only to developers | `[ ]` | isDeveloper flag |

---

## App Lock

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| AL1 | Lock screen shown after inactivity timeout | `[ ]` | appLockStore timeout |
| AL2 | Activity recorded on every navigation/interaction | `[ ]` | |
| AL3 | App resume from background triggers lock check | `[ ]` | visibilitychange event |
| AL4 | PIN entry: 4-digit auto-submit | `[ ]` | |
| AL5 | PIN entry: error shown on wrong PIN | `[ ]` | |
| AL6 | PIN entry: logout after 5 failed attempts | `[ ]` | |
| AL7 | Biometric auto-attempt on AppLockPage mount | `[ ]` | |
| AL8 | Biometric failure → fallback to PIN | `[ ]` | |
| AL9 | Per-profile PIN and timeout settings | `[ ]` | appLockStore per-profile storage |

---

## Messages

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| MS1 | Group conversation list loads | `[ ]` | messagesApi |
| MS2 | Private conversation list loads | `[ ]` | |
| MS3 | Send a message | `[ ]` | |
| MS4 | Delete a message | `[ ]` | |
| MS5 | Emoji reactions | `[ ]` | SMessageReactions |
| MS6 | Create group | `[ ]` | messageGroupApi |
| MS7 | Edit group (name, members) | `[ ]` | |
| MS8 | New message check (polling / push) | `[ ]` | messagesApi.checkForNew |
| MS9 | Unread count badge on menu | `[ ]` | |

---

## Contacts

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| C1 | Contact directory loads | `[ ]` | contactsApi |
| C2 | Incremental update (lastUpdate param) | `[ ]` | |
| C3 | Search / filter contacts | `[ ]` | |
| C4 | Offline: cached contacts served | `[ ]` | |

---

## Canteen

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| CA1 | Canteen list loads | `[ ]` | canteenApi |
| CA2 | External login handled | `[ ]` | |
| CA3 | Carte choices display | `[ ]` | |
| CA4 | Order creation | `[ ]` | |
| CA5 | Slot selection | `[ ]` | |
| CA6 | Label translation | `[ ]` | |

---

## Stream (Social Feed)

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| ST1 | Stream posts list loads | `[ ]` | streamPostApi |
| ST2 | Post detail view | `[ ]` | |
| ST3 | Create new post | `[ ]` | |
| ST4 | Create comment | `[ ]` | |

---

## Employee Card

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| EC1 | Card details display | `[ ]` | cardApi |
| EC2 | Promo code entry | `[ ]` | |
| EC3 | Register email (if not registered) | `[ ]` | |

---

## Trust Box

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| TB1 | Anonymous feedback form renders | `[ ]` | TrustBoxPage |
| TB2 | Submission sends to backend | `[ ]` | trustBoxApi |

---

## Television

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| TV1 | TV content displays | `[ ]` | TelevisionPage |
| TV2 | Change detection polling works | `[ ]` | televisionApi |

---

## Data List (Generic Forms)

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| DL1 | Data list renders items | `[ ]` | dataApi V1/V2 |
| DL2 | Item detail view | `[ ]` | |
| DL3 | Create new item | `[ ]` | |
| DL4 | Edit item | `[ ]` | |
| DL5 | Delete item | `[ ]` | |
| DL6 | Label translation | `[ ]` | |

---

## Custom Pages

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| CP1 | Custom HTML page list loads | `[ ]` | customPagesApi |
| CP2 | Custom page detail renders HTML | `[ ]` | |

---

## New Entry (Form Submission)

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| NE1 | Entry form renders per module | `[ ]` | NewEntryPage |
| NE2 | All field types render: Label, Number, Date, Time, Select, MultiSelect, CascadingSelect, Checkbox, MultiLineText, Editor, Photo, Document, Text | `[ ]` | formItem types |
| NE3 | Required fields marked with asterisk, block submit if empty | `[ ]` | |
| NE4 | Cascading select: child options update on parent change | `[ ]` | |
| NE5 | Photo field shows preview after selection | `[ ]` | |
| NE6 | Document field shows filename after selection | `[ ]` | |
| NE7 | Edit mode: existing values pre-populated | `[ ]` | |
| NE8 | Cross-link query params forwarded to API calls | `[ ]` | `crossLinkParams` |
| NE9 | Form submission succeeds + toast shown | `[ ]` | |

---

## License Plate Scanner

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| LP1 | Camera opens via barcode scanner plugin | `[ ]` | tauri-plugin-barcode-scanner |
| LP2 | OCR result sent to backend | `[ ]` | licensePlateApi |
| LP3 | Result displayed to user | `[ ]` | |

---

## Error Reporting

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| ER1 | HTTP errors collected automatically | `[ ]` | errorReportStore + axios interceptor |
| ER2 | Slow requests flagged (configurable threshold) | `[ ]` | |
| ER3 | Error list visible in ErrorReportPage | `[ ]` | |
| ER4 | Auto-flush at 100 items | `[ ]` | |

---

## Shared Infrastructure

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| IN1 | Offline banner shows when network lost | `[ ]` | OfflineBanner + useNetwork |
| IN2 | Offline banner hides when network restores | `[ ]` | |
| IN3 | Toast notifications for errors | `[ ]` | useNotify |
| IN4 | Loading states on all async operations | `[ ]` | useApi |
| IN5 | Empty state component shown on empty lists | `[ ]` | SEmptyState |
| IN6 | Error state component shown on fetch failure | `[ ]` | SErrorState |
| IN7 | Slow request detection (dev setting) | `[ ]` | DevSettingsPage |
| IN8 | Header respects device safe-area (notch / status bar) | `[ ]` | `env(safe-area-inset-top)` |
| IN9 | Company chat (groupApi) accessible via menu | `[ ]` | groupApi + employeeApi |

---

## Dev Tools

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| DV1 | Color palette page renders MD3 tokens | `[ ]` | DevPalettePage |
| DV2 | Component showcase renders all shared components | `[ ]` | DevComponentsPage |
| DV3 | Dev settings page saves preferences to localStorage | `[ ]` | DevSettingsPage |

---

## Build & Platform

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| BP1 | iOS build runs without errors | `[ ]` | `xcodebuild build` |
| BP2 | App installs and launches on iOS Simulator | `[ ]` | `xcrun simctl install` |
| BP3 | Desktop (dev) build runs | `[-]` | N/A — iOS only |
| BP4 | Camera scanner works on iOS | `[ ]` | AVFoundation |
| BP5 | Biometric works on iOS | `[ ]` | LocalAuthentication |

---

## Security

> `[!]` = known issue · `[?]` = needs verification · `[ ]` = todo

| # | Item | Status | Notes |
|---|------|--------|-------|
| SEC1 | `keystore.properties` removed from git / added to `.gitignore` | `[!]` | Dev signing credentials committed — `src-tauri/keystore/keystore.properties` | -- IGNORE
| SEC2 | Release APK does not use dev signing config | `[!]` | `build.gradle.kts` uses "dev" signingConfig for both debug and release |
| SEC3 | CSP enabled in `tauri.conf.json` | `[!]` | Currently `"csp": null` + `dangerousDisableAssetCspModification: true` |
| SEC4 | `v-html` in PostsPage backed by server-side HTML sanitization | `[?]` | `PostsPage.vue:84` — confirm backend escapes user-controlled HTML |
| SEC5 | `v-html` in SurveysPage backed by server-side sanitization | `[?]` | `SurveysPage.vue:86` — survey intro HTML |
| SEC6 | `v-html` in MenuPage (popup posts) backed by sanitization | `[?]` | `MenuPage.vue:257` |
| SEC7 | `v-html` in CustomPageDetailPage backed by sanitization | `[?]` | `CustomPageDetailPage.vue:18,38` |
| SEC8 | `ID_Login` redacted from all request logs | `[ ]` | `axios.ts` `sanitizeParams/sanitizeBody` — verify no bypass paths |
| SEC9 | `ID_Login` not persisted in `auth` store (only in `profiles` store by design) | `[?]` | `auth.ts` `persist: true` — verify idLogin excluded from persist payload |
| SEC10 | `accessCode` stored in profiles store is acceptable risk (by design) | `[?]` | `profile.ts` — intentional for silent re-login; document decision |
| SEC11 | Cleartext traffic disabled on production Android build | `[ ]` | `build.gradle.kts:37` — `usesCleartextTraffic=false` for release |
| SEC12 | Tauri capabilities grant only minimum required permissions | `[ ]` | `capabilities/default.json` — HTTPS only, barcode, biometric |
| SEC13 | No sensitive data in localStorage beyond what is documented | `[ ]` | Audit all `localStorage.setItem` calls |
| SEC14 | App lock mitigates persisted token risk on stolen device | `[ ]` | Verify lock engages before token can be extracted |

---

## Cache

| # | Item | Status | Notes |
|---|------|--------|-------|
| CA1 | Menu TTL (30 min) respected — no unnecessary re-fetches | `[ ]` | `menu.ts` `CACHE_TTL_MS` |
| CA2 | Badge TTL (30 min) refreshes independently of menu | `[ ]` | `lastBadgesFetchedAt` |
| CA3 | `force=true` bypass works (e.g. pull-to-refresh) | `[ ]` | `fetchMenu(force)` |
| CA4 | `CheckPrivateData` incremental update skips full XML download when unchanged | `[ ]` | `menuStore` `IsChange` check |
| CA5 | Posts cached in memory and served offline | `[ ]` | `posts.ts` offline branch |
| CA6 | Contacts incremental update via `lastUpdate` param works | `[ ]` | `contactsApi` |
| CA7 | Surveys store has no TTL — verify stale data is acceptable | `[?]` | `surveys.ts` — no expiry logic |
| CA8 | Employee profile store has no TTL — verify stale data is acceptable | `[?]` | `employee.ts` — fetches on demand only |
| CA9 | customPages store cache strategy is documented / acceptable | `[?]` | No TTL found |
| CA10 | Pinia persist does not grow unboundedly (old profiles pruned) | `[?]` | `profiles.ts` — check max saved profiles |
| CA11 | Favorites localStorage key is pruned when items removed server-side | `[?]` | `favorites.ts` manual localStorage |
| CA12 | No stale menu shown after forced logout + re-login as different user | `[ ]` | Store reset on profile switch |

---

## Tests

| # | Item | Status | Notes |
|---|------|--------|-------|
| T1 | `npm test` passes (all unit tests green) | `[ ]` | Vitest |
| T2 | `npm run test:e2e` login flow passes | `[ ]` | Playwright |
| **API modules** | | | |
| T3 | `employeeApi` unit tests | `[ ]` | not covered |
| T4 | `surveyApi` unit tests | `[ ]` | not covered |
| T5 | `messagesApi` / `messageGroupApi` unit tests | `[ ]` | not covered |
| T6 | `contactsApi` unit tests | `[ ]` | not covered |
| T7 | `canteenApi` unit tests | `[ ]` | not covered |
| T8 | `streamPostApi` unit tests | `[ ]` | not covered |
| T9 | `wsPostApi` / `wsSurveyApi` unit tests | `[ ]` | fallback API modules |
| T10 | `userPhotoApi` unit tests | `[ ]` | not covered |
| T11 | `axios.ts` interceptors unit tests (401 logout, error collect, sanitize) | `[ ]` | not covered |
| **Stores** | | | |
| T12 | `posts` store unit tests | `[ ]` | not covered |
| T13 | `menu` store unit tests | `[ ]` | TTL + offline + badge logic |
| T14 | `employee` store unit tests | `[ ]` | not covered |
| T15 | `contacts` store unit tests | `[ ]` | not covered |
| T16 | `messages` store unit tests | `[ ]` | not covered |
| T17 | `favorites` store unit tests | `[ ]` | not covered |
| T18 | `errorReport` store unit tests | `[ ]` | flush at 100, sanitize |
| T19 | `appLock` store unit tests | `[ ]` | timeout, PIN hash, biometric flag |
| T20 | `auth` store unit tests | `[ ]` | not covered |
| **Composables** | | | |
| T21 | `useLocale` unit tests | `[ ]` | not covered |
| T22 | `useNotify` unit tests | `[ ]` | not covered |
| **E2E** | | | |
| T23 | E2E: full login → menu → open a post → mark read | `[ ]` | |
| T24 | E2E: complete a survey | `[ ]` | |
| T25 | E2E: profile switch between two saved accounts | `[ ]` | |

---

## Code Quality

| # | Item | Status | Notes |
|---|------|--------|-------|
| CQ1 | No bare `console.log` in production code | `[ ]` | Logger gated by `isDev` in `src/utils/logger.ts` — verify no leaks |
| CQ2 | No `any` TypeScript types in `src/api/` or `src/stores/` | `[ ]` | Audit confirmed clean — recheck after new code |
| CQ3 | No inline type definitions in components or pages | `[ ]` | All types must live in `src/api/types/` |
| CQ4 | No raw `.then()` chains — all async code uses `async/await` | `[ ]` | Confirmed clean — recheck after new code |
| CQ5 | No page importing another page (layer violation) | `[ ]` | Confirmed clean |
| CQ6 | Store-to-store imports justified and documented | `[?]` | `employee→auth`, `favorites→employee`, `surveys→auth` — intentional but worth noting |
| CQ7 | `useApi()` composable used for all async calls (no raw try/catch in components) | `[ ]` | Verify pages don't bypass useApi |
| CQ8 | All API response shapes have a corresponding type in `src/api/types/` | `[ ]` | No inline response types in service modules |
| CQ9 | AGENTS.md rules followed in all directories (naming, conventions) | `[ ]` | `camelCase` files, `PascalCase` components, `kebab-case` routes |
| CQ10 | No feature flags or dead code left from abandoned features | `[ ]` | Scan for unreachable routes, unused stores |
| CQ11 | `ID_Login` never hardcoded or logged (rule from CLAUDE.md) | `[ ]` | Covered by SEC8 — cross-reference |
| CQ12 | Error boundary / fallback for `v-html` rendering failures | `[?]` | What happens if backend returns malformed HTML |
