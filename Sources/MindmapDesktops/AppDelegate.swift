import Cocoa
import Foundation

class AppDelegate: NSObject, NSApplicationDelegate {
    
    var mainWindowController: MainWindowController?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        setupApplication()
        createMainWindow()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Clean up any resources
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    private func setupApplication() {
        // Configure application appearance
        NSApp.appearance = NSAppearance(named: .aqua)
        
        // Set up menu bar
        setupMenuBar()
    }
    
    private func createMainWindow() {
        mainWindowController = MainWindowController()
        mainWindowController?.showWindow(self)
        mainWindowController?.window?.makeKeyAndOrderFront(self)
    }
    
    private func setupMenuBar() {
        let mainMenu = NSMenu()
        
        // App menu
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About Mindmap Desktops", action: #selector(showAbout), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Preferences...", action: #selector(showPreferences), keyEquivalent: ",")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Quit Mindmap Desktops", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)
        
        // View menu
        let viewMenuItem = NSMenuItem(title: "View", action: nil, keyEquivalent: "")
        let viewMenu = NSMenu(title: "View")
        viewMenu.addItem(withTitle: "Refresh Desktops", action: #selector(refreshDesktops), keyEquivalent: "r")
        viewMenu.addItem(withTitle: "Reset Layout", action: #selector(resetLayout), keyEquivalent: "")
        viewMenuItem.submenu = viewMenu
        mainMenu.addItem(viewMenuItem)
        
        NSApplication.shared.mainMenu = mainMenu
    }
    
    @objc private func showAbout() {
        NSApp.orderFrontStandardAboutPanel(self)
    }
    
    @objc private func showPreferences() {
        // TODO: Implement preferences window
        print("Preferences not yet implemented")
    }
    
    @objc private func refreshDesktops() {
        mainWindowController?.refreshDesktops()
    }
    
    @objc private func resetLayout() {
        mainWindowController?.resetLayout()
    }
} 