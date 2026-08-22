import AudioToolbox
import UIKit

@MainActor
enum PingoArcheryFeedback {
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

    static func arrowReleased() {
        mediumImpact.impactOccurred(intensity: 0.78)
        AudioServicesPlaySystemSound(1104)
        mediumImpact.prepare()
    }

    static func arrowResolved(score: Int) {
        switch score {
        case 10:
            notification.notificationOccurred(.success)
            heavyImpact.impactOccurred(intensity: 0.92)
            AudioServicesPlaySystemSound(1025)
        case 6...9:
            mediumImpact.impactOccurred(intensity: 0.70)
            AudioServicesPlaySystemSound(1103)
        case 1...5:
            lightImpact.impactOccurred(intensity: 0.56)
            AudioServicesPlaySystemSound(1105)
        default:
            notification.notificationOccurred(.warning)
            lightImpact.impactOccurred(intensity: 0.42)
            AudioServicesPlaySystemSound(1053)
        }
        lightImpact.prepare()
        mediumImpact.prepare()
        heavyImpact.prepare()
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
