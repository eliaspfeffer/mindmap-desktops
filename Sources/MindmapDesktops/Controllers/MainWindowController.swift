import Cocoa
import Foundation

class MainWindowController: NSWindowController {
    
    private var mindmapView: MindmapView!
    private var spaceManager = SpaceManager.shared
    
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 1200, height: 800),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        self.init(window: window)
        setupWindow()
        setupMindmapView()
        setupBindings()
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        window?.makeKeyAndOrderFront(self)
    }
    
    // MARK: - Setup Methods
    
    private func setupWindow() {
        guard let window = window else { return }
        
        window.title = "Mindmap Desktops"
        window.minSize = NSSize(width: 800, height: 600)
        window.isReleasedWhenClosed = false
        
        // Set window appearance
        window.appearance = NSAppearance(named: .aqua)
        window.backgroundColor = NSColor.windowBackgroundColor
        
        // Center window on screen
        window.center()
        
        // Enable full-size content view
        window.styleMask.insert(.fullSizeContentView)
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
    }
    
    private func setupMindmapView() {
        guard let window = window else { return }
        
        // Create the main mindmap view
        mindmapView = MindmapView()
        mindmapView.translatesAutoresizingMaskIntoConstraints = false
        
        // Create a scroll view to contain the mindmap
        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.backgroundColor = NSColor.controlBackgroundColor
        
        // Configure scroll view
        scrollView.documentView = mindmapView
        scrollView.contentView.backgroundColor = NSColor.controlBackgroundColor
        
        // Add scroll view to window
        window.contentView?.addSubview(scrollView)
        
        // Set up constraints
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: window.contentView!.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: window.contentView!.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: window.contentView!.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: window.contentView!.bottomAnchor)
        ])
        
        // Set initial mindmap size
        mindmapView.frame = NSRect(x: 0, y: 0, width: 2000, height: 2000)
        
        // Enable magnification for zooming
        scrollView.allowsMagnification = true
        scrollView.minMagnification = 0.25
        scrollView.maxMagnification = 3.0
        scrollView.magnification = 1.0
    }
    
    private func setupBindings() {
        // Observe changes in virtual desktops and update mindmap
        spaceManager.$virtualDesktops
            .receive(on: DispatchQueue.main)
            .sink { [weak self] desktops in
                self?.updateMindmapWithDesktops(desktops)
            }
            .store(in: &cancellables)
        
        // Observe current desktop changes
        spaceManager.$currentDesktopID
            .receive(on: DispatchQueue.main)
            .sink { [weak self] currentID in
                self?.mindmapView.highlightCurrentDesktop(currentID)
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Public Methods
    
    func refreshDesktops() {
        Task {
            await spaceManager.refreshDesktops()
        }
    }
    
    func resetLayout() {
        mindmapView.resetLayout()
    }
    
    func createNewDesktopBranch() {
        // Create a new desktop and add it to the mindmap
        if spaceManager.createNewDesktop() {
            Task {
                // Wait a moment for the new desktop to be created
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await spaceManager.refreshDesktops()
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func updateMindmapWithDesktops(_ desktops: [VirtualDesktop]) {
        // Convert virtual desktops to mindmap nodes
        let desktopNodes = desktops.map { desktop -> MindMapNode in
            let node = MindMapNode(type: .desktop, title: desktop.name)
            node.virtualDesktop = desktop
            node.subtitle = "\(desktop.windowCount) windows"
            
            // Set color based on desktop state
            if desktop.isActive {
                node.color = .systemBlue
                node.borderWidth = 3.0
            } else {
                node.color = .systemGray
                node.borderWidth = 2.0
            }
            
            return node
        }
        
        mindmapView.updateNodes(desktopNodes)
    }
}

// MARK: - Window Delegate

extension MainWindowController: NSWindowDelegate {
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // Hide instead of close to keep app running in background
        sender.orderOut(nil)
        return false
    }
    
    func windowDidResize(_ notification: Notification) {
        // Adjust mindmap layout when window resizes
        mindmapView.adjustLayoutForWindowSize()
    }
    
    func windowDidBecomeKey(_ notification: Notification) {
        // Refresh desktops when window becomes active
        refreshDesktops()
    }
}

// Import Combine for reactive bindings
import Combine 