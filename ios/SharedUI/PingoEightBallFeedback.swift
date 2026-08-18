import AudioToolbox
import UIKit

@MainActor
enum PingoEightBallFeedback {
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

    static func shotReleased() {
        mediumImpact.impactOccurred(intensity: 0.82)
        AudioServicesPlaySystemSound(1104)
        mediumImpact.prepare()
    }

    static func ballPocketed() {
        lightImpact.impactOccurred(intensity: 0.72)
        AudioServicesPlaySystemSound(1057)
        lightImpact.prepare()
    }

    static func scratch() {
        notification.notificationOccurred(.warning)
        AudioServicesPlaySystemSound(1053)
        notification.prepare()
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
