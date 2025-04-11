import AppKit
import TapDetection
import Combine
import Foundation
import Carbon

// Create an application - required for NSEvent monitoring to work properly
let app = NSApplication.shared
class AppDelegate: NSObject, NSApplicationDelegate {
    var detector: KeyTapDetector!
    var debugMonitor: Any?
    var flagsChangedMonitor: Any?
    var isRunning = true
    var cancellables = Set<AnyCancellable>()
    private var lastFlags: NSEvent.ModifierFlags = []
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("Starting TapDetection CLI Demo with Debug Info")

        // Create a detector with verbose logging
        detector = KeyTapDetector()
        detector.enableDebugLogging = true
        
        // Setup debugging monitors
        setupDebugMonitors()
        
        // Setup actual key detection
        setupKeyMonitoring()
        
        // Request accessibility permissions
        print("Checking accessibility permissions...")
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)

        if !accessEnabled {
            print("⚠️ WARNING: Accessibility permissions needed!")
            print("Please grant accessibility permissions in System Preferences > Security & Privacy > Privacy > Accessibility")
        } else {
            print("✅ Accessibility permissions granted")
        }
        
        print("Detector parameters:")
        print("  tapTimeWindow = \(detector.tapTimeWindow)")
        print("  holdDuration = \(detector.holdDuration)")
        
        print("\nTesting monitor setup...")
        print("Now press keys to see events. The following keys are being monitored:")
        print("  - Globe/Fn key (keyCode = \(KeyTapDetector.MonitoredKey.globe.keyCode))")
        print("  - Left Shift key (keyCode = \(KeyTapDetector.MonitoredKey.leftShift.keyCode))")
        print("  - Right Shift key (keyCode = \(KeyTapDetector.MonitoredKey.rightShift.keyCode))")
        print("  - Tab key (keyCode = \(KeyTapDetector.MonitoredKey.tab.keyCode))")
        print("Triple-tap TAB key to exit.")
        print("Press Ctrl+C to exit the application.")
        
        // Setup a timer to ensure the runloop keeps running
        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                // Just keep the runloop alive
            }
            .store(in: &cancellables)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        print("Demo exited.")
    }
    
    // Set up debugging monitors to help diagnose key detection issues
    func setupDebugMonitors() {
        // Monitor standard key events
        debugMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp]) { event in
            print("DEBUG: Local monitor - Key event: type=\(event.type), keyCode=\(event.keyCode)")
            return event
        }
        
        // Monitor global key events
        NSEvent.addGlobalMonitorForEvents(matching: [.keyDown, .keyUp]) { event in
            print("DEBUG: Global monitor - Key event: type=\(event.type), keyCode=\(event.keyCode)")
        }
        
        // Monitor modifier key events specifically
        flagsChangedMonitor = NSEvent.addLocalMonitorForEvents(matching: [.flagsChanged]) { [weak self] event in
            guard let self = self else { return event }
            
            // Detect which modifier changed by comparing with previous flags
            let oldFlags = self.lastFlags
            let newFlags = event.modifierFlags
            
            print("DEBUG: Modifier flags changed - keyCode=\(event.keyCode), flags=\(newFlags.rawValue)")
            
            // Check specific modifiers
            if oldFlags.contains(.shift) != newFlags.contains(.shift) {
                print("DEBUG: SHIFT modifier \(newFlags.contains(.shift) ? "PRESSED" : "RELEASED")")
            }
            if oldFlags.contains(.control) != newFlags.contains(.control) {
                print("DEBUG: CONTROL modifier \(newFlags.contains(.control) ? "PRESSED" : "RELEASED")")
            }
            if oldFlags.contains(.option) != newFlags.contains(.option) {
                print("DEBUG: OPTION modifier \(newFlags.contains(.option) ? "PRESSED" : "RELEASED")")
            }
            if oldFlags.contains(.command) != newFlags.contains(.command) {
                print("DEBUG: COMMAND modifier \(newFlags.contains(.command) ? "PRESSED" : "RELEASED")")
            }
            if oldFlags.contains(.function) != newFlags.contains(.function) {
                print("DEBUG: FUNCTION modifier \(newFlags.contains(.function) ? "PRESSED" : "RELEASED")")
            }
            
            // Store current flags for next comparison
            self.lastFlags = newFlags
            
            return event
        }
        
        // Global flags changed monitor
        NSEvent.addGlobalMonitorForEvents(matching: [.flagsChanged]) { [weak self] event in
            print("DEBUG: Global monitor - Flags changed: keyCode=\(event.keyCode), flags=\(event.modifierFlags.rawValue)")
        }
    }
    
    // Set up key monitoring with debug info
    func setupKeyMonitoring() {
        print("Setting up key monitoring...")
        
        // Focus on monitoring both shift keys and the globe key
        let keysToMonitor: [KeyTapDetector.MonitoredKey] = [
            .globe, .leftShift, .rightShift, .tab
        ]
        
        print("\n🔑 SPECIFICALLY MONITORING THESE KEYS:")
        print("  - Globe key (fn/globe on modern MacBooks)")
        print("  - Left Shift key")
        print("  - Right Shift key")
        print("  - Tab key (for testing exit functionality)")
        print("")
        
        for key in keysToMonitor {
            let keyName = String(describing: key)
            
            // Single tap
            detector.onKey(key, event: .tapped(count: 1)) {
                print("✓ DETECTED: \(keyName) tapped once")
            }
            
            // Double tap
            detector.onKey(key, event: .tapped(count: 2)) {
                print("✓ DETECTED: \(keyName) double-tapped")
            }
            
            // Hold
            detector.onKey(key, event: .held) {
                print("✓ DETECTED: \(keyName) held down")
            }
            
            // Release
            detector.onKey(key, event: .released) {
                print("✓ DETECTED: \(keyName) released")
            }
            
            print("  Registered handlers for \(keyName)")
        }
        
        // Special handler for testing - tab triple tap to exit
        detector.onKey(.tab, event: .tapped(count: 3)) {
            print("Triple-tap on Tab detected! Exiting...")
            NSApplication.shared.terminate(self)
        }
        
        // Add a debug timer to verify the app is still running
        Timer.publish(every: 5.0, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                print("DEBUG: App is still running... (timer tick)")
            }
            .store(in: &cancellables)
    }
}

// Set up the app delegate
let delegate = AppDelegate()
app.delegate = delegate

// Run the application
print("Starting application main run loop...")
app.run()