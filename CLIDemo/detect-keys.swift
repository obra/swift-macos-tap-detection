#!/usr/bin/swift

import Cocoa
import Carbon

// Set up a simple key event detector
let app = NSApplication.shared
class AppDelegate: NSObject, NSApplicationDelegate {
    var lastFlags: NSEvent.ModifierFlags = []
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("Simple Key Detection Demo")
        print("Press Ctrl+C to exit")
        
        // Monitor flagsChanged events
        NSEvent.addGlobalMonitorForEvents(matching: [.flagsChanged]) { [weak self] event in
            guard let self = self else { return }
            
            let keyCode = event.keyCode
            let flags = event.modifierFlags
            
            // Detect which flag changed
            let oldFlags = self.lastFlags
            self.lastFlags = flags
            
            print("Flags Changed - keyCode: \(keyCode)")
            
            if oldFlags.contains(.shift) != flags.contains(.shift) {
                print("  SHIFT \(flags.contains(.shift) ? "PRESSED" : "RELEASED")")
            }
            if oldFlags.contains(.control) != flags.contains(.control) {
                print("  CONTROL \(flags.contains(.control) ? "PRESSED" : "RELEASED")")
            }
            if oldFlags.contains(.option) != flags.contains(.option) {
                print("  OPTION \(flags.contains(.option) ? "PRESSED" : "RELEASED")")
            }
            if oldFlags.contains(.command) != flags.contains(.command) {
                print("  COMMAND \(flags.contains(.command) ? "PRESSED" : "RELEASED")")
            }
            if oldFlags.contains(.function) != flags.contains(.function) {
                print("  FUNCTION \(flags.contains(.function) ? "PRESSED" : "RELEASED")")
            }
        }
        
        // Monitor key events
        NSEvent.addGlobalMonitorForEvents(matching: [.keyDown, .keyUp]) { event in
            let keyCode = event.keyCode
            print("\(event.type == .keyDown ? "KeyDown" : "KeyUp") - keyCode: \(keyCode)")
        }
    }
}

let delegate = AppDelegate()
app.delegate = delegate
app.run()