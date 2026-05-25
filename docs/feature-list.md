# Clonka — Feature List

Complete feature inventory of the Clonka mobile app (Swift + SwiftUI, native iOS).

---

## Authentication & Session

| # | Feature | Details |
|---|---------|---------|
| F1 | Login (personal number + access code) | `GET /api/Employee/Login` → `ID_Login` session token |
| F2 | QR code login (camera scan) | Tauri barcode-scanner → jsQR browser fallback → manual entry fallback |
| F3 | QR login from image upload | File picker + jsQR canvas decode |
| F4 | Multi-profile account switching | Save multiple accounts, instant switch for active sessions, auto-relogin for expired profiles |
| F5 | Profile badges (Test / Production / Custom) | Environment badge per saved profile |
| F6 | Session validation (once per app load) | Router guard validates `ID_Login` on first navigation, non-blocking unless 401 |
| F7 | Auto-logout on 401 | Axios interceptor clears session + redirects to `/login` |
| F8 | Maintenance mode detection | `GET /api/Company/CheckState` on first navigation, blocks UI if active |
| F9 | Push notification registration | FCM token + device info sent to backend via Tauri remote-push plugin |
| F10 | Developer mode (easter egg) | Tap version 7×, enter "skeleton" → unlocks `/dev/*` routes |

---

## Navigation & Menu

| # | Feature | Details |
|---|---------|---------|
| F11 | Dynamic menu grid from backend | XML private data parsed into colored tiles |
| F12 | Badge counts on menu items | 30-second polling interval |
| F13 | Folder hierarchy (drill-down + back) | Breadcrumb folder stack |
| F14 | Favorites (star/unstar via long-press) | Local storage + server sync via employee settings |
| F15 | Menu search | Filters non-folder items by name |
| F16 | Pull-to-refresh | Forces cache bypass on menu and badges |
| F17 | Popup posts on menu load | Full-screen modal queue, marked as read on dismiss |
| F18 | Menu caching (30 min TTL) | Incremental update via `CheckPrivateData` + `lastDate` |
| F19 | Offline menu (cached data) | Serves last fetched menu when network unavailable |

---

## Posts & Announcements

| # | Feature | Details |
|---|---------|---------|
| F20 | Posts list per module | `GET /client/v1/post` with read/unread indicators |
| F21 | Post detail view | HTML content + image attachments |
| F22 | Mark post as read | Individual + mark-all-as-read |
| F23 | Post approval | Checkbox + approve button for `approveWithCheckbox` type |
| F24 | Popup posts (high-priority) | Shown as blocking dialogs on menu mount |
| F25 | Unread count badge | Badge counter on menu tile |

---

## Surveys

| # | Feature | Details |
|---|---------|---------|
| F26 | Survey list with status | Answered / Not Answered badges, progress bar, question count |
| F27 | Multi-page questionnaire | Intro page → question pages → submit page with progress bar |
| F28 | Question types: text, textarea, single-select, multi-select | Required marking, image/document attachments on questions |
| F29 | Save draft | Answers preserved mid-survey, restored on reopen |
| F30 | Submit survey | `submitAnswer` + `setState` → refreshes list |
| F31 | Dual API support (Client.Api V1 + Webservice.Core) | Fallback mapping between API versions |

---

## Messages & Chat

| # | Feature | Details |
|---|---------|---------|
| F32 | Group conversations | List groups, view members, send messages |
| F33 | Private direct messages | 1-on-1 threads per employee |
| F34 | Send / delete messages | Context menu to delete own messages |
| F35 | Emoji reactions | Reaction picker on messages |
| F36 | New message polling | `hasNewGroupMessages` flag, unread badges |
| F37 | Group management (create/edit) | Name + member management via `messageGroupApi` |

---

## Employee Profile

| # | Feature | Details |
|---|---------|---------|
| F38 | Profile view (name, department, email, phone) | `employeeApi.getEmployee()` |
| F39 | Profile photo upload / remove | Bottom sheet → file picker, `userPhotoApi` |
| F40 | Avatar with initials fallback | `SAvatar` component |
| F41 | Employee settings sync (ETag-cached) | Modules, favorites, preferences synced on session start |

---

## Settings

| # | Feature | Details |
|---|---------|---------|
| F42 | Language selection | Languages from login response, immediate UI switch via i18n |
| F43 | Dark mode toggle | CSS custom properties, persisted in `themeStore` |
| F44 | App lock (4-digit PIN) | SHA256-hashed, configurable timeout (5–30 min), per-profile storage |
| F45 | Biometric unlock (fingerprint) | Tauri biometric plugin, auto-attempts on lock screen, fallback to PIN |
| F46 | Lock on inactivity / app background | Activity tracking + `visibilitychange` event |
| F47 | Notification settings | UI banner only — "managed by admin", no backend toggle |

---

## Canteen

| # | Feature | Details |
|---|---------|---------|
| F48 | Canteen list with multi-location selector | `canteenApi` |
| F49 | Date navigation for daily menus | Date picker per canteen |
| F50 | Time slot selection | Available slots display + selection |
| F51 | Canteen login (password) | External auth for ordering |

---

## Contacts

| # | Feature | Details |
|---|---------|---------|
| F52 | Contact directory | Search by name/email/phone |
| F53 | Contact detail modal | Click-to-call/email support |
| F54 | Incremental update | `lastUpdate` param skips full re-fetch |
| F55 | Offline contacts | Serves cached contacts when offline |

---

## Stream (Social Feed)

| # | Feature | Details |
|---|---------|---------|
| F56 | Stream posts per module | Avatar, message, date, comment count |
| F57 | Post detail view | Full content + photo attachments |
| F58 | Pull-to-refresh | Refresh stream feed |

---

## Loyalty Card

| # | Feature | Details |
|---|---------|---------|
| F59 | Card details display | Card number, email, primary color header |
| F60 | QR code display | Monospace card number rendering |
| F61 | Unregistered state handling | Registration prompt when no card |

---

## Trust Box (Suggestion Box)

| # | Feature | Details |
|---|---------|---------|
| F62 | Anonymous feedback form | Min 10 characters, optional email |
| F63 | Submit to backend | `trustBoxApi` with loading state |

---

## Custom Pages

| # | Feature | Details |
|---|---------|---------|
| F64 | Custom HTML page list | Module-based routing |
| F65 | Single page direct render | HTML content rendered via `v-html` |

---

## Data Lists

| # | Feature | Details |
|---|---------|---------|
| F66 | Multiple layout types (BigPicture grid, Plain list) | `dataApi` V1/V2 |
| F67 | Search and filter | Real-time case-insensitive matching |
| F68 | Item detail modal | Full content view |

---

## Dynamic Forms (New Entry)

| # | Feature | Details |
|---|---------|---------|
| F69 | Dynamic form rendering per module | Field types: Label, Number, Text, Date, Time, TimePicker, Select, MultiSelect, TextArea, Checkbox |
| F70 | Required field validation | Asterisk marking, blocks submit if empty |
| F71 | Cascading select fields | Child options update on parent change |
| F72 | Photo / document attachment fields | Preview after selection |
| F73 | Edit mode with pre-populated values | Cross-link query params forwarded |

---

## License Plate Scanner

| # | Feature | Details |
|---|---------|---------|
| F74 | Image capture / upload for OCR | Camera or file picker |
| F75 | Plate hint input | Optional hint for accuracy |
| F76 | OCR result display | Detected plate number from backend |

---

## Television / Display

| # | Feature | Details |
|---|---------|---------|
| F77 | Dynamic display content | Module-based screen rendering |
| F78 | Change detection polling | `televisionApi` periodic check |

---

## Infrastructure & UX

| # | Feature | Details |
|---|---------|---------|
| F79 | Offline detection + banner | `useNetwork` composable + `OfflineBanner` component |
| F80 | Toast notifications | `useNotify` composable → Quasar Notify (success/error/info) |
| F81 | Loading states + skeleton loaders | Per-page skeletons during async fetches |
| F82 | Empty state placeholders | `SEmptyState` component on empty lists |
| F83 | Error state component | `SErrorState` on fetch failures |
| F84 | Safe-area / notch support | `env(safe-area-inset-top)` in header |
| F85 | Multi-language UI (i18n) | Locale switching updates all text + date formatting |
| F86 | JWT interceptor (ID_Login injection) | All API calls authenticated via Axios interceptor |
| F87 | ID_Login redaction in logs | `sanitizeParams` / `sanitizeBody` in `axios.ts` |
| F88 | Error reporting store | Auto-collects HTTP errors, slow requests, auto-flush at 100 |

---

## Shared UI Components

| Component | Purpose |
|-----------|---------|
| `SBtn` | Button with ghost/icon variants, loading state |
| `SCard` | Glass-morphism card wrapper |
| `SAvatar` | Colored avatar with initials fallback |
| `SEmptyState` | Empty list placeholder |
| `SErrorState` | Error display with retry |
| `SLoading` | Loading spinner |
| `SSearchInput` | Search field with clear button |
| `SDetailDialog` | Modal dialog for detail views |
| `SFormDialog` | Form in modal dialog |
| `SDatePicker` / `STimePicker` / `SDateTimePicker` | Date and time inputs |
| `SSelect` / `SMultiSelect` | Select dropdowns |
| `SEditDropDown` | Editable dropdown |
| `SMessageReactions` | Emoji reaction display |

---

## Developer Tools

| # | Feature | Details |
|---|---------|---------|
| F89 | Color palette page (MD3 tokens) | `DevPalettePage` |
| F90 | Component showcase | `DevComponentsPage` — all shared components |
| F91 | Dev settings page | `DevSettingsPage` — routing works, minimal content |
| F92 | Error report page | Expandable error list, copy log, clear all, badge counter |

---

## Platform & Native

| # | Feature | Details |
|---|---------|---------|
| F93 | iOS build (Xcode) | `xcodebuild build` |
| F94 | Android build | N/A — iOS only |
| F95 | Desktop dev mode | N/A — iOS only |
| F96 | Camera scanner (AVFoundation) | Camera-based QR scanning |
| F97 | Biometric (LocalAuthentication) | Face ID / Touch ID authentication |
| F98 | Push notifications (APNs + FCM) | APNs + Firebase Cloud Messaging |

---

## Summary

| Category | Features |
|----------|----------|
| Auth & Session | 10 |
| Navigation & Menu | 9 |
| Posts | 6 |
| Surveys | 6 |
| Messages | 6 |
| Profile | 4 |
| Settings | 6 |
| Canteen | 4 |
| Contacts | 4 |
| Stream | 3 |
| Loyalty Card | 3 |
| Trust Box | 2 |
| Custom Pages | 2 |
| Data Lists | 3 |
| Dynamic Forms | 5 |
| License Plate | 3 |
| Television | 2 |
| Infrastructure | 10 |
| Dev Tools | 4 |
| Platform | 6 |
| **Total** | **98** |
