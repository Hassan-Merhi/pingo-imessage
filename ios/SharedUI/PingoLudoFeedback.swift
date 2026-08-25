import AudioToolbox
import UIKit

@MainActor
enum PingoLudoFeedback {
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

    static func moveSubmitted(isPass: Bool) {
        if isPass {
            lightImpact.impactOccurred(intensity: 0.42)
            AudioServicesPlaySystemSound(1103)
        } else {
            mediumImpact.impactOccurred(intensity: 0.72)
            AudioServicesPlaySystemSound(1104)
        }
        lightImpact.prepare()
        mediumImpact.prepare()
    }

    static func moveResolved(summary: String) {
        if summary.contains("piece") {
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
