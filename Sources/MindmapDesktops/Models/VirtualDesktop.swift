import Cocoa
import Foundation

// Model representing a virtual desktop (Space) in macOS
@MainActor
class VirtualDesktop: NSObject, Identifiable, ObservableObject {
    let id = UUID()
    
    @Published var spaceID: CGWindowID
    @Published var name: String
    @Published var previewImage: NSImage?
    @Published var isActive: Bool = false
    @Published var windowCount: Int = 0
    @Published var applications: [String] = []
    
    // Custom properties for mindmap organization
    @Published var customColor: NSColor = .systemBlue
    @Published var tags: [String] = []
    @Published var category: String = ""
    @Published var position: CGPoint = .zero
    
    init(spaceID: CGWindowID, name: String? = nil) {
        self.spaceID = spaceID
        self.name = name ?? "Desktop \(spaceID)"
        super.init()
    }
    
    // Update preview image asynchronously
    func updatePreview() async {
        let image = await SpaceManager.shared.captureDesktopPreview(for: spaceID)
        self.previewImage = image
    }
    
    // Update desktop information
    func updateInfo(windowCount: Int, applications: [String]) {
        self.windowCount = windowCount
        self.applications = applications
    }
    
    // Switch to this desktop
    func activate() {
        SpaceManager.shared.switchToSpace(spaceID)
    }
}

// Extension for Equatable and Hashable
extension VirtualDesktop {
    static func == (lhs: VirtualDesktop, rhs: VirtualDesktop) -> Bool {
        return lhs.spaceID == rhs.spaceID
    }
    
    override var hash: Int {
        return spaceID.hashValue
    }
} 