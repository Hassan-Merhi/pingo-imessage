import AudioToolbox
import UIKit

@MainActor
enum PingoWordHuntFeedback {
    private static let selection = UISelectionFeedbackGenerator()
    private static let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private static let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private static let notification = UINotificationFeedbackGenerator()

    static func prepare() {
        selection.prepare(); lightImpact.prepare(); mediumImpact.prepare(); notification.prepare()
    }

    static func wordSubmitted() {
        mediumImpact.impactOccurred(intensity: 0.72)
        AudioServicesPlaySystemSound(1104)
        mediumImpact.prepare()
    }

    static func wordResolved(points: Int) {
        if points > 0 {
            notification.notificationOccurred(.success)
            AudioServicesPlaySystemSound(1025)
        } else {
            lightImpact.impactOccurred(intensity: 0.5)
            AudioServicesPlaySystemSound(1105)
        }
        lightImpact.prepare(); notification.prepare()
    }

    static func turnReady() {
        selection.selectionChanged()
        AudioServicesPlaySystemSound(1103)
        selection.prepare()
    }

    static func matchFinished(won: Bool) {
        notification.notificationOccurred(won ? .success : .error)
        AudioServicesPlaySystemSound(won ? 1025 : 1053)
        notification.prepare()
    }
}
