import AudioToolbox
import UIKit

@MainActor
enum PingoCrazyEightsFeedback {
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

    static func moveSubmitted(isDraw: Bool) {
        (isDraw ? lightImpact : mediumImpact).impactOccurred(intensity: isDraw ? 0.45 : 0.75)
        AudioServicesPlaySystemSound(isDraw ? 1103 : 1104)
        lightImpact.prepare()
        mediumImpact.prepare()
    }

    static func moveResolved(summary: String) {
        if summary.hasPrefix("Played") {
            notification.notificationOccurred(.success)
            AudioServicesPlaySystemSound(1025)
        } else {
            selection.selectionChanged()
            AudioServicesPlaySystemSound(1105)
        }
        selection.prepare()
        notification.prepare()
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
