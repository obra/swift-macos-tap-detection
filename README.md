# macOS Key Tap Detection

This Swift package enables detection of key taps and holds on macOS, designed specifically for implementing power-user features in dictation and other apps. It can detect special keys like the Globe key, Shift keys, and function keys that don't generate keystrokes.

This library was written by an AI agent to do something I found useful. Caveat Emptor.

## Features

- Detect when modifier keys are held down (Globe/Fn, Left Shift, Right Shift, etc.)
- Count taps on keys (double, triple, quadruple taps)
- Configurable time windows for tap sequences
- Configurable hold durations
- Clean API with Combine support
- Robust detection of modifier keys that don't generate regular keystrokes

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/obra/swift-macos-tap-detection.git", from: "1.0.0")
]
```

For proper functionality, you'll also need to add Carbon as a linked framework:

```swift
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["TapDetection"],
        linkerSettings: [
            .linkedFramework("Carbon")
        ]
    ),
]
```

## Usage

```swift
import TapDetection

let detector = KeyTapDetector()

// Configure timing parameters (optional)
detector.tapTimeWindow = 0.4 // Time window for counting multiple taps (default: 0.5s)
detector.holdDuration = 1.0 // Duration for a key to be considered "held" (default: 0.8s)

// Monitor a double-tap on the Globe key
detector.onKey(.globe, event: .tapped(count: 2)) {
    print("Globe key double-tapped!")
}

// Monitor right shift being held down
detector.onKey(.rightShift, event: .held) {
    print("Right shift is being held!")
}

// Monitor left shift being released
detector.onKey(.leftShift, event: .released) {
    print("Left shift was released!")
}

// Enable logging for debugging
detector.enableDebugLogging = true
```

## Demo Apps

The package includes two demo applications:

### CLI Demo

A command-line app for testing and debugging.

1. Navigate to the `CLIDemo` directory
2. Run `./run.sh` to build and run the demo
3. Follow on-screen instructions to test key detection

### Simple Tap Detector

A minimal example for testing key detection:

1. Navigate to the `CLIDemo` directory
2. Run `./tap-detector.swift` to start the detector
3. Press the modifier keys (shift, globe, etc.) to see detection in action

## Supported Keys

The package provides built-in support for the following keys:

- `.globe` (Fn/Globe key on modern keyboards)
- `.leftShift`
- `.rightShift`
- `.function` (Same as globe on modern keyboards)
- `.control`
- `.option`
- `.command`
- `.capsLock`
- `.escape`
- `.tab`
- `.custom(CGKeyCode)` (for any other key by its key code)

## Key Codes

For reference, here are the key codes used by the library:

- Globe/Fn: 63 (0x3F)
- Left Shift: 56 (0x38)
- Right Shift: 60 (0x3C)
- Control: 59 (0x3B)
- Option: 58 (0x3A)
- Command: 55 (0x37)
- Caps Lock: 57 (0x39)
- Escape: 53 (0x35)
- Tab: 48 (0x30)

## Requirements

- macOS 11.0+
- Swift 5.3+
- Carbon.framework (linked automatically)

## Security & Permissions

This package requires accessibility permissions to monitor keyboard events. Your app must:

1. Request accessibility permissions in code
2. Be added to System Preferences > Security & Privacy > Privacy > Accessibility

Example code to request permissions:

```swift
let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: true]
let accessEnabled = AXIsProcessTrustedWithOptions(options)

if !accessEnabled {
    print("Please enable accessibility permissions in System Settings > Privacy & Security > Accessibility")
}
```

## Implementation Details

The library uses CGEvent.tapCreate to monitor system-wide keyboard events including:
- Regular key presses (keyDown, keyUp)
- Modifier key state changes (flagsChanged)

This approach provides more reliable detection of modifier keys than NSEvent monitoring alone.

## License

This project is available under the MIT license. See the LICENSE file for more info.
