import AudioToolbox
import UIKit

@MainActor
enum PingoMiniGolfFeedback {
    private static let selection = UISelectionFeedbackGenerator()
    private static let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private static let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private static let notification = UINotificationFeedbackGenerator()

    static func prepare() {
        selection.prepare()
        lightImpact.prepare()
        mediumImpact.prepare()
        notification.prepare()
    }

    static func aimChanged() {
        selection.selectionChanged()
        selection.prepare()
    }

    static func puttReleased() {
        mediumImpact.impactOccurred(intensity: 0.76)
        AudioServicesPlaySystemSound(1104)
        mediumImpact.prepare()
    }

    static func puttResolved(holed: Bool, autoFinished: Bool) {
        if holed && !autoFinished {
            notification.notificationOccurred(.success)
            AudioServicesPlaySystemSound(1025)
        } else {
            lightImpact.impactOccurred(intensity: autoFinished ? 0.76 : 0.48)
            AudioServicesPlaySystemSound(1105)
        }
        notification.prepare()
        lightImpact.prepare()
    }

    static func turnReady() {
        notification.notificationOccurred(.success)
        AudioServicesPlaySystemSound(1103)
        notification.prepare()
    }

    static func matchFinished(won: Bool) {
        notification.notificationOccurred(won ? .success : .error)
        AudioServicesPlaySystemSound(won ? 1025 : 1053)
        notification.prepare()
    }
}
