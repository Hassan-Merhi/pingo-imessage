import AudioToolbox
import UIKit

@MainActor
enum PingoDrawGuessFeedback {
    private static let selection = UISelectionFeedbackGenerator()
    private static let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private static let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private static let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private static let notification = UINotificationFeedbackGenerator()

    static func prepare() {
        selection.prepare()
        lightImpact.prepare()
        mediumImpact.prepare()
        heavyImpact.prepare()
        notification.prepare()
    }

    static func moveSubmitted(artist: Bool) {
        if artist {
            mediumImpact.impactOccurred(intensity: 0.72)
            AudioServicesPlaySystemSound(1104)
            mediumImpact.prepare()
        } else {
            lightImpact.impactOccurred(intensity: 0.62)
            AudioServicesPlaySystemSound(1105)
            lightImpact.prepare()
        }
    }

    static func turnReady() {
        selection.selectionChanged()
        AudioServicesPlaySystemSound(1103)
        selection.prepare()
    }

    static func turnResolved(correct: Bool) {
        notification.notificationOccurred(correct ? .success : .warning)
        AudioServicesPlaySystemSound(correct ? 1025 : 1053)
        notification.prepare()
    }

    static func matchFinished(won: Bool) {
        notification.notificationOccurred(won ? .success : .error)
        if won {
            heavyImpact.impactOccurred(intensity: 0.94)
        }
        AudioServicesPlaySystemSound(won ? 1025 : 1053)
        heavyImpact.prepare()
        notification.prepare()
    }
}
