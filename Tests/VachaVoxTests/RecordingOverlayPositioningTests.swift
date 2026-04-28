import XCTest
@testable import VachaVox

final class RecordingOverlayPositioningTests: XCTestCase {
    func testOverlayPrefersBelowCaretAnchor() {
        let visibleFrame = CGRect(x: 0, y: 0, width: 1_000, height: 800)
        let anchor = RecordingOverlayAnchor(rect: CGRect(x: 500, y: 400, width: 2, height: 20))

        let origin = RecordingOverlayPositioning.origin(for: anchor, visibleFrame: visibleFrame)

        XCTAssertEqual(origin.x, 465, accuracy: 0.001)
        XCTAssertEqual(origin.y, 316, accuracy: 0.001)
    }

    func testOverlayFlipsAboveNearScreenBottom() {
        let visibleFrame = CGRect(x: 0, y: 0, width: 1_000, height: 800)
        let anchor = RecordingOverlayAnchor(rect: CGRect(x: 500, y: 40, width: 2, height: 20))

        let origin = RecordingOverlayPositioning.origin(for: anchor, visibleFrame: visibleFrame)

        XCTAssertEqual(origin.x, 465, accuracy: 0.001)
        XCTAssertEqual(origin.y, 72, accuracy: 0.001)
    }

    func testOverlayClampsToVisibleFrameEdges() {
        let visibleFrame = CGRect(x: 40, y: 30, width: 500, height: 400)
        let leftAnchor = RecordingOverlayAnchor(rect: CGRect(x: 42, y: 300, width: 2, height: 20))
        let rightAnchor = RecordingOverlayAnchor(rect: CGRect(x: 538, y: 300, width: 2, height: 20))

        let leftOrigin = RecordingOverlayPositioning.origin(for: leftAnchor, visibleFrame: visibleFrame)
        let rightOrigin = RecordingOverlayPositioning.origin(for: rightAnchor, visibleFrame: visibleFrame)

        XCTAssertEqual(leftOrigin.x, 48, accuracy: 0.001)
        XCTAssertEqual(rightOrigin.x, 460, accuracy: 0.001)
        XCTAssertEqual(leftOrigin.y, 216, accuracy: 0.001)
        XCTAssertEqual(rightOrigin.y, 216, accuracy: 0.001)
    }

    func testOverlayUsesTopCenterWhenAnchorIsMissing() {
        let visibleFrame = CGRect(x: 100, y: 50, width: 600, height: 500)

        let origin = RecordingOverlayPositioning.origin(for: nil, visibleFrame: visibleFrame)

        XCTAssertEqual(origin.x, 364, accuracy: 0.001)
        XCTAssertEqual(origin.y, 468, accuracy: 0.001)
    }

    func testMenuBarCenteredOriginAlignsToVisibleFrameMidpoint() {
        let visibleFrame = CGRect(x: 200, y: 40, width: 1000, height: 700)
        let overlaySize = CGSize(width: 300, height: 100)

        let origin = RecordingOverlayPositioning.menuBarCenteredOrigin(
            overlaySize: overlaySize,
            visibleFrame: visibleFrame
        )

        XCTAssertEqual(origin.x, 550, accuracy: 0.001)
        XCTAssertEqual(origin.y, 630, accuracy: 0.001)
    }
}
