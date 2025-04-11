// ABOUTME: Handles application lifecycle and sets up key tap detection.
// ABOUTME: Demonstrates use of the TapDetection library in a real application.

import AppKit
import TapDetection
import Combine

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var detector: KeyTapDetector!
    var textView: NSTextView!
    var listeningButton: NSButton!
    var cancellables = Set<AnyCancellable>()
    var isListening = false
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("Application did finish launching")
        
        // IMPORTANT: Create a menu
        createMenu()
        
        // Create window
        createWindow()
        
        // Configure detector and permissions
        setupKeyTapDetector()
        checkAccessibilityPermissions()
        
        // Show the window and activate the app
        window.orderFrontRegardless()
        window.makeKey()
        NSApp.activate(ignoringOtherApps: true)
        
        print("Window should be visible now: \(window.isVisible)")
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    func createMenu() {
        let mainMenu = NSMenu()
        
        // Application menu
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        
        // About Item
        let aboutMenuItem = NSMenuItem(
            title: "About TapDetection Demo",
            action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)),
            keyEquivalent: ""
        )
        aboutMenuItem.target = NSApp
        appMenu.addItem(aboutMenuItem)
        
        // Separator
        appMenu.addItem(NSMenuItem.separator())
        
        // Quit Item
        let quitMenuItem = NSMenuItem(
            title: "Quit",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        quitMenuItem.target = NSApp
        appMenu.addItem(quitMenuItem)
        
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)
        
        // Set the menu
        NSApp.mainMenu = mainMenu
    }
    
    func createWindow() {
        // Create the window with an explicit position and size
        window = NSWindow(
            contentRect: NSRect(x: 200, y: 200, width: 600, height: 400),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "TapDetection Demo"
        window.isReleasedWhenClosed = false
        
        // Create main content view
        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 400))
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        
        // Create text view
        let scrollView = NSScrollView(frame: NSRect(x: 20, y: 60, width: 560, height: 300))
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autoresizingMask = [.width, .height]
        scrollView.borderType = .bezelBorder
        
        textView = NSTextView(frame: NSRect(x: 0, y: 0, width: 560, height: 300))
        textView.isEditable = false
        textView.isSelectable = true
        textView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.autoresizingMask = [.width, .height]
        
        scrollView.documentView = textView
        contentView.addSubview(scrollView)
        
        // Create button
        listeningButton = NSButton(frame: NSRect(x: 20, y: 20, width: 150, height: 30))
        listeningButton.title = "Start Listening"
        listeningButton.bezelStyle = .rounded
        listeningButton.target = self
        listeningButton.action = #selector(toggleListening)
        contentView.addSubview(listeningButton)
        
        // Set the content view
        window.contentView = contentView
    }
    
    func setupKeyTapDetector() {
        detector = KeyTapDetector()
        
        setupKeyMonitoring(.globe, name: "Globe")
        setupKeyMonitoring(.rightShift, name: "Right Shift")
        setupKeyMonitoring(.function, name: "Function")
        setupKeyMonitoring(.control, name: "Control")
        setupKeyMonitoring(.option, name: "Option")
        setupKeyMonitoring(.command, name: "Command")
        setupKeyMonitoring(.capsLock, name: "Caps Lock")
        setupKeyMonitoring(.escape, name: "Escape")
        setupKeyMonitoring(.tab, name: "Tab")
        
        appendToTextView("KeyTapDetector initialized")
    }
    
    func setupKeyMonitoring(_ key: KeyTapDetector.MonitoredKey, name: String) {
        detector.onKey(key, event: .tapped(count: 1)) { [weak self] in
            guard let self = self, self.isListening else { return }
            self.appendToTextView("🔄 \(name) single tap")
        }
        
        detector.onKey(key, event: .tapped(count: 2)) { [weak self] in
            guard let self = self, self.isListening else { return }
            self.appendToTextView("🔄🔄 \(name) double tap")
        }
        
        detector.onKey(key, event: .tapped(count: 3)) { [weak self] in
            guard let self = self, self.isListening else { return }
            self.appendToTextView("🔄🔄🔄 \(name) triple tap")
        }
        
        detector.onKey(key, event: .held) { [weak self] in
            guard let self = self, self.isListening else { return }
            self.appendToTextView("🔽 \(name) held down")
        }
        
        detector.onKey(key, event: .released) { [weak self] in
            guard let self = self, self.isListening else { return }
            self.appendToTextView("⬆️ \(name) released")
        }
    }
    
    @objc func toggleListening() {
        isListening = !isListening
        listeningButton.title = isListening ? "Stop Listening" : "Start Listening"
        
        if isListening {
            appendToTextView("Started listening for key events...")
        } else {
            appendToTextView("Stopped listening")
        }
    }
    
    func appendToTextView(_ text: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
            let entry = "[\(timestamp)] \(text)\n"
            
            if let textStorage = self.textView.textStorage {
                let attributedString = NSAttributedString(string: entry)
                textStorage.append(attributedString)
                self.textView.scrollToEndOfDocument(nil)
            }
            
            print("[\(timestamp)] \(text)")
        }
    }
    
    func checkAccessibilityPermissions() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        
        if !accessEnabled {
            appendToTextView("⚠️ Accessibility permissions needed")
            
            let alert = NSAlert()
            alert.messageText = "Accessibility Permissions Required"
            alert.informativeText = "To detect keyboard events, this app needs accessibility permissions. Please grant them in System Preferences > Security & Privacy > Privacy > Accessibility."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        } else {
            appendToTextView("✅ Accessibility permissions granted")
        }
    }
}