import Cocoa
import Foundation
import ApplicationServices

// Manager class for handling macOS Spaces/Virtual Desktops
class SpaceManager: ObservableObject {
    static let shared = SpaceManager()
    
    @Published var virtualDesktops: [VirtualDesktop] = []
    @Published var currentDesktopID: CGWindowID?
    
    private let notificationCenter = NSWorkspace.shared.notificationCenter
    private var refreshTimer: Timer?
    
    private init() {
        setupNotifications()
        
        // Set up refresh timer after initialization
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task {
                await self?.refreshDesktops()
            }
        }
        
        // Initial load
        Task {
            await refreshDesktops()
        }
    }
    
    deinit {
        refreshTimer?.invalidate()
        notificationCenter.removeObserver(self)
    }
    
    // MARK: - Public Methods
    
    /// Refresh the list of virtual desktops
    func refreshDesktops() async {
        let desktops = await discoverVirtualDesktops()
        
        await MainActor.run {
            // Update existing desktops or create new ones
            var newDesktops: [VirtualDesktop] = []
            
            for desktopInfo in desktops {
                if let existing = virtualDesktops.first(where: { $0.spaceID == desktopInfo.spaceID }) {
                    existing.updateInfo(windowCount: desktopInfo.windowCount, applications: desktopInfo.applications)
                    newDesktops.append(existing)
                } else {
                    let newDesktop = VirtualDesktop(spaceID: desktopInfo.spaceID, name: desktopInfo.name)
                    newDesktop.updateInfo(windowCount: desktopInfo.windowCount, applications: desktopInfo.applications)
                    newDesktops.append(newDesktop)
                }
            }
            
            self.virtualDesktops = newDesktops
            
            // Update current desktop
            self.currentDesktopID = getCurrentDesktopID()
            self.updateActiveDesktop()
        }
        
        // Update preview images for all desktops
        await updateAllPreviews()
    }
    
    /// Switch to a specific virtual desktop
    func switchToSpace(_ spaceID: CGWindowID) {
        // Use AppleScript for reliable space switching
        let script = """
        tell application "System Events"
            tell application process "Dock"
                try
                    set spacesGroup to group 1 of group 1 of group 1
                    set spacesList to spacesGroup's groups
                    
                    -- Try to find and click the space (this is a simplified approach)
                    -- In a real implementation, you'd need more sophisticated space detection
                    click item \(spaceID) of spacesGroup
                end try
            end tell
        end tell
        """
        
        executeAppleScript(script)
    }
    
    /// Force update all desktop previews (use sparingly due to space switching)
    func forceUpdateAllPreviews() async {
        await withTaskGroup(of: Void.self) { group in
            for desktop in virtualDesktops {
                group.addTask {
                    await desktop.updatePreview()
                }
            }
        }
    }
    
    /// Create a new virtual desktop
    func createNewDesktop(name: String? = nil) -> Bool {
        let script = """
        tell application "System Events"
            tell application process "Dock"
                try
                    -- Open Mission Control
                    key code 126 using {control down}
                    delay 0.5
                    
                    -- Create new space by moving cursor to top right and clicking +
                    set screenSize to size of first desktop
                    set xPos to (item 1 of screenSize) - 50
                    set {mouseX, mouseY} to position of mouse
                    set the position of mouse to {xPos, 50}
                    delay 0.2
                    click mouse
                    delay 0.5
                    
                    -- Exit Mission Control
                    key code 53 -- Escape key
                    return true
                end try
            end tell
        end tell
        """
        
        return executeAppleScript(script)
    }
    
    /// Capture desktop preview for a specific space
    func captureDesktopPreview(for spaceID: CGWindowID) async -> NSImage? {
        // If this is the current active desktop, capture it directly
        if spaceID == currentDesktopID {
            return await captureCurrentDesktop()
        }
        
        // For non-active desktops, we need to temporarily switch to capture them
        // This is complex and may cause UI disruption, so we'll use a different approach
        return await captureDesktopForSpace(spaceID)
    }
    
    private func captureCurrentDesktop() async -> NSImage? {
        let cgImage = CGWindowListCreateImage(
            CGRect.null,
            .optionOnScreenOnly,
            kCGNullWindowID,
            [.bestResolution, .boundsIgnoreFraming]
        )
        
        guard let cgImage = cgImage else { return nil }
        
        let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        return resizeImage(nsImage, to: NSSize(width: 200, height: 150))
    }
    
    private func captureDesktopForSpace(_ spaceID: CGWindowID) async -> NSImage? {
        // Store current space
        let originalSpace = currentDesktopID
        
        // Method 1: Try to get windows specific to this space
        if let spaceImage = await captureWindowsForSpace(spaceID) {
            return spaceImage
        }
        
        // Method 2: If we can't get space-specific windows, temporarily switch
        // Note: This approach minimizes disruption by quickly switching and back
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: nil)
                    return
                }
                
                // Switch to target space
                self.switchToSpace(spaceID)
                
                // Wait briefly for the switch to complete
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    // Capture the screen
                    let cgImage = CGWindowListCreateImage(
                        CGRect.null,
                        .optionOnScreenOnly,
                        kCGNullWindowID,
                        [.bestResolution, .boundsIgnoreFraming]
                    )
                    
                    var capturedImage: NSImage? = nil
                    if let cgImage = cgImage {
                        let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
                        capturedImage = self.resizeImage(nsImage, to: NSSize(width: 200, height: 150))
                    }
                    
                    // Switch back to original space if different
                    if let originalSpace = originalSpace, originalSpace != spaceID {
                        self.switchToSpace(originalSpace)
                    }
                    
                    continuation.resume(returning: capturedImage)
                }
            }
        }
    }
    
    private func captureWindowsForSpace(_ spaceID: CGWindowID) async -> NSImage? {
        // Get windows that belong to this specific space
        let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]]
        
        guard let windows = windowList else { return nil }
        
        // Filter windows by space (this is simplified - real implementation would need space-window mapping)
        let spaceWindows = windows.filter { window in
            // In a real implementation, you would check if window belongs to specific space
            // For now, we'll use a heuristic based on space ID
            return true // Simplified for demo
        }
        
        if spaceWindows.isEmpty {
            // No windows in this space, create a simple desktop background representation
            return createEmptyDesktopPreview(for: spaceID)
        }
        
        // Capture windows for this space
        // This is a simplified approach - real implementation would need more sophisticated space detection
        let cgImage = CGWindowListCreateImage(
            CGRect.null,
            .optionOnScreenOnly,
            kCGNullWindowID,
            [.bestResolution, .boundsIgnoreFraming]
        )
        
        guard let cgImage = cgImage else { return nil }
        
        let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        return resizeImage(nsImage, to: NSSize(width: 200, height: 150))
    }
    
    private func createEmptyDesktopPreview(for spaceID: CGWindowID) -> NSImage {
        let size = NSSize(width: 200, height: 150)
        let image = NSImage(size: size)
        
        image.lockFocus()
        
        // Create distinctive backgrounds for different desktops
        let desktopStyles = [
            (color: NSColor.systemBlue, pattern: "main", name: "Main Desktop"),
            (color: NSColor.systemPurple, pattern: "code", name: "Development"),
            (color: NSColor.systemGreen, pattern: "chat", name: "Communication"),
            (color: NSColor.systemOrange, pattern: "design", name: "Design")
        ]
        
        let styleIndex = (Int(spaceID) - 1) % desktopStyles.count
        let style = desktopStyles[styleIndex]
        
        // Draw gradient background
        let gradient = NSGradient(starting: style.color.withAlphaComponent(0.4), 
                                 ending: style.color.withAlphaComponent(0.1))
        gradient?.draw(in: NSRect(origin: .zero, size: size), angle: 45)
        
        // Draw pattern based on desktop type
        style.color.withAlphaComponent(0.3).setFill()
        
        switch style.pattern {
        case "main":
            // Draw folder-like icons for main desktop
            for i in 0..<3 {
                let iconRect = NSRect(x: 20 + (i * 60), y: 80, width: 40, height: 30)
                iconRect.fill()
            }
        case "code":
            // Draw terminal-like rectangles for development
            for i in 0..<2 {
                let termRect = NSRect(x: 20, y: 70 + (i * 40), width: 160, height: 25)
                termRect.fill()
            }
        case "chat":
            // Draw message bubbles for communication
            let bubble1 = NSRect(x: 20, y: 90, width: 80, height: 20)
            let bubble2 = NSRect(x: 100, y: 70, width: 80, height: 20)
            bubble1.fill()
            bubble2.fill()
        case "design":
            // Draw design tools icons
            let circle = NSBezierPath(ovalIn: NSRect(x: 50, y: 80, width: 30, height: 30))
            circle.fill()
            let rect = NSRect(x: 120, y: 80, width: 30, height: 30)
            rect.fill()
        default:
            break
        }
        
        // Draw desktop name
        let text = style.name
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11, weight: .medium),
            .foregroundColor: NSColor.labelColor
        ]
        
        let textSize = text.size(withAttributes: attributes)
        let textRect = NSRect(
            x: (size.width - textSize.width) / 2,
            y: 20,
            width: textSize.width,
            height: textSize.height
        )
        
        text.draw(in: textRect, withAttributes: attributes)
        
        // Draw space ID in corner
        let idText = "\(spaceID)"
        let idAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 10, weight: .regular),
            .foregroundColor: NSColor.tertiaryLabelColor
        ]
        
        idText.draw(in: NSRect(x: size.width - 20, y: size.height - 20, width: 15, height: 15), 
                   withAttributes: idAttributes)
        
        image.unlockFocus()
        return image
    }
    
    // MARK: - Private Methods
    
    private func setupNotifications() {
        // Listen for workspace changes
        notificationCenter.addObserver(
            self,
            selector: #selector(activeSpaceDidChange),
            name: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil
        )
    }
    
    @objc private func activeSpaceDidChange() {
        Task {
            await MainActor.run {
                self.currentDesktopID = self.getCurrentDesktopID()
                self.updateActiveDesktop()
            }
        }
    }
    
    private func discoverVirtualDesktops() async -> [(spaceID: CGWindowID, name: String, windowCount: Int, applications: [String])] {
        // This is a simplified implementation
        // In reality, getting space information requires private APIs or complex workarounds
        
        var desktops: [(spaceID: CGWindowID, name: String, windowCount: Int, applications: [String])] = []
        
        // Create more distinct mock spaces with different characteristics
        let spaceConfigs = [
            (id: 1, name: "Main Desktop", windowCount: 3, apps: ["Finder", "Safari", "TextEdit"]),
            (id: 2, name: "Development", windowCount: 5, apps: ["Xcode", "Terminal", "Simulator", "GitHub Desktop"]),
            (id: 3, name: "Communication", windowCount: 2, apps: ["Mail", "Messages", "Slack"]),
            (id: 4, name: "Design", windowCount: 4, apps: ["Figma", "Photoshop", "Sketch", "Preview"])
        ]
        
        for config in spaceConfigs {
            let spaceID = CGWindowID(config.id)
            let applications = config.apps
            
            desktops.append((spaceID: spaceID, name: config.name, windowCount: config.windowCount, applications: applications))
        }
        
        return desktops
    }
    
    private func getCurrentDesktopID() -> CGWindowID {
        // Simplified - in reality, this would use private APIs
        // For demo purposes, simulate changing between different desktops
        let currentTime = Date().timeIntervalSince1970
        let desktopIndex = Int(currentTime / 10) % 4 + 1 // Change every 10 seconds, cycle through 1-4
        return CGWindowID(desktopIndex)
    }
    
    private func getApplicationsForSpace(_ spaceID: CGWindowID) -> [String] {
        // Get list of running applications
        let runningApps = NSWorkspace.shared.runningApplications
        let visibleApps = runningApps.filter { !$0.isHidden && $0.activationPolicy == .regular }
        
        return visibleApps.compactMap { $0.localizedName }
    }
    
    @MainActor
    private func updateActiveDesktop() {
        for desktop in virtualDesktops {
            desktop.isActive = (desktop.spaceID == currentDesktopID)
        }
    }
    
    private func updateAllPreviews() async {
        // Update previews more intelligently to avoid constant space switching
        
        // First, update the current active desktop immediately
        if let activeDesktop = virtualDesktops.first(where: { $0.spaceID == currentDesktopID }) {
            await activeDesktop.updatePreview()
        }
        
        // For other desktops, update them with a staggered approach to minimize disruption
        let inactiveDesktops = virtualDesktops.filter { $0.spaceID != currentDesktopID }
        
        // Update at most 1 inactive desktop per refresh cycle to minimize disruption
        if !inactiveDesktops.isEmpty {
            let desktopToUpdate = inactiveDesktops.randomElement()
            await desktopToUpdate?.updatePreview()
        }
    }
    
    private func resizeImage(_ image: NSImage, to newSize: NSSize) -> NSImage {
        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        
        let context = NSGraphicsContext.current
        context?.imageInterpolation = .high
        
        image.draw(in: NSRect(origin: .zero, size: newSize),
                  from: NSRect(origin: .zero, size: image.size),
                  operation: .sourceOver,
                  fraction: 1.0)
        
        newImage.unlockFocus()
        return newImage
    }
    
    @discardableResult
    private func executeAppleScript(_ script: String) -> Bool {
        let appleScript = NSAppleScript(source: script)
        var error: NSDictionary?
        appleScript?.executeAndReturnError(&error)
        
        if let error = error {
            print("AppleScript error: \(error)")
            return false
        }
        return true
    }
}

// MARK: - Desktop Information Structure
private struct DesktopInfo {
    let spaceID: CGWindowID
    let name: String
    let windowCount: Int
    let applications: [String]
} 