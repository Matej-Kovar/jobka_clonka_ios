# Clonka Swift

## Purpose
Enterprise employee mobile app integrating with Skeleton.Jobka backend — auth, news, chat, HR, canteen, forms, and more. Native iOS with SwiftUI.

## Architecture
Clean Architecture + MVVM inside `ClonkaApp/ClonkaApp/`:
- **App/**: Entry point, `AppState`, `SessionManager`, `RootView`
- **UI/**: 18 module folders — SwiftUI Views + `@MainActor` ViewModels
- **Data/**: `API/Services/` (17 services), `API/Model/` (DTOs), `API/Interceptors/APIClient.swift`
- **Util/**: `AppResult<T>`, `AppLogger`, `ConfigManager`, `ErrorReportStore`

## Tech Stack
- Swift 6.2, iOS 17+ deployment, Xcode 26.2
- SwiftUI + NavigationStack (typed path routing)
- URLSession via `APIClient` actor (networking)
- Codable (JSON serialization)
- Swift Concurrency (async/await, @MainActor)
- OSLog via `AppLogger` (structured logging with categories)
- UserDefaults (local persistence)

## Conventions
- PascalCase types/files, camelCase functions/vars, `S` prefix for design components
- `FeatureViewModel`, `FeatureAPIService` (static methods)
- `AppResult<T>` for all API calls
- Swift Concurrency + @Published for async, `Codable` DTOs

## Rules
- All API calls through `APIClient.shared` (`wsGet`, `clientGet`, `wsPost`, etc.)
- `APIClient` auto-injects `ID_Login` as query param on every request
- ViewModels are `@MainActor final class: ObservableObject` with `@Published` properties
- Redact sensitive fields in logs via `AppLogger.redact()`
- Single window — all navigation through NavigationStack in `MainTabView`
- New Swift files MUST be added to `project.pbxproj` (Xcode project file)

---

## Build & Test Commands

### Quick Build (compile check)
```bash
cd ClonkaApp
xcodebuild build -project ClonkaApp.xcodeproj -scheme ClonkaApp \
  -sdk iphonesimulator26.2 -arch arm64 -configuration Debug \
  -derivedDataPath build/ -quiet
```

### Run Tests (39 tests: 16 integration + 23 unit)
```bash
cd ClonkaApp
xcodebuild test -project ClonkaApp.xcodeproj -scheme ClonkaApp \
  -configuration Debug -derivedDataPath build/ \
  -destination "platform=iOS Simulator,name=iPhone 16 Pro" -quiet
```

### Build Errors Only
```bash
xcodebuild build ... -quiet 2>&1 | grep "error:"
```

---

## Simulator Commands

### Boot & Open
```bash
xcrun simctl boot "iPhone 16 Pro"
open -a Simulator
```

### Install & Launch (with auto-login)
```bash
xcrun simctl install "iPhone 16 Pro" build/Build/Products/Debug-iphonesimulator/ClonkaApp.app
xcrun simctl launch "iPhone 16 Pro" cz.skeleton.clonka \
  -personalNumber 1 -accessCode 8cbe80b0-d2be-4733-8045-638f03474842
```

### Auto-Navigate to Module (testing specific screens)
```bash
xcrun simctl launch "iPhone 16 Pro" cz.skeleton.clonka \
  -personalNumber 1 -accessCode 8cbe80b0-d2be-4733-8045-638f03474842 \
  -navigateTo SurveyList -moduleId 29780
```

### Screenshot
```bash
xcrun simctl io "iPhone 16 Pro" screenshot /tmp/screenshot.png
```

### Terminate App
```bash
xcrun simctl terminate "iPhone 16 Pro" cz.skeleton.clonka
```

### Uninstall (clean state)
```bash
xcrun simctl uninstall "iPhone 16 Pro" cz.skeleton.clonka
```

---

## Hot Reload (Development)
```bash
./hot-reload.sh [personalNumber] [accessCode]
# Default: PN=1, QR=8cbe80b0...
# Watches .swift files, rebuilds, reinstalls, relaunches on change
# Install fswatch for instant reload: brew install fswatch
```

---

## Test Users
| User | PersonalNumber | QR/AccessCode |
|------|---------------|---------------|
| Tester (TT, #00bcd4) | `1` | `8cbe80b0-d2be-4733-8045-638f03474842` |
| User 2 | `2` | `f28293b1-f6be-462a-8cf0-a9260075946c` |

## Module IDs (Test Server)
| Module | ID | Route Name | Notes |
|--------|----|------------|-------|
| About App | 29778 | `AboutApp` | |
| Settings | 29779 | `Settings` | |
| Surveys | 29780 | `SurveyList` | 2 items |
| Form | 29781 | `Form` | 3 fields (Text, Výběr, Čas) |
| Chat | 29782 | `ChatList` | 1 conversation |
| Canteen | 29783 | `Canteen` | ⚠️ Server 500 (backend bug) |
| Card | 29784 | `Card` | ⚠️ Server SQL error |
| Contacts | 29785 | `Contacts` | Empty on test server |
| Stream | 29786 | `Stream` | 1 article, 3 comments |
| License Plates | 29787 | `LicensePlates` | |
| Data List | 29788 | `List` | 1 item |
| Posts | 29789 | `PostList` | Multiple test posts |
| Folder | 29790 | `Folder` | Contains sub-items |
| Television | 29791 | `Television` | |
| Custom Page | 29793 | `CustomPage` | |
| Form (2nd) | 29850 | `Form` | |
| List (2nd) | 29851 | `List` | |

## API Endpoints (Test Environment)
- **Webservice Core**: `https://jobka-test-webservice-core.azurewebsites.net`
- **Client API**: `https://jobka-test-client-api.azurewebsites.net`
- **Azure Files**: `https://jobkatest.file.core.windows.net`

### Quick API Test (curl)
```bash
# Login → get ID_Login
curl -s "https://jobka-test-webservice-core.azurewebsites.net/api/Employee/Login?PersonalNumber=1&Code=8cbe80b0-d2be-4733-8045-638f03474842&Browser=curl&Lang=en"

# Test Client API (use fresh ID_Login from above)
curl -s "https://jobka-test-client-api.azurewebsites.net/client/v1/survey?ID_Login=GUID&ModuleId=29780"

# Badge counts (discover module IDs)
curl -s "https://jobka-test-webservice-core.azurewebsites.net/api/CompanyMenuItem/AllNumberOfNew?ID_Login=GUID"
```

## API Quirks (critical for debugging)
- **WS response `IsSucccess`**: has THREE s's (server typo). Some endpoints use two s's (`IsSuccess`). Decoder handles both.
- **Menu 404**: `/api/CompanyMenuItem/AllNavigation` returns 404. Menu loaded via `CheckPrivateData` → Azure blob XML → parse.
- **Chat**: DM history needs `ID_CompanyMenuItem` param. Fields: `Employee` (not DisplayName), `EmployeeInicial` (typo).
- **Form**: Endpoint is `/api/v2/FormItem/AllForm` (NOT `/api/FormItem/AllFormV2`).
- **DataList**: Endpoint is `/api/v2/Data/AllCompanyMenuItem`. Response wraps items: `{Items: [...]}`.
- **NavigationLink**: MUST use `NavigationLink(value:)` inside `NavigationStack(path:)`. `NavigationLink(destination:)` breaks.

## Developer Tools
- **Enable dev mode**: 7-tap version label on login screen → enter "skeleton" → opens settings
- **Dev Tools**: Settings → Developer Tools (when dev mode active) — shows error log, slow requests, environment info
- **ErrorReportStore**: Collects API errors and slow requests (>3s threshold, configurable) — max 50 entries
- **Logging categories**: `.auth`, `.api`, `.navigation`, `.menu`, `.lifecycle` — use `log stream` to read

## Read Logs
```bash
# All app logs
log stream --predicate 'subsystem == "cz.skeleton.clonka"' --level debug
# API calls only
log stream --predicate 'subsystem == "cz.skeleton.clonka" AND category == "API"' --level debug
# Recent logs (last 5 min)
log show --predicate 'subsystem == "cz.skeleton.clonka"' --last 5m --style compact
```

## Known Server-Side Issues (not our bugs)
- Card (29784): SQL error in backend stored procedure
- Canteen (29783): Server 500 error
- TrustBox, CustomPages, Television: 404 on some client API endpoints (WS endpoints may work)
- Contacts: returns empty data on test server (no employees configured)

## Git Workflow
- **One feature = one commit**: each distinct feature committed separately
- **Bug fixes may be grouped**: related fixes can share a commit
- **Commit before moving on**: always commit completed work before next task

## Agent Parallelism
- **Spawn subagents aggressively**: any task touching independent subsystems must be parallelized
- **Main agent = coordinator**: orchestrates, reviews, and merges
- **Independent edits in parallel**: if two files have no shared dependency, spawn two subagents

## Reference Projects
- **Legacy MAUI app**: `legacy/JobkaMobile/` — check for API patterns, field names, auth flow
- **Tauri web app**: `/Users/danielvazac/Repos/Clonka/clonka-tauri/` — modern reference, has DevSettingsPage, error reporting, fallback logic
- **Kotlin Android**: `/Users/danielvazac/Repos/Clonka/clonka-kotlin/` — same architecture in Kotlin

---

This project uses per-directory `AGENTS.md` files for coding rules.
When editing files in any directory, walk up the tree and apply ONLY
the `AGENTS.md` files found from the file's location to the project
root. Do NOT read `AGENTS.md` files from unrelated branches of the tree.

All `AGENTS.md` locations:
- `/AGENTS.md`
