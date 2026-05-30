import AVFoundation
import ApplicationServices
import Foundation

@MainActor
protocol PermissionAuthorizing {
    var microphonePermission: PermissionState { get }
    func requestMicrophonePermission() async -> PermissionState
    func isAccessibilityTrusted(prompt: Bool) -> Bool
    func requestAccessibilityPermission() -> Bool
}

@MainActor
final class PermissionsService: PermissionAuthorizing {
    var microphonePermission: PermissionState {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            return .granted
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            return .unknown
        @unknown default:
            return .unknown
        }
    }

    func requestMicrophonePermission() async -> PermissionState {
        let current = microphonePermission
        guard current == .unknown else { return current }

        let granted = await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                continuation.resume(returning: granted)
            }
        }
        return granted ? .granted : .denied
    }

    func isAccessibilityTrusted(prompt: Bool) -> Bool {
        let options: NSDictionary = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt
        ]
        return AXIsProcessTrustedWithOptions(options)
    }

    func requestAccessibilityPermission() -> Bool {
        isAccessibilityTrusted(prompt: true)
    }
}
