import AudioToolbox
import UIKit

@MainActor
enum PingoPenaltyShootoutFeedback {
    private static let selection = UISelectionFeedbackGenerator()
    private static let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private static let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private static let notification = UINotificationFeedbackGenerator()

    static func prepare() {
        selection.prepare()
        mediumImpact.prepare()
        heavyImpact.prepare()
        notification.prepare()
    }

    static func aimChanged() {
        selection.selectionChanged()
        selection.prepare()
    }

    static func kickReleased() {
        mediumImpact.impactOccurred(intensity: 0.80)
        AudioServicesPlaySystemSound(1104)
        mediumImpact.prepare()
    }

    static func kickResolved(goal: Bool) {
        if goal {
            notification.notificationOccurred(.success)
            heavyImpact.impactOccurred(intensity: 0.90)
            AudioServicesPlaySystemSound(1025)
        } else {
            notification.notificationOccurred(.warning)
            mediumImpact.impactOccurred(intensity: 0.56)
            AudioServicesPlaySystemSound(1053)
        }
        notification.prepare()
        mediumImpact.prepare()
        heavyImpact.prepare()
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
