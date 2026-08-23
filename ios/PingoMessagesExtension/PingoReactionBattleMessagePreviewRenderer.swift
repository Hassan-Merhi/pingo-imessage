import PingoCore
import UIKit

@MainActor
enum PingoReactionBattleMessagePreviewRenderer {
    static func image(payload: PingoMessagePayload) -> UIImage {
        let size = CGSize(width: 640, height: 360)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { renderer in
            let context = renderer.cgContext
            drawBackground(context: context, size: size)
            drawArena(context: context, payload: payload)
            drawFooter(size: size, payload: payload)
        }
    }

    private static func drawBackground(context: CGContext, size: CGSize) {
        let colors = [
            UIColor(red: 0.98, green: 0.69, blue: 0.08, alpha: 1).cgColor,
            UIColor(red: 0.72, green: 0.20, blue: 0.08, alpha: 1).cgColor
        ] as CFArray
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
        UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 34).addClip()
        context.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: size.width, y: size.height), options: [])
        UIColor.black.withAlphaComponent(0.24).setFill()
        context.fill(CGRect(x: 0, y: size.height - 92, width: size.width, height: 92))
    }

    private static func drawArena(context: CGContext, payload: PingoMessagePayload) {
        let state = (try? PingoExtraGameEngine.state(from: payload.match.gameState, gameID: .reactionBattle, matchID: payload.match.id)) ?? PingoExtraGameState()
        let senderIndex = payload.match.players.firstIndex(where: { $0.id == payload.sender.id }) ?? 0
        let opponentIndex = senderIndex == 0 ? 1 : 0
        let senderScore = value(state.scores, senderIndex)
        let opponentScore = value(state.scores, opponentIndex)
        let run = min(5, value(state.attempts, senderIndex) + 1)

        let panel = CGRect(x: 40, y: 40, width: 355, height: 216)
        UIColor.black.withAlphaComponent(0.34).setFill()
        UIBezierPath(roundedRect: panel, cornerRadius: 24).fill()

        let signalCenter = CGPoint(x: panel.midX, y: panel.midY - 10)
        UIColor.black.withAlphaComponent(0.32).setFill()
        context.fillEllipse(in: CGRect(x: signalCenter.x - 70, y: signalCenter.y - 70, width: 140, height: 140))
        UIColor.systemYellow.setFill()
        context.fillEllipse(in: CGRect(x: signalCenter.x - 48, y: signalCenter.y - 48, width: 96, height: 96))
        UIColor.white.withAlphaComponent(0.42).setFill()
        context.fillEllipse(in: CGRect(x: signalCenter.x - 28, y: signalCenter.y - 34, width: 32, height: 24))

        ("RUN \(run)/5" as NSString).draw(at: CGPoint(x: 438, y: 52), withAttributes: [
            .font: UIFont.systemFont(ofSize: 16, weight: .heavy),
            .foregroundColor: UIColor.white.withAlphaComponent(0.62)
        ])
        ("\(senderScore)" as NSString).draw(at: CGPoint(x: 438, y: 82), withAttributes: [
            .font: UIFont.monospacedDigitSystemFont(ofSize: 50, weight: .heavy),
            .foregroundColor: UIColor.white
        ])
        ("YOU" as NSString).draw(at: CGPoint(x: 540, y: 103), withAttributes: [
            .font: UIFont.systemFont(ofSize: 12, weight: .heavy),
            .foregroundColor: UIColor.white.withAlphaComponent(0.55)
        ])
        ("\(opponentScore)" as NSString).draw(at: CGPoint(x: 438, y: 154), withAttributes: [
            .font: UIFont.monospacedDigitSystemFont(ofSize: 36, weight: .bold),
            .foregroundColor: UIColor.white.withAlphaComponent(0.82)
        ])
        ("THEM" as NSString).draw(at: CGPoint(x: 540, y: 169), withAttributes: [
            .font: UIFont.systemFont(ofSize: 12, weight: .heavy),
            .foregroundColor: UIColor.white.withAlphaComponent(0.46)
        ])
        drawPill(statusText(payload, state: state), at: CGPoint(x: 430, y: 216))
    }

    private static func statusText(_ payload: PingoMessagePayload, state: PingoExtraGameState) -> String {
        switch payload.action {
        case .challenge: return "REACTION CHALLENGE"
        case .accepted: return "ARENA READY"
        case .turn: return state.lastSummary.isEmpty ? "YOUR RUN" : state.lastSummary.uppercased()
        case .completed: return "BATTLE COMPLETE"
        case .resigned: return "BATTLE ENDED"
        case .rematch: return "NEW BATTLE"
        }
    }

    private static func drawPill(_ text: String, at point: CGPoint) {
        let value = text as NSString
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13, weight: .heavy),
            .foregroundColor: UIColor.white
        ]
        let textSize = value.size(withAttributes: attrs)
        let pill = CGRect(x: point.x, y: point.y, width: min(190, textSize.width + 30), height: 30)
        UIColor.black.withAlphaComponent(0.70).setFill()
        UIBezierPath(roundedRect: pill, cornerRadius: 15).fill()
        value.draw(at: CGPoint(x: pill.minX + 15, y: pill.minY + 6), withAttributes: attrs)
    }

    private static func drawFooter(size: CGSize, payload: PingoMessagePayload) {
        ("Reaction Battle" as NSString).draw(at: CGPoint(x: 28, y: size.height - 77), withAttributes: [
            .font: UIFont.systemFont(ofSize: 28, weight: .bold),
            .foregroundColor: UIColor.white
        ])
        let action = actionText(payload) as NSString
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold),
            .foregroundColor: UIColor.white.withAlphaComponent(0.78)
        ]
        let actionSize = action.size(withAttributes: attrs)
        action.draw(at: CGPoint(x: size.width - actionSize.width - 28, y: size.height - 70), withAttributes: attrs)
    }

    private static func actionText(_ payload: PingoMessagePayload) -> String {
        switch payload.action {
        case .challenge: return "TAP TO BATTLE"
        case .accepted: return "ARENA READY"
        case .turn: return "OPEN YOUR RUN"
        case .completed: return "SEE RESULT"
        case .resigned: return "BATTLE ENDED"
        case .rematch: return "NEXT BATTLE"
        }
    }

    private static func value(_ values: [Int], _ index: Int) -> Int {
        values.indices.contains(index) ? values[index] : 0
    }
}
