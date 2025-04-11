import AppKit
import Combine
import Foundation
import TapDetection

// Create a basic app with a window
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var textView: NSTextView!
    var startButton: NSButton!
    var detector: KeyTapDetector!
    var isListening = false
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("App started")
        
        // Create a window
        window = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 500, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "TapDetection Demo"
        
        // Create a text view
        let scrollView = NSScrollView(frame: NSRect(x: 20, y: 60, width: 460, height: 200))
        scrollView.hasVerticalScroller = true
        
        textView = NSTextView(frame: NSRect(x: 0, y: 0, width: 460, height: 200))
        textView.isEditable = false
        textView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        
        scrollView.documentView = textView
        window.contentView?.addSubview(scrollView)
        
        // Create a button
        startButton = NSButton(frame: NSRect(x: 20, y: 20, width: 150, height: 30))
        startButton.title = "Start Listening"
        startButton.bezelStyle = .rounded
        startButton.target = self
        startButton.action = #selector(toggleListening)
        window.contentView?.addSubview(startButton)
        
        // Set up tap detector
        setupTapDetector()
        
        // Show the window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        log("App ready. Click 'Start Listening' to begin.")
    }
    
    func setupTapDetector() {
        detector = KeyTapDetector()
        
        // Globe key
        detector.onKey(KeyTapDetector.MonitoredKey.globe, event: KeyTapDetector.KeyEvent.tapped(count: 1)) { [weak self] in
            self?.handleEvent(key: "Globe", event: "tapped")
        }
        
        detector.onKey(KeyTapDetector.MonitoredKey.globe, event: KeyTapDetector.KeyEvent.held) { [weak self] in
            self?.handleEvent(key: "Globe", event: "held")
        }
        
        // Right Shift key
        detector.onKey(KeyTapDetector.MonitoredKey.rightShift, event: KeyTapDetector.KeyEvent.tapped(count: 1)) { [weak self] in
            self?.handleEvent(key: "Right Shift", event: "tapped")
        }
        
        detector.onKey(KeyTapDetector.MonitoredKey.rightShift, event: KeyTapDetector.KeyEvent.held) { [weak self] in
            self?.handleEvent(key: "Right Shift", event: "held")
        }
        
        // Function key
        detector.onKey(KeyTapDetector.MonitoredKey.function, event: KeyTapDetector.KeyEvent.tapped(count: 1)) { [weak self] in
            self?.handleEvent(key: "Function", event: "tapped")
        }
        
        detector.onKey(KeyTapDetector.MonitoredKey.function, event: KeyTapDetector.KeyEvent.held) { [weak self] in
            self?.handleEvent(key: "Function", event: "held")
        }
    }
    
    func handleEvent(key: String, event: String) {
        if isListening {
            log("\(key) key \(event)")
        }
    }
    
    @objc func toggleListening() {
        isListening = !isListening
        startButton.title = isListening ? "Stop Listening" : "Start Listening"
        
        if isListening {
            log("Started listening for key events")
        } else {
            log("Stopped listening")
        }
    }
    
    func log(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let text = "[\(timestamp)] \(message)\n"
        print(text)
        
        DispatchQueue.main.async { [weak self] in
            if let textStorage = self?.textView.textStorage {
                let attributedString = NSAttributedString(string: text)
                textStorage.append(attributedString)
                self?.textView.scrollToEndOfDocument(nil)
            }
        }
    }
}

// Create and run the application
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()