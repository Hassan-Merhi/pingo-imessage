import AudioToolbox
import UIKit

@MainActor
enum PingoMiniRacingFeedback {
    private static let selection = UISelectionFeedbackGenerator()
    private static let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private static let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private static let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private static let notification = UINotificationFeedbackGenerator()

    static func prepare() {
        selection.prepare(); lightImpact.prepare(); mediumImpact.prepare(); heavyImpact.prepare(); notification.prepare()
    }

    static func raceStarted() {
        mediumImpact.impactOccurred(intensity: 0.78)
        AudioServicesPlaySystemSound(1104)
        mediumImpact.prepare()
    }

    static func runResolved() {
        lightImpact.impactOccurred(intensity: 0.55)
        AudioServicesPlaySystemSound(1105)
        lightImpact.prepare()
    }

    static func turnReady() {
        selection.selectionChanged()
        AudioServicesPlaySystemSound(1103)
        selection.prepare()
    }

    static func matchFinished(won: Bool) {
        notification.notificationOccurred(won ? .success : .error)
        if won { heavyImpact.impactOccurred(intensity: 0.92) }
        AudioServicesPlaySystemSound(won ? 1025 : 1053)
        heavyImpact.prepare(); notification.prepare()
    }
}
