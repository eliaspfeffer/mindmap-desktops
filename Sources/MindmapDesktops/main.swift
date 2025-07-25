import Cocoa
import Foundation

// Main entry point for the Mindmap Desktops application
@main
class AppMain {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        
        // Request necessary permissions
        requestAccessibilityPermissions()
        
        app.run()
    }
    
    static func requestAccessibilityPermissions() {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as CFDictionary
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        
        if !accessEnabled {
            print("Accessibility permissions required for desktop switching functionality")
        }
    }
} 