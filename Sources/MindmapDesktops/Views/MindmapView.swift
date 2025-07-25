import Cocoa
import Foundation

class MindmapView: NSView {
    
    // MARK: - Properties
    
    private var nodes: [MindMapNode] = []
    private var rootNode: MindMapNode?
    private var connections: [(from: MindMapNode, to: MindMapNode)] = []
    
    // Interaction state
    private var selectedNode: MindMapNode?
    private var draggedNode: MindMapNode?
    private var dragOffset: CGPoint = .zero
    private var lastMouseLocation: CGPoint = .zero
    
    // Layout engine
    private let layoutEngine = RadialTreeLayout()
    
    // Animation layers
    private var nodeLayer: CALayer!
    private var connectionLayer: CALayer!
    private var backgroundLayer: CALayer!
    
    // MARK: - Initialization
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
        setupLayers()
        createRootNode()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        setupLayers()
        createRootNode()
    }
    
    // MARK: - Setup Methods
    
    private func setupView() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        
        // Enable mouse tracking
        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.activeInActiveApp, .mouseMoved, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
    }
    
    private func setupLayers() {
        guard let layer = layer else { return }
        
        // Background layer for grid/pattern
        backgroundLayer = CALayer()
        backgroundLayer.frame = layer.bounds
        layer.addSublayer(backgroundLayer)
        
        // Connection layer for drawing lines between nodes
        connectionLayer = CALayer()
        connectionLayer.frame = layer.bounds
        layer.addSublayer(connectionLayer)
        
        // Node layer for rendering nodes
        nodeLayer = CALayer()
        nodeLayer.frame = layer.bounds
        layer.addSublayer(nodeLayer)
        
        drawBackground()
    }
    
    private func createRootNode() {
        rootNode = MindMapNode(type: .root, title: "Virtual Desktops", position: CGPoint(x: bounds.midX, y: bounds.midY))
        rootNode?.size = CGSize(width: 160, height: 80)
        rootNode?.color = .systemPurple
        
        if let root = rootNode {
            nodes.append(root)
            addNodeLayer(for: root)
        }
    }
    
    // MARK: - Public Methods
    
    func updateNodes(_ desktopNodes: [MindMapNode]) {
        // Remove existing desktop nodes, keep root and categories
        nodes.removeAll { $0.type == .desktop }
        
        // Clear existing connections
        connections.removeAll()
        
        // Add new desktop nodes as children of root
        guard let root = rootNode else { return }
        
        root.children.removeAll { $0.type == .desktop }
        
        for desktopNode in desktopNodes {
            nodes.append(desktopNode)
            root.addChild(desktopNode)
        }
        
        // Update layout
        layoutEngine.updateLayout(root: root, in: bounds)
        
        // Redraw everything
        rebuildLayers()
    }
    
    func highlightCurrentDesktop(_ currentDesktopID: CGWindowID?) {
        for node in nodes {
            if let desktop = node.virtualDesktop,
               desktop.spaceID == currentDesktopID {
                node.isHighlighted = true
                node.borderWidth = 4.0
                node.borderColor = .systemYellow
            } else {
                node.isHighlighted = false
                node.borderWidth = 2.0
                node.borderColor = node.color
            }
        }
        
        rebuildLayers()
    }
    
    func resetLayout() {
        guard let root = rootNode else { return }
        
        // Reset root position to center
        root.position = CGPoint(x: bounds.midX, y: bounds.midY)
        
        // Recalculate layout
        layoutEngine.updateLayout(root: root, in: bounds)
        
        // Animate to new positions
        animateNodesToNewPositions()
        rebuildLayers()
    }
    
    func adjustLayoutForWindowSize() {
        // Recalculate layout when window resizes
        resetLayout()
    }
    
    // MARK: - Drawing Methods
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        // All drawing is handled by Core Animation layers
    }
    
    private func drawBackground() {
        backgroundLayer.sublayers?.removeAll()
        
        // Draw subtle grid pattern
        let gridLayer = CAShapeLayer()
        let gridPath = CGMutablePath()
        
        let gridSpacing: CGFloat = 50
        
        // Vertical lines
        var x: CGFloat = 0
        while x <= bounds.width {
            gridPath.move(to: CGPoint(x: x, y: 0))
            gridPath.addLine(to: CGPoint(x: x, y: bounds.height))
            x += gridSpacing
        }
        
        // Horizontal lines
        var y: CGFloat = 0
        while y <= bounds.height {
            gridPath.move(to: CGPoint(x: 0, y: y))
            gridPath.addLine(to: CGPoint(x: bounds.width, y: y))
            y += gridSpacing
        }
        
        gridLayer.path = gridPath
        gridLayer.strokeColor = NSColor.quaternaryLabelColor.cgColor
        gridLayer.lineWidth = 0.5
        gridLayer.opacity = 0.3
        
        backgroundLayer.addSublayer(gridLayer)
    }
    
    private func rebuildLayers() {
        // Clear existing layers
        nodeLayer.sublayers?.removeAll()
        connectionLayer.sublayers?.removeAll()
        
        // Rebuild connections
        rebuildConnections()
        
        // Rebuild nodes
        for node in nodes {
            addNodeLayer(for: node)
        }
    }
    
    private func rebuildConnections() {
        guard let root = rootNode else { return }
        
        connections.removeAll()
        buildConnectionsRecursive(from: root)
        
        for connection in connections {
            addConnectionLayer(from: connection.from, to: connection.to)
        }
    }
    
    private func buildConnectionsRecursive(from parent: MindMapNode) {
        for child in parent.children {
            connections.append((from: parent, to: child))
            buildConnectionsRecursive(from: child)
        }
    }
    
    private func addConnectionLayer(from: MindMapNode, to: MindMapNode) {
        let connectionLayer = CAShapeLayer()
        
        // Create curved connection path
        let path = CGMutablePath()
        let fromCenter = CGPoint(
            x: from.position.x + from.size.width / 2,
            y: from.position.y + from.size.height / 2
        )
        let toCenter = CGPoint(
            x: to.position.x + to.size.width / 2,
            y: to.position.y + to.size.height / 2
        )
        
        // Create smooth bezier curve
        let controlPoint1 = CGPoint(
            x: fromCenter.x + (toCenter.x - fromCenter.x) * 0.3,
            y: fromCenter.y
        )
        let controlPoint2 = CGPoint(
            x: fromCenter.x + (toCenter.x - fromCenter.x) * 0.7,
            y: toCenter.y
        )
        
        path.move(to: fromCenter)
        path.addCurve(to: toCenter, control1: controlPoint1, control2: controlPoint2)
        
        connectionLayer.path = path
        connectionLayer.strokeColor = NSColor.secondaryLabelColor.cgColor
        connectionLayer.lineWidth = 2.0
        connectionLayer.fillColor = NSColor.clear.cgColor
        connectionLayer.lineCap = .round
        
        self.connectionLayer.addSublayer(connectionLayer)
    }
    
    private func addNodeLayer(for node: MindMapNode) {
        let layer = CALayer()
        layer.frame = CGRect(origin: node.position, size: node.size)
        layer.backgroundColor = node.color.cgColor
        layer.cornerRadius = node.cornerRadius
        layer.borderWidth = node.borderWidth
        layer.borderColor = node.borderColor.cgColor
        
        // Add shadow
        layer.shadowColor = NSColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: -2)
        layer.shadowRadius = 4
        layer.shadowOpacity = 0.2
        
        // Add text layer
        let textLayer = CATextLayer()
        textLayer.frame = layer.bounds.insetBy(dx: 8, dy: 8)
        textLayer.string = node.title
        textLayer.fontSize = node.type == .root ? 16 : 12
        textLayer.foregroundColor = NSColor.controlTextColor.cgColor
        textLayer.alignmentMode = .center
        textLayer.isWrapped = true
        textLayer.contentsScale = NSScreen.main?.backingScaleFactor ?? 1.0
        
        layer.addSublayer(textLayer)
        
        // Add preview image if available (for desktop nodes)
        if let desktop = node.virtualDesktop,
           let previewImage = desktop.previewImage {
            let imageLayer = CALayer()
            imageLayer.frame = CGRect(x: 4, y: 20, width: node.size.width - 8, height: node.size.height - 32)
            imageLayer.contents = previewImage
            imageLayer.contentsGravity = .resizeAspectFill
            imageLayer.cornerRadius = 4
            imageLayer.masksToBounds = true
            
            layer.addSublayer(imageLayer)
        }
        
        // Apply transformations
        layer.transform = CATransform3DMakeScale(node.scale, node.scale, 1.0)
        layer.opacity = Float(node.opacity)
        
        nodeLayer.addSublayer(layer)
        
        // Store reference for interaction
        layer.setValue(node.id.uuidString, forKey: "nodeID")
    }
    
    // MARK: - Mouse Event Handling
    
    override func mouseDown(with event: NSEvent) {
        let locationInView = convert(event.locationInWindow, from: nil)
        
        if let node = findNode(at: locationInView) {
            selectedNode = node
            draggedNode = node
            dragOffset = CGPoint(
                x: locationInView.x - node.position.x,
                y: locationInView.y - node.position.y
            )
            
            node.select()
            rebuildLayers()
            
            // Handle double-click for desktop activation
            if event.clickCount == 2 && node.type == .desktop {
                node.virtualDesktop?.activate()
            }
        } else {
            selectedNode?.deselect()
            selectedNode = nil
            rebuildLayers()
        }
        
        lastMouseLocation = locationInView
    }
    
    override func mouseDragged(with event: NSEvent) {
        guard let draggedNode = draggedNode else { return }
        
        let locationInView = convert(event.locationInWindow, from: nil)
        
        // Update node position
        draggedNode.position = CGPoint(
            x: locationInView.x - dragOffset.x,
            y: locationInView.y - dragOffset.y
        )
        
        // If dragging root node, update layout for all children
        if draggedNode.isRoot {
            layoutEngine.updateChildrenPositions(root: draggedNode)
        }
        
        rebuildLayers()
    }
    
    override func mouseUp(with event: NSEvent) {
        if let draggedNode = draggedNode {
            // Snap to grid if desired
            snapToGrid(node: draggedNode)
            
            // Check for drop on other nodes to create relationships
            let locationInView = convert(event.locationInWindow, from: nil)
            if let targetNode = findNode(at: locationInView),
               targetNode != draggedNode {
                handleNodeDrop(draggedNode, on: targetNode)
            }
        }
        
        draggedNode = nil
        rebuildLayers()
    }
    
    override func rightMouseDown(with event: NSEvent) {
        let locationInView = convert(event.locationInWindow, from: nil)
        
        if let node = findNode(at: locationInView) {
            showContextMenu(for: node, at: locationInView)
        } else {
            showBackgroundContextMenu(at: locationInView)
        }
    }
    
    // MARK: - Helper Methods
    
    private func findNode(at point: CGPoint) -> MindMapNode? {
        return nodes.first { $0.contains(point: point) }
    }
    
    private func snapToGrid(node: MindMapNode) {
        let gridSize: CGFloat = 20
        node.position.x = round(node.position.x / gridSize) * gridSize
        node.position.y = round(node.position.y / gridSize) * gridSize
    }
    
    private func handleNodeDrop(_ droppedNode: MindMapNode, on targetNode: MindMapNode) {
        // Logic for creating relationships between nodes
        if targetNode.type == .category || targetNode.type == .root {
            droppedNode.removeFromParent()
            targetNode.addChild(droppedNode)
            layoutEngine.updateLayout(root: rootNode!, in: bounds)
        }
    }
    
    private func showContextMenu(for node: MindMapNode, at point: CGPoint) {
        let menu = NSMenu()
        
        if node.type == .desktop {
            let switchItem = NSMenuItem(title: "Switch to Desktop", action: #selector(switchToDesktop(_:)), keyEquivalent: "")
            switchItem.representedObject = node
            menu.addItem(switchItem)
            
            let renameItem = NSMenuItem(title: "Rename Desktop", action: #selector(renameDesktop(_:)), keyEquivalent: "")
            renameItem.representedObject = node
            menu.addItem(renameItem)
            
            menu.addItem(NSMenuItem.separator())
        }
        
        let deleteItem = NSMenuItem(title: "Delete Node", action: #selector(deleteNode(_:)), keyEquivalent: "")
        deleteItem.representedObject = node
        menu.addItem(deleteItem)
        
        let addChildItem = NSMenuItem(title: "Add Child", action: #selector(addChildNode(_:)), keyEquivalent: "")
        addChildItem.representedObject = node
        menu.addItem(addChildItem)
        
        NSMenu.popUpContextMenu(menu, with: NSApp.currentEvent!, for: self)
    }
    
    private func showBackgroundContextMenu(at point: CGPoint) {
        let menu = NSMenu()
        
        let newDesktopItem = NSMenuItem(title: "Create New Desktop", action: #selector(createNewDesktop(_:)), keyEquivalent: "")
        newDesktopItem.representedObject = NSValue(point: point)
        menu.addItem(newDesktopItem)
        
        let addCategoryItem = NSMenuItem(title: "Add Category", action: #selector(addCategory(_:)), keyEquivalent: "")
        addCategoryItem.representedObject = NSValue(point: point)
        menu.addItem(addCategoryItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let resetLayoutItem = NSMenuItem(title: "Reset Layout", action: #selector(resetLayoutAction(_:)), keyEquivalent: "")
        resetLayoutItem.representedObject = NSValue(point: point)
        menu.addItem(resetLayoutItem)
        
        NSMenu.popUpContextMenu(menu, with: NSApp.currentEvent!, for: self)
    }
    
    private func animateNodesToNewPositions() {
        for node in nodes {
            node.animateToPosition(node.position)
        }
    }
    
    // MARK: - Context Menu Actions
    
    @objc private func switchToDesktop(_ sender: NSMenuItem) {
        guard let node = sender.representedObject as? MindMapNode else { return }
        node.virtualDesktop?.activate()
    }
    
    @objc private func renameDesktop(_ sender: NSMenuItem) {
        guard let node = sender.representedObject as? MindMapNode else { return }
        // TODO: Implement rename dialog
        print("Rename desktop: \(node.title)")
    }
    
    @objc private func deleteNode(_ sender: NSMenuItem) {
        guard let node = sender.representedObject as? MindMapNode else { return }
        if node.type != MindMapNodeType.root {
            node.removeFromParent()
            nodes.removeAll { $0.id == node.id }
            rebuildLayers()
        }
    }
    
    @objc private func addChildNode(_ sender: NSMenuItem) {
        guard let parentNode = sender.representedObject as? MindMapNode else { return }
        
        let newNode = MindMapNode(type: .task, title: "New Task")
        newNode.position = CGPoint(
            x: parentNode.position.x + 150,
            y: parentNode.position.y
        )
        
        nodes.append(newNode)
        parentNode.addChild(newNode)
        
        layoutEngine.updateLayout(root: rootNode!, in: bounds)
        rebuildLayers()
    }
    
    @objc private func createNewDesktop(_ sender: NSMenuItem) {
        _ = SpaceManager.shared.createNewDesktop()
    }
    
    @objc private func addCategory(_ sender: NSMenuItem) {
        guard let pointValue = sender.representedObject as? NSValue else { return }
        let point = pointValue.pointValue
        
        let categoryNode = MindMapNode(type: .category, title: "New Category")
        categoryNode.position = point
        
        nodes.append(categoryNode)
        rootNode?.addChild(categoryNode)
        
        rebuildLayers()
    }
    
    @objc private func resetLayoutAction(_ sender: NSMenuItem) {
        resetLayout()
    }
}

// MARK: - Radial Tree Layout Engine

class RadialTreeLayout {
    
    func updateLayout(root: MindMapNode, in bounds: CGRect) {
        updateChildrenPositions(root: root)
    }
    
    func updateChildrenPositions(root: MindMapNode) {
        guard !root.children.isEmpty else { return }
        
        let angleStep = 2 * CGFloat.pi / CGFloat(root.children.count)
        let radius: CGFloat = 150
        
        for (index, child) in root.children.enumerated() {
            let angle = angleStep * CGFloat(index)
            let x = root.position.x + root.size.width / 2 + cos(angle) * radius - child.size.width / 2
            let y = root.position.y + root.size.height / 2 + sin(angle) * radius - child.size.height / 2
            
            child.position = CGPoint(x: x, y: y)
            
            // Recursively layout children
            if !child.children.isEmpty {
                updateChildrenPositions(root: child)
            }
        }
    }
} 