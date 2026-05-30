import AppKit
import ApplicationServices

struct RecordingOverlayAnchor: Equatable {
    let rect: CGRect
}

enum RecordingOverlayPositioning {
    static let overlaySize = CGSize(width: 72, height: 72)
    static let resultMaxWidth: CGFloat = 540
    static let resultMinWidth: CGFloat = 260
    static let edgeInset: CGFloat = 8
    static let anchorGap: CGFloat = 12
    static let fallbackTopInset: CGFloat = 10

    static func origin(
        for anchor: RecordingOverlayAnchor?,
        overlaySize: CGSize = overlaySize,
        visibleFrame: CGRect
    ) -> CGPoint {
        guard let anchor else {
            return CGPoint(
                x: visibleFrame.midX - overlaySize.width / 2,
                y: visibleFrame.maxY - overlaySize.height - fallbackTopInset
            )
            .clamped(overlaySize: overlaySize, visibleFrame: visibleFrame, edgeInset: edgeInset)
        }

        let anchorRect = anchor.rect
        let preferredBelow = CGPoint(
            x: anchorRect.midX - overlaySize.width / 2,
            y: anchorRect.minY - overlaySize.height - anchorGap
        )
        let preferredAbove = CGPoint(
            x: anchorRect.midX - overlaySize.width / 2,
            y: anchorRect.maxY + anchorGap
        )

        let unclamped = preferredBelow.y >= visibleFrame.minY + edgeInset ? preferredBelow : preferredAbove
        return unclamped.clamped(
            overlaySize: overlaySize,
            visibleFrame: visibleFrame,
            edgeInset: edgeInset
        )
    }

    static func menuBarCenteredOrigin(
        overlaySize: CGSize,
        visibleFrame: CGRect
    ) -> CGPoint {
        CGPoint(
            x: visibleFrame.midX - overlaySize.width / 2,
            y: visibleFrame.maxY - overlaySize.height - fallbackTopInset
        )
        .clamped(
            overlaySize: overlaySize,
            visibleFrame: visibleFrame,
            edgeInset: edgeInset
        )
    }
}

@MainActor
enum RecordingOverlayAnchorResolver {
    static func resolve() -> RecordingOverlayAnchor? {
        if let focusedElement = focusedElement() {
            if let caretAnchor = caretAnchor(in: focusedElement) {
                return caretAnchor
            }
            if let elementAnchor = elementBoundsAnchor(focusedElement) {
                return elementAnchor
            }
        }

        return nil
    }

    private static func focusedElement() -> AXUIElement? {
        let systemWide = AXUIElementCreateSystemWide()
        var focusedObject: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedUIElementAttribute as CFString,
            &focusedObject
        ) == .success,
            let focusedObject
        else {
            return nil
        }

        return (focusedObject as! AXUIElement)
    }

    private static func caretAnchor(in element: AXUIElement) -> RecordingOverlayAnchor? {
        guard let selectedRangeValue = copyAXValue(
            kAXSelectedTextRangeAttribute as CFString,
            from: element
        ) else {
            return nil
        }

        var boundsObject: CFTypeRef?
        guard AXUIElementCopyParameterizedAttributeValue(
            element,
            kAXBoundsForRangeParameterizedAttribute as CFString,
            selectedRangeValue,
            &boundsObject
        ) == .success,
            let boundsObject,
            CFGetTypeID(boundsObject) == AXValueGetTypeID()
        else {
            return nil
        }

        let boundsValue = boundsObject as! AXValue
        guard let rect = cgRect(from: boundsValue) else { return nil }
        return convertAccessibilityRectToAppKit(rect).map(RecordingOverlayAnchor.init(rect:))
    }

    private static func elementBoundsAnchor(_ element: AXUIElement) -> RecordingOverlayAnchor? {
        guard isTextEntryElement(element) else { return nil }
        guard let rect = positionSizeRect(for: element) else { return nil }
        return convertAccessibilityRectToAppKit(rect).map(RecordingOverlayAnchor.init(rect:))
    }

    private static func isTextEntryElement(_ element: AXUIElement) -> Bool {
        if let role = copyString(kAXRoleAttribute as CFString, from: element),
           ["AXTextField", "AXTextArea", "AXComboBox"].contains(role) {
            return true
        }

        if let subrole = copyString(kAXSubroleAttribute as CFString, from: element),
           ["AXSearchField"].contains(subrole) {
            return true
        }

        return copyAXValue(kAXSelectedTextRangeAttribute as CFString, from: element) != nil
    }

    private static func positionSizeRect(for element: AXUIElement) -> CGRect? {
        guard let positionValue = copyAXValue(kAXPositionAttribute as CFString, from: element),
              let sizeValue = copyAXValue(kAXSizeAttribute as CFString, from: element),
              let point = cgPoint(from: positionValue),
              let size = cgSize(from: sizeValue)
        else {
            return nil
        }

        return normalized(CGRect(origin: point, size: size))
    }

    private static func copyAXValue(_ attribute: CFString, from element: AXUIElement) -> AXValue? {
        var object: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute, &object) == .success,
              let object,
              CFGetTypeID(object) == AXValueGetTypeID()
        else {
            return nil
        }
        return (object as! AXValue)
    }

    private static func copyString(_ attribute: CFString, from element: AXUIElement) -> String? {
        var object: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute, &object) == .success,
              let object,
              CFGetTypeID(object) == CFStringGetTypeID()
        else {
            return nil
        }
        return String(object as! CFString)
    }

    private static func cgRect(from value: AXValue) -> CGRect? {
        var rect = CGRect.zero
        guard AXValueGetValue(value, .cgRect, &rect) else { return nil }
        return normalized(rect)
    }

    private static func cgPoint(from value: AXValue) -> CGPoint? {
        var point = CGPoint.zero
        guard AXValueGetValue(value, .cgPoint, &point) else { return nil }
        return point
    }

    private static func cgSize(from value: AXValue) -> CGSize? {
        var size = CGSize.zero
        guard AXValueGetValue(value, .cgSize, &size) else { return nil }
        return size
    }

    private static func normalized(_ rect: CGRect) -> CGRect? {
        guard rect.origin.x.isFinite,
              rect.origin.y.isFinite,
              rect.size.width.isFinite,
              rect.size.height.isFinite,
              !rect.isNull
        else {
            return nil
        }

        var normalized = rect.standardized
        normalized.size.width = max(normalized.size.width, 1)
        normalized.size.height = max(normalized.size.height, 1)
        return normalized
    }

    private static func convertAccessibilityRectToAppKit(_ rect: CGRect) -> CGRect? {
        guard let normalized = normalized(rect) else { return nil }
        guard let screen = screen(containingAccessibilityRect: normalized) else {
            return normalized
        }

        return CGRect(
            x: normalized.minX,
            y: screen.frame.maxY - normalized.maxY,
            width: normalized.width,
            height: normalized.height
        )
    }

    private static func screen(containingAccessibilityRect rect: CGRect) -> NSScreen? {
        let candidates = [
            CGPoint(x: rect.midX, y: rect.midY),
            CGPoint(x: rect.minX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.maxY)
        ]

        return NSScreen.screens.first { screen in
            candidates.contains { point in
                point.x >= screen.frame.minX &&
                    point.x <= screen.frame.maxX &&
                    point.y >= 0 &&
                    point.y <= screen.frame.height
            }
        } ?? NSScreen.main
    }
}

private extension CGPoint {
    func clamped(overlaySize: CGSize, visibleFrame: CGRect, edgeInset: CGFloat) -> CGPoint {
        CGPoint(
            x: min(
                max(x, visibleFrame.minX + edgeInset),
                visibleFrame.maxX - overlaySize.width - edgeInset
            ),
            y: min(
                max(y, visibleFrame.minY + edgeInset),
                visibleFrame.maxY - overlaySize.height - edgeInset
            )
        )
    }
}
