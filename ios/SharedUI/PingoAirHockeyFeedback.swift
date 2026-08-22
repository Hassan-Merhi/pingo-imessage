import AudioToolbox
import UIKit

@MainActor
enum PingoAirHockeyFeedback {
    private static let selection = UISelectionFeedbackGenerator()
    private static let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private static let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private static let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private static let notification = UINotificationFeedbackGenerator()

    static func prepare() {
        selection.prepare(); lightImpact.prepare(); mediumImpact.prepare(); heavyImpact.prepare(); notification.prepare()
    }

    static func shotReleased() {
        mediumImpact.impactOccurred(intensity: 0.78)
        AudioServicesPlaySystemSound(1104)
        mediumImpact.prepare()
    }

    static func shotResolved(score: Int) {
        if score == 1 {
            notification.notificationOccurred(.success)
            heavyImpact.impactOccurred(intensity: 0.92)
            AudioServicesPlaySystemSound(1025)
        } else {
            lightImpact.impactOccurred(intensity: 0.52)
            AudioServicesPlaySystemSound(1105)
        }
        lightImpact.prepare(); heavyImpact.prepare(); notification.prepare()
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
