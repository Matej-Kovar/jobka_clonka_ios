# Start dev environment

1. Boot the iOS Simulator:
```bash
xcrun simctl boot "iPhone 16 Pro" 2>/dev/null || true
open -a Simulator
```

2. Build and install:
```bash
cd /Users/danielvazac/Repos/Clonka/clonka-swift/ClonkaApp
xcodebuild build -project ClonkaApp.xcodeproj -scheme ClonkaApp -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -derivedDataPath build/
xcrun simctl install booted build/Build/Products/Debug-iphonesimulator/ClonkaApp.app
xcrun simctl launch booted cz.skeleton.clonka
```

3. Stream logs:
```bash
log stream --predicate 'subsystem == "cz.skeleton.clonka"' --level debug
```
