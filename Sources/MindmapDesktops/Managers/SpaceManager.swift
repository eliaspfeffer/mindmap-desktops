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
        // Use CGWindowListCreateImage to capture desktop content
        // This is a simplified version - in reality, capturing a specific space is complex
        
        let cgImage = CGWindowListCreateImage(
            CGRect.null,
            .optionOnScreenOnly,
            kCGNullWindowID,
            [.bestResolution, .boundsIgnoreFraming]
        )
        
        guard let cgImage = cgImage else { return nil }
        
        // Convert to NSImage and resize for thumbnail
        let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        return resizeImage(nsImage, to: NSSize(width: 200, height: 150))
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
        
        // For demonstration, we'll create some mock spaces
        // In a real implementation, you'd use Core Foundation Private APIs or other methods
        for i in 1...4 {
            let spaceID = CGWindowID(i)
            let name = "Desktop \(i)"
            let windowCount = Int.random(in: 0...5)
            let applications = getApplicationsForSpace(spaceID)
            
            desktops.append((spaceID: spaceID, name: name, windowCount: windowCount, applications: applications))
        }
        
        return desktops
    }
    
    private func getCurrentDesktopID() -> CGWindowID {
        // Simplified - in reality, this would use private APIs
        return CGWindowID(1) // Return first space for now
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
        await withTaskGroup(of: Void.self) { group in
            for desktop in virtualDesktops {
                group.addTask {
                    await desktop.updatePreview()
                }
            }
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