import PingoCore
import UIKit

@MainActor
enum PingoPenaltyShootoutMessagePreviewRenderer {
    static func image(payload: PingoMessagePayload) -> UIImage {
        let size = CGSize(width: 640, height: 360)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1

        return UIGraphicsImageRenderer(size: size, format: format).image { renderer in
            let context = renderer.cgContext
            drawBackground(context: context, size: size)
            drawPitch(context: context, payload: payload)
            drawFooter(size: size, payload: payload)
        }
    }

    private static func drawBackground(context: CGContext, size: CGSize) {
        let colors = [
            UIColor(red: 0.03, green: 0.28, blue: 0.18, alpha: 1).cgColor,
            UIColor(red: 0.02, green: 0.10, blue: 0.12, alpha: 1).cgColor
        ] as CFArray
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
        UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 34).addClip()
        context.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: size.width, y: size.height), options: [])
        UIColor.black.withAlphaComponent(0.24).setFill()
        context.fill(CGRect(x: 0, y: size.height - 92, width: size.width, height: 92))
    }

    private static func drawPitch(context: CGContext, payload: PingoMessagePayload) {
        let state = (try? PingoExtraGameEngine.state(from: payload.match.gameState, gameID: .penaltyShootout, matchID: payload.match.id)) ?? PingoExtraGameState()
        let pitch = CGRect(x: 38, y: 30, width: 330, height: 226)

        UIColor(red: 0.08, green: 0.48, blue: 0.24, alpha: 1).setFill()
        UIBezierPath(roundedRect: pitch, cornerRadius: 18).fill()

        UIColor.white.withAlphaComponent(0.48).setStroke()
        let markings = UIBezierPath()
        markings.append(UIBezierPath(rect: CGRect(x: pitch.minX + 54, y: pitch.minY + 18, width: pitch.width - 108, height: 78)))
        markings.move(to: CGPoint(x: pitch.midX, y: pitch.minY + 96))
        markings.addLine(to: CGPoint(x: pitch.midX, y: pitch.maxY - 24))
        markings.lineWidth = 2
        markings.stroke()

        let goal = CGRect(x: pitch.midX - 82, y: pitch.minY + 22, width: 164, height: 48)
        UIColor.white.withAlphaComponent(0.94).setStroke()
        let goalPath = UIBezierPath(rect: goal)
        goalPath.lineWidth = 5
        goalPath.stroke()

        UIColor.white.withAlphaComponent(0.28).setStroke()
        let net = UIBezierPath()
        for x in stride(from: goal.minX + 14, through: goal.maxX - 14, by: 18) {
            net.move(to: CGPoint(x: x, y: goal.minY))
            net.addLine(to: CGPoint(x: x, y: goal.maxY))
        }
        for y in stride(from: goal.minY + 12, through: goal.maxY - 8, by: 12) {
            net.move(to: CGPoint(x: goal.minX, y: y))
            net.addLine(to: CGPoint(x: goal.maxX, y: y))
        }
        net.lineWidth = 1
        net.stroke()

        let keeper = CGRect(x: goal.midX - 20, y: goal.maxY - 24, width: 40, height: 28)
        UIColor.systemBlue.setFill()
        UIBezierPath(roundedRect: keeper, cornerRadius: 8).fill()

        let ballCenter = CGPoint(x: pitch.midX, y: pitch.maxY - 43)
        UIColor.white.setFill()
        context.fillEllipse(in: CGRect(x: ballCenter.x - 15, y: ballCenter.y - 15, width: 30, height: 30))
        UIColor.black.withAlphaComponent(0.80).setFill()
        context.fillEllipse(in: CGRect(x: ballCenter.x - 4, y: ballCenter.y - 4, width: 8, height: 8))

        drawScorePanel(payload: payload, state: state)
        drawStatusPill(payload: payload, state: state)
    }

    private static func drawScorePanel(payload: PingoMessagePayload, state: PingoExtraGameState) {
        let senderIndex = payload.match.players.firstIndex(where: { $0.id == payload.sender.id }) ?? 0
        let opponentIndex = senderIndex == 0 ? 1 : 0
        let senderScore = value(state.scores, senderIndex)
        let opponentScore = value(state.scores, opponentIndex)
        let senderAttempts = value(state.attempts, senderIndex)

        ("KICK \(min(5, senderAttempts + 1))/5" as NSString).draw(at: CGPoint(x: 398, y: 54), withAttributes: [
            .font: UIFont.systemFont(ofSize: 17, weight: .heavy),
            .foregroundColor: UIColor.white.withAlphaComponent(0.58)
        ])
        ("\(senderScore)" as NSString).draw(at: CGPoint(x: 394, y: 83), withAttributes: [
            .font: UIFont.monospacedDigitSystemFont(ofSize: 54, weight: .heavy),
            .foregroundColor: UIColor.white
        ])
        ("YOU" as NSString).draw(at: CGPoint(x: 494, y: 100), withAttributes: [
            .font: UIFont.systemFont(ofSize: 12, weight: .heavy),
            .foregroundColor: UIColor.white.withAlphaComponent(0.55)
        ])
        ("\(opponentScore)" as NSString).draw(at: CGPoint(x: 394, y: 156), withAttributes: [
            .font: UIFont.monospacedDigitSystemFont(ofSize: 38, weight: .bold),
            .foregroundColor: UIColor.white.withAlphaComponent(0.78)
        ])
        ("THEM" as NSString).draw(at: CGPoint(x: 494, y: 166), withAttributes: [
            .font: UIFont.systemFont(ofSize: 12, weight: .heavy),
            .foregroundColor: UIColor.white.withAlphaComponent(0.45)
        ])
    }

    private static func drawStatusPill(payload: PingoMessagePayload, state: PingoExtraGameState) {
        let text: String
        switch payload.action {
        case .challenge: text = "PENALTY CHALLENGE"
        case .accepted: text = "SHOOTOUT READY"
        case .turn: text = state.lastScore > 0 ? "GOAL • YOUR KICK" : "SAVED • YOUR KICK"
        case .completed: text = "SHOOTOUT COMPLETE"
        case .resigned: text = "MATCH ENDED"
        case .rematch: text = "NEW SHOOTOUT"
        }

        let value = text as NSString
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13, weight: .heavy),
            .foregroundColor: UIColor.white
        ]
        let textSize = value.size(withAttributes: attrs)
        let pill = CGRect(x: 390, y: 218, width: textSize.width + 30, height: 30)
        UIColor.black.withAlphaComponent(0.70).setFill()
        UIBezierPath(roundedRect: pill, cornerRadius: 15).fill()
        value.draw(at: CGPoint(x: pill.minX + 15, y: pill.minY + 6), withAttributes: attrs)
    }

    private static func drawFooter(size: CGSize, payload: PingoMessagePayload) {
        ("Penalty Shootout" as NSString).draw(at: CGPoint(x: 28, y: size.height - 77), withAttributes: [
            .font: UIFont.systemFont(ofSize: 30, weight: .bold),
            .foregroundColor: UIColor.white
        ])

        let action = actionText(payload) as NSString
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 19, weight: .semibold),
            .foregroundColor: UIColor.white.withAlphaComponent(0.82)
        ]
        let actionSize = action.size(withAttributes: attrs)
        action.draw(at: CGPoint(x: size.width - actionSize.width - 28, y: size.height - 70), withAttributes: attrs)
    }

    private static func actionText(_ payload: PingoMessagePayload) -> String {
        switch payload.action {
        case .challenge: return "TAP TO SHOOT"
        case .accepted: return "KICK FIRST"
        case .turn: return "OPEN YOUR KICK"
        case .resigned: return "MATCH ENDED"
        case .completed: return "SEE RESULT"
        case .rematch: return "NEXT SHOOTOUT"
        }
    }

    private static func value(_ values: [Int], _ index: Int) -> Int {
        values.indices.contains(index) ? values[index] : 0
    }
}
