#!/bin/bash

echo "🚀 Building Mindmap Desktops App..."

# Create build directory
mkdir -p build

# Compile all Swift files
echo "📦 Compiling Swift sources..."

swiftc \
    -o build/MindmapDesktops \
    -sdk $(xcrun --show-sdk-path) \
    -target arm64-apple-macosx10.15 \
    Sources/MindmapDesktops/main.swift \
    Sources/MindmapDesktops/AppDelegate.swift \
    Sources/MindmapDesktops/Controllers/MainWindowController.swift \
    Sources/MindmapDesktops/Views/MindmapView.swift \
    Sources/MindmapDesktops/Models/VirtualDesktop.swift \
    Sources/MindmapDesktops/Models/MindMapNode.swift \
    Sources/MindmapDesktops/Managers/SpaceManager.swift \
    -framework Cocoa \
    -framework Foundation \
    -framework ApplicationServices

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo "🎉 Starting Mindmap Desktops..."
    echo ""
    echo "📝 Note: The app will request Accessibility permissions."
    echo "   Go to System Preferences > Security & Privacy > Accessibility"
    echo "   and allow the app to control your virtual desktops."
    echo ""
    
    # Run the application
    ./build/MindmapDesktops
else
    echo "❌ Build failed. Let's try an alternative approach..."
    echo ""
    echo "🛠️  Alternative: Install Xcode for better compatibility"
    echo "   1. Install Xcode from the App Store (free)"
    echo "   2. Run: sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
    echo "   3. Try building again with: swift build"
    echo ""
    echo "📱 Or create a simple Xcode project:"
    echo "   1. Open Xcode"
    echo "   2. Create new macOS App project"
    echo "   3. Copy all .swift files from Sources/MindmapDesktops/"
    echo "   4. Build and run in Xcode"
fi 