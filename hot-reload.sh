#!/bin/bash
# Hot Reload for Clonka Swift iOS app
# Usage: ./hot-reload.sh [personalNumber] [accessCode]
# Watches for Swift file changes, rebuilds, reinstalls, and relaunches

PN="${1:-1}"
AC="${2:-8cbe80b0-d2be-4733-8045-638f03474842}"
SIM="iPhone 16 Pro"
BUNDLE="cz.skeleton.clonka"
PROJECT_DIR="$(cd "$(dirname "$0")/ClonkaApp" && pwd)"
APP="$PROJECT_DIR/build/Build/Products/Debug-iphonesimulator/ClonkaApp.app"

echo "🔥 Clonka Hot Reload"
echo "   Project: $PROJECT_DIR"
echo "   User: PN=$PN"
echo "   Simulator: $SIM"
echo ""

rebuild_and_install() {
    echo ""
    echo "🔨 Building..."
    cd "$PROJECT_DIR"
    if xcodebuild build -project ClonkaApp.xcodeproj -scheme ClonkaApp \
        -sdk iphonesimulator26.2 -arch arm64 -configuration Debug \
        -derivedDataPath build/ -quiet 2>&1 | grep -q "error:"; then
        echo "❌ Build failed!"
        xcodebuild build -project ClonkaApp.xcodeproj -scheme ClonkaApp \
            -sdk iphonesimulator26.2 -arch arm64 -configuration Debug \
            -derivedDataPath build/ -quiet 2>&1 | grep "error:"
        return 1
    fi
    
    echo "📲 Installing..."
    xcrun simctl terminate "$SIM" "$BUNDLE" 2>/dev/null
    xcrun simctl install "$SIM" "$APP"
    
    echo "🚀 Launching..."
    xcrun simctl launch "$SIM" "$BUNDLE" \
        -personalNumber "$PN" -accessCode "$AC"
    
    echo "✅ Ready! $(date +%H:%M:%S)"
}

# Initial build
rebuild_and_install

# Watch for changes using fswatch if available, otherwise poll
if command -v fswatch &> /dev/null; then
    echo ""
    echo "👁️  Watching for changes (fswatch)... Press Ctrl+C to stop"
    fswatch -o -r --include='\.swift$' --exclude='build/' "$PROJECT_DIR/ClonkaApp/" | while read; do
        rebuild_and_install
    done
else
    echo ""
    echo "👁️  Watching for changes (poll every 3s)... Press Ctrl+C to stop"
    echo "   💡 Install fswatch for instant reload: brew install fswatch"
    LAST_HASH=""
    while true; do
        HASH=$(find "$PROJECT_DIR/ClonkaApp" -name "*.swift" -newer "$APP" 2>/dev/null | head -1)
        if [ -n "$HASH" ] && [ "$HASH" != "$LAST_HASH" ]; then
            LAST_HASH="$HASH"
            echo "📝 Changed: $(basename "$HASH")"
            rebuild_and_install
        fi
        sleep 3
    done
fi
