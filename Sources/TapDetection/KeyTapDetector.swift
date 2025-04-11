// ABOUTME: Provides detection for key taps and holds with configurable behavior.
// ABOUTME: Main API for consumers to detect when keys are tapped or held.

import Foundation
import Combine

#if canImport(AppKit)
import AppKit
#endif

#if canImport(Carbon)
import Carbon
#endif

public class KeyTapDetector {
    // MARK: - Public Types
    
    /// Represents a key that can be monitored for taps and holds
    public enum MonitoredKey: Hashable, CustomStringConvertible {
        case globe
        case leftShift
        case rightShift
        case function
        case control
        case option
        case command
        case capsLock
        case escape
        case tab
        case custom(CGKeyCode)
        
        public var description: String {
            switch self {
            case .globe: return "Globe"
            case .leftShift: return "LeftShift"
            case .rightShift: return "RightShift"
            case .function: return "Function"
            case .control: return "Control"
            case .option: return "Option"
            case .command: return "Command"
            case .capsLock: return "CapsLock"
            case .escape: return "Escape"
            case .tab: return "Tab"
            case .custom(let code): return "Custom(\(code))"
            }
        }
        
        var keyCode: CGKeyCode {
            switch self {
            case .globe: return CGKeyCode(63) // Fn key (0x3F)
            case .leftShift: return CGKeyCode(56) // (0x38)
            case .rightShift: return CGKeyCode(60) // (0x3C)
            case .function: return CGKeyCode(63) // Same as globe on modern keyboards (0x3F)
            case .control: return CGKeyCode(59) // (0x3B)
            case .option: return CGKeyCode(58) // (0x3A)
            case .command: return CGKeyCode(55) // (0x37)
            case .capsLock: return CGKeyCode(57) // (0x39)
            case .escape: return CGKeyCode(53) // (0x35)
            case .tab: return CGKeyCode(48) // (0x30)
            case .custom(let code): return code
            }
        }
        
        // Convert Carbon key code to MonitoredKey
        static func fromKeyCode(_ keyCode: CGKeyCode) -> MonitoredKey? {
            switch keyCode {
            case 63: return .globe // Fn/Globe key (0x3F)
            case 56: return .leftShift // (0x38)
            case 60: return .rightShift // (0x3C)
            case 59: return .control // (0x3B)
            case 58: return .option // (0x3A)
            case 55: return .command // (0x37)
            case 57: return .capsLock // (0x39)
            case 53: return .escape // (0x35)
            case 48: return .tab // (0x30)
            default: return .custom(keyCode)
            }
        }
    }
    
    /// Types of key events that can be detected
    public enum KeyEvent: CustomStringConvertible {
        case tapped(count: Int)
        case held
        case released
        
        public var description: String {
            switch self {
            case .tapped(let count):
                return "Tapped(\(count))"
            case .held:
                return "Held"
            case .released:
                return "Released"
            }
        }
    }
    
    // MARK: - Public Properties
    
    /// Time window in which multiple taps will be counted as a sequence (in seconds)
    public var tapTimeWindow: TimeInterval = 0.5
    
    /// Duration for a key to be considered "held" (in seconds)
    public var holdDuration: TimeInterval = 0.8
    
    /// Enable debug logging
    public var enableDebugLogging: Bool = true
    
    // MARK: - Private Properties
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var keyState: [MonitoredKey: KeyState] = [:]
    private var cancellables = Set<AnyCancellable>()
    
    private struct KeyState {
        var isDown = false
        var tapCount = 0
        var lastTapTime = Date.distantPast
        var holdTimer: AnyCancellable?
    }
    
    // MARK: - Public Methods
    
    public init() {
        setupEventTap()
        logDebug("KeyTapDetector initialized")
    }
    
    deinit {
        stopEventTap()
        logDebug("KeyTapDetector destroyed")
    }
    
    /// Register a callback for key events
    /// - Parameters:
    ///   - key: The key to monitor
    ///   - event: The event type to listen for
    ///   - callback: The function to call when the event occurs
    /// - Returns: A cancellable to stop monitoring this event
    @discardableResult
    public func onKey(_ key: MonitoredKey, event: KeyEvent, callback: @escaping () -> Void) -> AnyCancellable {
        logDebug("Registering callback for key: \(key), event: \(event)")
        
        let notificationName = Notification.Name("KeyTapDetector.\(key.hashValue).\(event.hashString)")
        logDebug("Using notification name: \(notificationName.rawValue)")
        
        let publisher = NotificationCenter.default.publisher(
            for: notificationName,
            object: nil
        )
        
        let cancellable = publisher
            .sink { [weak self] _ in
                self?.logDebug("Event triggered: \(key) \(event)")
                callback()
            }
        
        cancellables.insert(cancellable)
        return cancellable
    }
    
    // MARK: - Private Methods
    
    private func setupEventTap() {
        logDebug("Setting up event tap")
        
        // We need to monitor both key events and flag changes (for modifier keys)
        let eventMask = CGEventMask(
            (1 << CGEventType.keyDown.rawValue) |
            (1 << CGEventType.keyUp.rawValue) |
            (1 << CGEventType.flagsChanged.rawValue)
        )
        
        // Create callback
        let callback: CGEventTapCallBack = { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
            let detector = Unmanaged<KeyTapDetector>.fromOpaque(refcon!).takeUnretainedValue()
            detector.handleCGEvent(type: type, event: event)
            return Unmanaged.passRetained(event)
        }
        
        // Create the event tap
        eventTap = CGEvent.tapCreate(
            tap: .cghidEventTap,       // Respond to all events, including those from other processes
            place: .headInsertEventTap, // Insert at the head of the event queue
            options: .defaultTap,      // Default tap options
            eventsOfInterest: eventMask,
            callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )
        
        guard let eventTap = eventTap else {
            logDebug("ERROR: Failed to create event tap")
            return
        }
        
        // Create a run loop source and add it to the current run loop
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        
        if let runLoopSource = runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            // Enable the event tap
            CGEvent.tapEnable(tap: eventTap, enable: true)
            logDebug("Event tap successfully set up")
        } else {
            logDebug("ERROR: Failed to create run loop source")
        }
    }
    
    private func stopEventTap() {
        guard let eventTap = eventTap else { return }
        
        // Disable the event tap
        CGEvent.tapEnable(tap: eventTap, enable: false)
        
        // Remove the run loop source
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            self.runLoopSource = nil
        }
        
        self.eventTap = nil
        logDebug("Event tap stopped")
    }
    
    private func handleCGEvent(type: CGEventType, event: CGEvent) {
        // Handle different event types
        switch type {
        case .keyDown:
            let keyCodeInt64 = event.getIntegerValueField(.keyboardEventKeycode)
            let keyCode = CGKeyCode(truncatingIfNeeded: keyCodeInt64)
            if let monitoredKey = MonitoredKey.fromKeyCode(keyCode) {
                logDebug("Key down event detected: \(monitoredKey)")
                handleKeyDown(monitoredKey)
            }
            
        case .keyUp:
            let keyCodeInt64 = event.getIntegerValueField(.keyboardEventKeycode)
            let keyCode = CGKeyCode(truncatingIfNeeded: keyCodeInt64)
            if let monitoredKey = MonitoredKey.fromKeyCode(keyCode) {
                logDebug("Key up event detected: \(monitoredKey)")
                handleKeyUp(monitoredKey)
            }
            
        case .flagsChanged:
            handleFlagsChanged(event)
            
        default:
            break
        }
    }
    
    private func handleFlagsChanged(_ event: CGEvent) {
        let flags = event.flags
        let keyCodeInt64 = event.getIntegerValueField(.keyboardEventKeycode)
        let keyCode = CGKeyCode(truncatingIfNeeded: keyCodeInt64)
        
        logDebug("Flags changed event detected: keyCode=\(keyCode), flags=\(flags.rawValue)")
        
        // Map key code to our monitored key
        guard let monitoredKey = MonitoredKey.fromKeyCode(keyCode) else {
            logDebug("No monitored key for code \(keyCode)")
            return
        }
        
        // Determine if the key is pressed or released
        let isPressed = isModifierKeyPressed(monitoredKey, flags: flags)
        
        logDebug("Mapped to monitored key: \(monitoredKey), isPressed: \(isPressed)")
        
        if isPressed {
            handleKeyDown(monitoredKey)
        } else {
            handleKeyUp(monitoredKey)
        }
    }
    
    private func isModifierKeyPressed(_ key: MonitoredKey, flags: CGEventFlags) -> Bool {
        switch key {
        case .leftShift, .rightShift:
            return flags.contains(.maskShift)
        case .control:
            return flags.contains(.maskControl)
        case .option:
            return flags.contains(.maskAlternate)
        case .command:
            return flags.contains(.maskCommand)
        case .globe, .function:
            return flags.contains(.maskSecondaryFn)
        case .capsLock:
            return flags.contains(.maskAlphaShift)
        default:
            return false
        }
    }
    
    private func handleKeyDown(_ key: MonitoredKey) {
        logDebug("Handling key down for: \(key)")
        
        var state = keyState[key] ?? KeyState()
        
        if state.isDown {
            logDebug("Key already down, ignoring")
            return
        }
        
        state.isDown = true
        
        // Cancel existing hold timer if there is one
        state.holdTimer?.cancel()
        logDebug("Scheduled hold timer cancelled")
        
        // Schedule hold detection
        logDebug("Scheduling hold detection in \(holdDuration) seconds")
        let holdTimer = Timer.publish(every: holdDuration, on: .main, in: .common)
            .autoconnect()
            .first()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.logDebug("Hold timer fired for \(key)")
                self.triggerEvent(key: key, event: .held)
            }
        
        state.holdTimer = holdTimer
        keyState[key] = state
        logDebug("Key state updated for: \(key)")
    }
    
    private func handleKeyUp(_ key: MonitoredKey) {
        logDebug("Handling key up for: \(key)")
        
        guard var state = keyState[key], state.isDown else {
            logDebug("Key wasn't down, ignoring")
            return
        }
        
        state.isDown = false
        state.holdTimer?.cancel()
        state.holdTimer = nil
        logDebug("Hold timer cancelled")
        
        let now = Date()
        
        // Check if this keyUp is part of a tap sequence
        if now.timeIntervalSince(state.lastTapTime) <= tapTimeWindow {
            state.tapCount += 1
            logDebug("Part of tap sequence, new tap count: \(state.tapCount)")
        } else {
            state.tapCount = 1
            logDebug("New tap sequence started, tap count: 1")
        }
        
        state.lastTapTime = now
        keyState[key] = state
        
        // Trigger the tap after a delay to allow for multi-tap detection
        logDebug("Scheduling tap detection in \(tapTimeWindow) seconds")
        Timer.publish(every: tapTimeWindow, on: .main, in: .common)
            .autoconnect()
            .first()
            .sink { [weak self] _ in
                guard let self = self, let currentState = self.keyState[key] else { return }
                
                // Only process if no new taps have occurred during the wait period
                if currentState.lastTapTime.timeIntervalSince(now) < 0.001 {
                    let tapCount = currentState.tapCount
                    self.logDebug("Tap timer fired, triggering tap with count: \(tapCount)")
                    self.triggerEvent(key: key, event: .tapped(count: tapCount))
                    
                    // Reset tap count after triggering
                    var updatedState = currentState
                    updatedState.tapCount = 0
                    self.keyState[key] = updatedState
                    self.logDebug("Tap count reset to 0")
                } else {
                    self.logDebug("New tap occurred during wait, not triggering")
                }
            }
            .store(in: &cancellables)
        
        logDebug("Triggering released event for: \(key)")
        triggerEvent(key: key, event: .released)
    }
    
    private func triggerEvent(key: MonitoredKey, event: KeyEvent) {
        let name = Notification.Name("KeyTapDetector.\(key.hashValue).\(event.hashString)")
        logDebug("Posting notification: \(name.rawValue)")
        NotificationCenter.default.post(name: name, object: nil)
    }
    
    private func logDebug(_ message: String) {
        if enableDebugLogging {
            print("[TapDetection] \(message)")
        }
    }
}

extension KeyTapDetector.KeyEvent {
    var hashString: String {
        switch self {
        case .tapped(let count):
            return "tapped.\(count)"
        case .held:
            return "held"
        case .released:
            return "released"
        }
    }
}