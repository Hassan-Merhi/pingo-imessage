import AudioToolbox
import UIKit

@MainActor
enum PingoBowlingFeedback {
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

    static func rollReleased() {
        mediumImpact.impactOccurred(intensity: 0.78)
        AudioServicesPlaySystemSound(1104)
        mediumImpact.prepare()
    }

    static func rollResolved(pins: Int) {
        if pins == 10 {
            notification.notificationOccurred(.success)
            heavyImpact.impactOccurred(intensity: 0.92)
            AudioServicesPlaySystemSound(1025)
        } else {
            mediumImpact.impactOccurred(intensity: pins >= 7 ? 0.76 : 0.50)
            AudioServicesPlaySystemSound(1105)
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
