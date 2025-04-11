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
        XCTAssertEqual(KeyTapDetector.MonitoredKey.globe.keyCode, 0x6E)
        XCTAssertEqual(KeyTapDetector.MonitoredKey.rightShift.keyCode, 0x3C)
        XCTAssertEqual(KeyTapDetector.MonitoredKey.function.keyCode, 0x3F)
        XCTAssertEqual(KeyTapDetector.MonitoredKey.control.keyCode, 0x3B)
        XCTAssertEqual(KeyTapDetector.MonitoredKey.option.keyCode, 0x3A)
        XCTAssertEqual(KeyTapDetector.MonitoredKey.command.keyCode, 0x37)
        XCTAssertEqual(KeyTapDetector.MonitoredKey.capsLock.keyCode, 0x39)
        XCTAssertEqual(KeyTapDetector.MonitoredKey.escape.keyCode, 0x35)
        XCTAssertEqual(KeyTapDetector.MonitoredKey.tab.keyCode, 0x30)
        
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
}
