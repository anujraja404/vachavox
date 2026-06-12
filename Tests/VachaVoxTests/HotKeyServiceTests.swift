import XCTest
@testable import VachaVox

final class HotKeyServiceTests: XCTestCase {
    func testFunctionKeyTrackerEmitsDownAndUpForFnPressRelease() {
        var tracker = FunctionKeyStateTracker()

        XCTAssertEqual(
            tracker.transition(isFunctionKeyEvent: true, functionModifierDown: true),
            .down
        )
        XCTAssertTrue(tracker.isDown)

        XCTAssertEqual(
            tracker.transition(isFunctionKeyEvent: true, functionModifierDown: false),
            .up
        )
        XCTAssertFalse(tracker.isDown)
    }

    func testFunctionKeyTrackerIgnoresRepeatedStateEvents() {
        var tracker = FunctionKeyStateTracker()

        XCTAssertEqual(
            tracker.transition(isFunctionKeyEvent: true, functionModifierDown: true),
            .down
        )
        XCTAssertNil(tracker.transition(isFunctionKeyEvent: true, functionModifierDown: true))
        XCTAssertNil(tracker.transition(isFunctionKeyEvent: false, functionModifierDown: true))
    }

    func testFunctionKeyTrackerHandlesModifierOnlyRelease() {
        var tracker = FunctionKeyStateTracker()

        XCTAssertEqual(
            tracker.transition(isFunctionKeyEvent: true, functionModifierDown: true),
            .down
        )
        XCTAssertEqual(
            tracker.transition(isFunctionKeyEvent: false, functionModifierDown: false),
            .up
        )
    }

    func testFunctionKeyTrackerResetClearsDownState() {
        var tracker = FunctionKeyStateTracker()

        XCTAssertEqual(
            tracker.transition(isFunctionKeyEvent: true, functionModifierDown: true),
            .down
        )
        tracker.reset()

        XCTAssertFalse(tracker.isDown)
        XCTAssertEqual(
            tracker.transition(isFunctionKeyEvent: true, functionModifierDown: true),
            .down
        )
    }
}
