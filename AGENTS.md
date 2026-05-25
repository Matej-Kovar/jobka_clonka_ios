# Clonka Swift

## Purpose
Enterprise employee mobile app (portal) integrating with Skeleton.Jobka backend — auth, news, chat, HR, canteen, forms, and more. Native iOS implementation using SwiftUI.

## Architecture
Clean Architecture + MVVM with four layers inside `ClonkaApp/ClonkaApp/`:
- **App/**: Entry point (`ClonkaApp.swift`), `AppState`, `SessionManager`, `RootView`
- **UI/**: SwiftUI Views + `@MainActor` ViewModels per module (Auth, Menu, Surveys, Messages, Posts, Stream, Forms, DataList, Contacts, Card, Canteen, Settings, TrustBox, CustomPages, Television, LicensePlate, Profile, Dev)
- **Data/**: API services (`Data/API/Services/`), models (`Data/API/Model/`), interceptors (`Data/API/Interceptors/APIClient.swift`)
- **Domain/**: (thin) Repository protocols and business model structs
- **Util/**: `AppResult<T>` enum, `AppLogger` (OSLog), `ConfigManager`, `ErrorReportStore`

Data flow: `View → ViewModel (@Published StateFlow) → APIService (async) → APIClient (URLSession) → AppResult<T> → ViewModel updates → View redraws`

## Key Files
| File | Role |
|------|------|
| `UI/Menu/MainTabView.swift` | Central navigation hub — NavigationStack, all `.navigationDestination` registrations, auto-navigate, deep links |
| `Data/API/Interceptors/APIClient.swift` | Core networking actor — all HTTP calls, ID_Login injection, WS/ClientApi response decoders, error/slow-request reporting |
| `Data/API/Model/OtherModels.swift` | Shared models: Stream, Card, TrustBox, DataList, Form, Television, etc. |
| `App/SessionManager.swift` | Auth state, user profile, saved profiles (UserDefaults) |
| `Util/ConfigManager.swift` | Loads `publicConfig.json`, provides WS/ClientApi URLs per environment |
| `Util/ErrorReportStore.swift` | Developer debug: collects API errors + slow requests (max 50) |
| `UI/Settings/DevToolsView.swift` | Developer tools UI: error log, environment info, export |
| `UI/Menu/MenuTileView.swift` | Menu grid tile component (1:1 square aspect ratio) |

## Conventions
- PascalCase types/files, camelCase functions/vars, UPPER_SNAKE constants
- Design-system components use `S` prefix: `SBtn`, `SAvatar`, `SLoading`, `SErrorState`, `SEmptyState`
- ViewModels: `FeatureViewModel` (`@MainActor final class: ObservableObject`)
- API services: `FeatureAPIService` (static methods returning `AppResult<T>`)
- DTOs: `Codable` structs in `Data/API/Model/`
- Error handling: `AppResult<T>` enum (`.success(T)` / `.failure(AppError)`)
- Async: Swift Concurrency (async/await, Task) — no Combine
- Logging: `AppLogger` categories: `.auth`, `.api`, `.navigation`, `.menu`, `.lifecycle`

## Rules
- All API calls go through `APIClient.shared` methods (`wsGet`, `clientGet`, `wsPost`, etc.)
- `APIClient` automatically injects `ID_Login` as query parameter on every request
- Never expose mutable state from ViewModels — use `@Published` with private setter or private `_state`
- Never hardcode API base URLs — use `ConfigManager.shared.webserviceURL` / `.clientApiURL`
- Sensitive fields (`ID_Login`, `password`, `token`) must be redacted in logs via `AppLogger.redact()`
- Single window — all navigation through NavigationStack in MainTabView
- When adding new Swift files, they MUST be added to `ClonkaApp.xcodeproj/project.pbxproj`

## API Quirks (IMPORTANT)
- **WS response field**: `IsSucccess` has THREE s's (server typo), but some endpoints use `IsSuccess` (two s's). Our decoder handles both via CodingKeys.
- **Client API auth**: Passes `ID_Login` as query parameter (not header). Returns HTTP 401 if invalid.
- **Client API base path**: URLs are like `/client/v1/survey` or `/client/v2/survey` — note the `/client/` prefix is part of the path, NOT the base URL.
- **Menu loading**: `GET /api/CompanyMenuItem/AllNavigation` returns 404 on test server. Menu is loaded via: `CheckPrivateData` → SAS-signed Azure blob URL → download XML → parse with `XMLConfigurationParser`.
- **Chat messages**: DM history requires `ID_CompanyMenuItem` parameter — returns empty without it. Field names: `Employee` (not DisplayName), `EmployeeInicial` (not Initials — note typo).
- **Form API**: `GET /api/v2/FormItem/AllForm` (not `/api/FormItem/AllFormV2`). Submit: `POST /api/v2/Data/NewDataItems`.
- **DataList API**: `GET /api/v2/Data/AllCompanyMenuItem` (not V2 suffix). Response wraps items in `{Items: [...], ID_NewFormCompanyMenuItem, EmptyDataText}`.
- **Badge counts**: `GET /api/CompanyMenuItem/AllNumberOfNew` — use this to discover correct module IDs.

## Navigation
- `MainTabView` uses `NavigationStack(path:)` with typed `NavigationPath`
- **MUST use** `NavigationLink(value:)` + `.navigationDestination(for:)` — do NOT use `NavigationLink(destination:)` inside path-based NavigationStack (it breaks)
- Destination types: `ModuleDestination`, `SurveyDetailDestination`, `PostDetailDestination`, `ChatDestination`, `StreamDetailDestination`
- Deep links: `clonka://navigate/SurveyList/29780`
- Auto-navigate via launch args: `-navigateTo SurveyList -moduleId 29780`

## Git Workflow
- One feature = one commit
- Bug fixes may be grouped
- Commit before moving on
