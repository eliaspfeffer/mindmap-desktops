# Mindmap Desktops

A native macOS application that visualizes your virtual desktops (Spaces) in an interactive mindmap interface. Organize your workspaces by task, project, or category with visual previews and easy navigation.

## ✨ Features

- **Interactive Mindmap**: Visualize your virtual desktops in a beautiful, zoomable mindmap
- **Desktop Previews**: See live thumbnail previews of each virtual desktop
- **Click to Switch**: Double-click any desktop node to instantly switch to that Space
- **Custom Organization**: Drag desktops into different branches and categories
- **Task Management**: Create custom categories and organize desktops by project or workflow
- **Real-time Updates**: Automatically detects new desktops and updates the mindmap
- **Smooth Animations**: Hardware-accelerated animations with Core Animation
- **Context Menus**: Right-click for additional options like renaming and creating new desktops

## 🎯 Use Cases

- **Job Applications**: Dedicate one desktop branch to job searching, applications, and interviews
- **Development Projects**: Organize different coding projects across separate desktop spaces
- **Research & Writing**: Keep research materials on one desktop, writing tools on another
- **Creative Work**: Separate design tools, inspiration, and project files
- **Personal & Professional**: Clear separation between work and personal tasks

## 🛠 Technical Architecture

Built with:

- **Swift + AppKit** for native macOS performance
- **Core Animation** for smooth, hardware-accelerated graphics
- **Radial Tree Layout** algorithm for optimal mindmap organization
- **AppleScript integration** for reliable Space switching
- **Accessibility APIs** for system integration

## 📋 Requirements

- macOS 13.0 or later
- Xcode 15.0 or later (for building from source)
- Accessibility permissions (prompted on first run)

## 🚀 Building & Running

### Option 1: Using Swift Package Manager

```bash
# Clone the repository
git clone <repository-url>
cd mindmap-desktops

# Build and run
swift build
swift run MindmapDesktops
```

### Option 2: Using Xcode

1. Open Terminal and navigate to the project directory
2. Generate Xcode project:
   ```bash
   swift package generate-xcodeproj
   ```
3. Open `MindmapDesktops.xcodeproj` in Xcode
4. Select your target device and click Run

## 🔐 Permissions

The app requires **Accessibility permissions** to:

- Switch between virtual desktops
- Create new desktop spaces
- Capture desktop previews

When you first run the app, macOS will prompt you to grant these permissions in System Preferences > Security & Privacy > Accessibility.

## 🎮 Usage

### Basic Navigation

- **Double-click** a desktop node to switch to that Space
- **Drag nodes** to reorganize your mindmap
- **Scroll & zoom** to navigate large mindmaps
- **Right-click** for context menus with additional options

### Creating Structure

- **Right-click empty space** → "Add Category" to create organizational branches
- **Right-click empty space** → "Create New Desktop" to add new virtual desktops
- **Drag desktop nodes** onto category nodes to organize them

### Menu Options

- **View → Refresh Desktops** (⌘R) to update the mindmap
- **View → Reset Layout** to return to default positions

## 🏗 Architecture Overview

```
┌─────────────────────────────────────┐
│             MindmapView             │ ← Custom NSView with Core Animation
├─────────────────────────────────────┤
│          MainWindowController       │ ← Coordinates UI and data flow
├─────────────────────────────────────┤
│            SpaceManager             │ ← Handles macOS Spaces integration
├─────────────────────────────────────┤
│     Models (VirtualDesktop,         │ ← Data models and relationships
│              MindMapNode)           │
└─────────────────────────────────────┘
```

## 🔧 Configuration

The app automatically discovers your virtual desktops and creates a mindmap. You can customize:

- **Desktop names**: Right-click any desktop node → "Rename Desktop"
- **Categories**: Create custom categories to group related desktops
- **Layout**: Drag nodes to your preferred positions
- **Colors**: Different node types have distinct color schemes

## 🐛 Known Limitations

- **Desktop detection**: Uses simplified detection methods for demo purposes
- **Private APIs**: Full Spaces control requires private APIs (not App Store compatible)
- **Screenshot capture**: Shows current screen rather than specific Space content
- **AppleScript timing**: Space switching may have brief delays

## 🚧 Future Enhancements

- **Persistent layouts**: Save custom mindmap arrangements
- **Desktop templates**: Quick setup for common workflows
- **Mission Control integration**: Better native Spaces detection
- **Keyboard shortcuts**: Hotkeys for quick desktop switching
- **Export/Import**: Share mindmap configurations

## 📖 How It Works

1. **Discovery**: Scans for virtual desktops using macOS APIs
2. **Visualization**: Creates mindmap nodes with preview thumbnails
3. **Interaction**: Handles mouse events for dragging and clicking
4. **Switching**: Uses AppleScript to reliably switch between Spaces
5. **Updates**: Continuously monitors for changes to virtual desktops

## 💡 Tips

- **Organize by workflow**: Group related applications on the same desktop
- **Use categories**: Create branches like "Work", "Personal", "Projects"
- **Regular updates**: The app refreshes every 5 seconds, or use ⌘R manually
- **Zoom for clarity**: Use scroll wheel to zoom in/out for better visibility

## 🤝 Contributing

This project was built as a demonstration of native macOS development with mindmap visualization. Feel free to extend it with:

- Better Space detection algorithms
- Enhanced visual themes
- Additional organization features
- Integration with productivity tools

## 📄 License

MIT License - see LICENSE file for details.

---

**Note**: This application demonstrates concepts for virtual desktop management. For production use, consider implementing more robust Space detection and handling edge cases specific to your macOS version.
