#!/usr/bin/swift

import Cocoa
import Carbon

// Simple tap detector that focuses specifically on shift and fn/globe keys
class KeyTapDetector {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
    enum KeyType: String {
        case leftShift = "Left Shift"
        case rightShift = "Right Shift"
        case globe = "Globe/Fn"
        case tab = "Tab"
        case unknown = "Unknown"
    }
    
    // Dictionary to map key codes to our types
    private let keyCodeMap: [CGKeyCode: KeyType] = [
        56: .leftShift,   // Left Shift
        60: .rightShift,  // Right Shift
        63: .globe,       // Globe/Fn
        48: .tab          // Tab
    ]
    
    // Dictionary to track key states
    private var keyStates: [KeyType: Bool] = [
        .leftShift: false,
        .rightShift: false,
        .globe: false,
        .tab: false
    ]
    
    init() {
        print("Key Tap Detector - Specifically monitoring:")
        print("  - Left Shift (keyCode 56)")
        print("  - Right Shift (keyCode 60)")
        print("  - Globe/Fn (keyCode 63)")
        print("  - Tab (keyCode 48)")
    }
    
    func start() {
        let eventMask = CGEventMask(
            (1 << CGEventType.keyDown.rawValue) |
            (1 << CGEventType.keyUp.rawValue) |
            (1 << CGEventType.flagsChanged.rawValue)
        )
        
        // Create callback
        let callback: CGEventTapCallBack = { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
            let detector = Unmanaged<KeyTapDetector>.fromOpaque(refcon!).takeUnretainedValue()
            detector.handleEvent(type: type, event: event)
            return Unmanaged.passRetained(event)
        }
        
        // Create the event tap
        eventTap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )
        
        guard let eventTap = eventTap else {
            print("ERROR: Failed to create event tap")
            return
        }
        
        // Create a run loop source and add it to the current run loop
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        
        guard let runLoopSource = runLoopSource else {
            print("ERROR: Failed to create run loop source")
            return
        }
        
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        print("Event tap enabled - monitoring started")
    }
    
    func stop() {
        guard let eventTap = eventTap else { return }
        CGEvent.tapEnable(tap: eventTap, enable: false)
        
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }
        
        print("Event tap disabled - monitoring stopped")
    }
    
    private func handleEvent(type: CGEventType, event: CGEvent) {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        
        // Only process keys we're specifically monitoring
        guard let keyType = keyCodeMap[CGKeyCode(keyCode)] else {
            return
        }
        
        // Handle the event based on its type
        switch type {
        case .keyDown:
            if !keyStates[keyType, default: false] {
                keyStates[keyType] = true
                print("\(keyType.rawValue) PRESSED (keyDown event, keyCode: \(keyCode))")
            }
            
        case .keyUp:
            if keyStates[keyType, default: false] {
                keyStates[keyType] = false
                print("\(keyType.rawValue) RELEASED (keyUp event, keyCode: \(keyCode))")
            }
            
        case .flagsChanged:
            // For modifier keys, we need to check the flags
            if keyType == .leftShift || keyType == .rightShift {
                let isPressed = event.flags.contains(.maskShift)
                if isPressed != keyStates[keyType, default: false] {
                    keyStates[keyType] = isPressed
                    print("\(keyType.rawValue) \(isPressed ? "PRESSED" : "RELEASED") (flagsChanged event, keyCode: \(keyCode))")
                }
            } else if keyType == .globe {
                let isPressed = event.flags.contains(.maskSecondaryFn)
                if isPressed != keyStates[keyType, default: false] {
                    keyStates[keyType] = isPressed
                    print("\(keyType.rawValue) \(isPressed ? "PRESSED" : "RELEASED") (flagsChanged event, keyCode: \(keyCode))")
                }
            }
            
        default:
            break
        }
    }
}

// Set up a simple app to run the detector
let app = NSApplication.shared
class AppDelegate: NSObject, NSApplicationDelegate {
    let detector = KeyTapDetector()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("Simple Key Tap Detection Demo")
        print("Press Ctrl+C to exit")
        
        // Request accessibility permissions
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        
        if !accessEnabled {
            print("⚠️ WARNING: Accessibility permissions needed!")
            print("Please grant accessibility permissions in System Preferences > Security & Privacy > Privacy > Accessibility")
        } else {
            print("✅ Accessibility permissions granted")
            detector.start()
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        detector.stop()
        print("Demo exited.")
    }
}

// Set up the app delegate and run the app
let delegate = AppDelegate()
app.delegate = delegate
app.run()