import Cocoa
import Foundation

// Enum for different types of mindmap nodes
enum MindMapNodeType {
    case root           // Central node
    case desktop        // Virtual desktop node
    case category       // Grouping node
    case task           // Task/project node
}

// Model representing a node in the mindmap
class MindMapNode: NSObject, Identifiable, ObservableObject {
    let id = UUID()
    
    @Published var type: MindMapNodeType
    @Published var title: String
    @Published var subtitle: String?
    @Published var position: CGPoint
    @Published var size: CGSize
    
    // Visual properties
    @Published var color: NSColor
    @Published var borderColor: NSColor
    @Published var borderWidth: CGFloat = 2.0
    @Published var cornerRadius: CGFloat = 8.0
    @Published var isSelected: Bool = false
    @Published var isHighlighted: Bool = false
    
    // Hierarchical relationships
    @Published var parent: MindMapNode?
    @Published var children: [MindMapNode] = []
    
    // Associated virtual desktop (if applicable)
    @Published var virtualDesktop: VirtualDesktop?
    
    // Animation properties
    @Published var scale: CGFloat = 1.0
    @Published var opacity: CGFloat = 1.0
    @Published var rotation: CGFloat = 0.0
    
    // Layout properties
    var level: Int {
        guard let parent = parent else { return 0 }
        return parent.level + 1
    }
    
    var isLeaf: Bool {
        return children.isEmpty
    }
    
    var isRoot: Bool {
        return parent == nil && type == .root
    }
    
    init(type: MindMapNodeType, title: String, position: CGPoint = .zero, size: CGSize = CGSize(width: 120, height: 60)) {
        self.type = type
        self.title = title
        self.position = position
        self.size = size
        
        // Set default colors based on type
        switch type {
        case .root:
            self.color = .systemPurple
            self.borderColor = .systemPurple
        case .desktop:
            self.color = .systemBlue
            self.borderColor = .systemBlue
        case .category:
            self.color = .systemGreen
            self.borderColor = .systemGreen
        case .task:
            self.color = .systemOrange
            self.borderColor = .systemOrange
        }
        
        super.init()
    }
    
    // Add child node
    func addChild(_ child: MindMapNode) {
        children.append(child)
        child.parent = self
    }
    
    // Remove child node
    func removeChild(_ child: MindMapNode) {
        children.removeAll { $0.id == child.id }
        child.parent = nil
    }
    
    // Remove from parent
    func removeFromParent() {
        parent?.removeChild(self)
    }
    
    // Get all descendants
    func getAllDescendants() -> [MindMapNode] {
        var descendants: [MindMapNode] = []
        for child in children {
            descendants.append(child)
            descendants.append(contentsOf: child.getAllDescendants())
        }
        return descendants
    }
    
    // Calculate bounds including all children
    func calculateBounds() -> CGRect {
        var minX = position.x
        var minY = position.y
        var maxX = position.x + size.width
        var maxY = position.y + size.height
        
        for child in getAllDescendants() {
            minX = min(minX, child.position.x)
            minY = min(minY, child.position.y)
            maxX = max(maxX, child.position.x + child.size.width)
            maxY = max(maxY, child.position.y + child.size.height)
        }
        
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
    
    // Check if point is inside node
    func contains(point: CGPoint) -> Bool {
        let frame = CGRect(origin: position, size: size)
        return frame.contains(point)
    }
    
    // Animate to new position
    func animateToPosition(_ newPosition: CGPoint, duration: Double = 0.3) {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = duration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            position = newPosition
        })
    }
    
    // Trigger selection visual feedback
    func select() {
        isSelected = true
        scale = 1.1
    }
    
    func deselect() {
        isSelected = false
        scale = 1.0
    }
}

// Extension for Equatable and Hashable
extension MindMapNode {
    static func == (lhs: MindMapNode, rhs: MindMapNode) -> Bool {
        return lhs.id == rhs.id
    }
    
    override var hash: Int {
        return id.hashValue
    }
} 