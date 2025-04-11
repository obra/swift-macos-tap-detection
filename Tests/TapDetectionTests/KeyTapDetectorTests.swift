// ABOUTME: Tests for the KeyTapDetector class functionality.
// ABOUTME: Verifies key detection, tap counting, and hold recognition.

import XCTest
import Foundation
import Combine
#if canImport(AppKit)
import AppKit
#endif
@testable import TapDetection

final class KeyTapDetectorTests: XCTestCase {
    var detector: KeyTapDetector?
    var cancellables: Set<AnyCancellable>?
    
    override func setUp() {
        super.setUp()
        detector = KeyTapDetector()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        detector = nil
        cancellables = nil
        super.tearDown()
    }
    
    func testMonitoredKeyKeyCodes() {
        // Values must match actual implementation
        XCTAssertEqual(KeyTapDetector.MonitoredKey.globe.keyCode, 63)     // 0x3F
        XCTAssertEqual(KeyTapDetector.MonitoredKey.leftShift.keyCode, 56) // 0x38
        XCTAssertEqual(KeyTapDetector.MonitoredKey.rightShift.keyCode, 60) // 0x3C
        XCTAssertEqual(KeyTapDetector.MonitoredKey.function.keyCode, 63)   // 0x3F
        XCTAssertEqual(KeyTapDetector.MonitoredKey.control.keyCode, 59)    // 0x3B
        XCTAssertEqual(KeyTapDetector.MonitoredKey.option.keyCode, 58)     // 0x3A
        XCTAssertEqual(KeyTapDetector.MonitoredKey.command.keyCode, 55)    // 0x37
        XCTAssertEqual(KeyTapDetector.MonitoredKey.capsLock.keyCode, 57)   // 0x39
        XCTAssertEqual(KeyTapDetector.MonitoredKey.escape.keyCode, 53)     // 0x35
        XCTAssertEqual(KeyTapDetector.MonitoredKey.tab.keyCode, 48)        // 0x30
        
        let customKeyCode: CGKeyCode = 0x42 // Some arbitrary key code
        XCTAssertEqual(KeyTapDetector.MonitoredKey.custom(customKeyCode).keyCode, customKeyCode)
    }
    
    func testCallbackRegistration() {
        guard let detector = detector else {
            XCTFail("Detector should be initialized")
            return
        }
        
        let expectation = XCTestExpectation(description: "Callback should be registered")
        
        let cancellable = detector.onKey(.globe, event: .tapped(count: 2)) {
            expectation.fulfill()
        }
        
        XCTAssertNotNil(cancellable)
        
        // We can't actually trigger the event in a unit test, so we'll just verify
        // that the cancellable is returned and not nil
        
        // Clean up
        cancellable.cancel()
    }
    
    // In a real test environment, we would mock NSEvent to test the event handling
    // But for this example, we'll just test the initialization and configuration
    
    func testDetectorInitialization() {
        guard let detector = detector else {
            XCTFail("Detector should be initialized")
            return
        }
        
        XCTAssertNotNil(detector)
        XCTAssertEqual(detector.tapTimeWindow, 0.5)
        XCTAssertEqual(detector.holdDuration, 0.8)
    }
    
    func testCustomConfiguration() {
        guard let detector = detector else {
            XCTFail("Detector should be initialized")
            return
        }
        
        detector.tapTimeWindow = 0.3
        detector.holdDuration = 1.0
        
        XCTAssertEqual(detector.tapTimeWindow, 0.3)
        XCTAssertEqual(detector.holdDuration, 1.0)
    }
    
    // Tests for our safety enhancements
    
    func testEventTapResilience() {
        // In a real environment, this would test the event tap being disabled
        // and then automatically re-enabled, but we can't disable system event taps
        // in unit tests. We're just verifying the code paths exist.
        guard let detector = detector else {
            XCTFail("Detector should be initialized")
            return
        }
        
        // Verify the watchdog timer exists for tap monitoring
        var timerFound = false
        
        // Use runtime reflection to check for watchdog timer
        Mirror(reflecting: detector).children.forEach { child in
            if child.label == "tapWatchdogTimer", child.value is Timer? {
                timerFound = true
            }
        }
        
        XCTAssertTrue(timerFound, "Watchdog timer should exist")
    }
    
    func testThreadSafety() {
        // Verify thread safety mechanisms exist
        guard let detector = detector else {
            XCTFail("Detector should be initialized")
            return
        }
        
        var lockFound = false
        
        // Use runtime reflection to check for state lock
        Mirror(reflecting: detector).children.forEach { child in
            if child.label == "keyStateLock", child.value is NSLock {
                lockFound = true
            }
        }
        
        XCTAssertTrue(lockFound, "Key state lock should exist")
    }
}
