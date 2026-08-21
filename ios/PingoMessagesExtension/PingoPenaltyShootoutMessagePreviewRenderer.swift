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
            UIColor(red: 0.03, green: 0.24, blue: 0.12, alpha: 1).cgColor,
            UIColor(red: 0.01, green: 0.10, blue: 0.08, alpha: 1).cgColor
        ] as CFArray
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
        let card = UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 34)
        card.addClip()
        context.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: size.width, y: size.height), options: [])
        UIColor.black.withAlphaComponent(0.24).setFill()
        context.fill(CGRect(x: 0, y: size.height - 92, width: size.width, height: 92))
    }

    private static func drawPitch(context: CGContext, payload: PingoMessagePayload) {
        let state = (try? PingoExtraGameEngine.state(from: payload.match.gameState, gameID: .penaltyShootout, matchID: payload.match.id)) ?? PingoExtraGameState()
        let pitch = CGRect(x: 36, y: 28, width: 322, height: 230)

        UIColor(red: 0.08, green: 0.47, blue: 0.22, alpha: 1).setFill()
        UIBezierPath(roundedRect: pitch, cornerRadius: 18).fill()

        UIColor.white.withAlphaComponent(0.24).setStroke()
        let stripePath = UIBezierPath()
        for y in stride(from: pitch.minY + 28, through: pitch.maxY - 10, by: 36) {
            stripePath.move(to: CGPoint(x: pitch.minX + 8, y: y))
            stripePath.addLine(to: CGPoint(x: pitch.maxX - 8, y: y))
        }
        stripePath.lineWidth = 1
        stripePath.stroke()

        let goal = CGRect(x: pitch.midX - 96, y: pitch.minY + 18, width: 192, height: 72)
        UIColor.white.withAlphaComponent(0.92).setStroke()
        let goalPath = UIBezierPath(rect: goal)
        goalPath.lineWidth = 4
        goalPath.stroke()

        UIColor.white.withAlphaComponent(0.15).setStroke()
        for x in stride(from: goal.minX + 16, through: goal.maxX - 8, by: 16) {
            let p = UIBezierPath()
            p.move(to: CGPoint(x: x, y: goal.minY))
            p.addLine(to: CGPoint(x: x, y: goal.maxY))
            p.lineWidth = 1
            p.stroke()
        }
        for y in stride(from: goal.minY + 14, through: goal.maxY - 8, by: 14) {
            let p = UIBezierPath()
            p.move(to: CGPoint(x: goal.minX, y: y))
            p.addLine(to: CGPoint(x: goal.maxX, y: y))
            p.lineWidth = 1
            p.stroke()
        }

        UIColor.systemBlue.withAlphaComponent(0.95).setFill()
        context.fillEllipse(in: CGRect(x: goal.midX - 10, y: goal.midY - 10, width: 20, height: 20))

        UIColor.white.setFill()
        context.fillEllipse(in: CGRect(x: pitch.midX - 16, y: pitch.maxY - 54, width: 32, height: 32))
        UIColor.black.withAlphaComponent(0.72).setFill()
        context.fillEllipse(in: CGRect(x: pitch.midX - 5, y: pitch.maxY - 43, width: 10, height: 10))

        drawScorePanel(payload: payload, state: state)
        drawStatusPill(payload: payload, state: state)
    }

    private static func drawScorePanel(payload: PingoMessagePayload, state: PingoExtraGameState) {
        let senderIndex = payload.match.players.firstIndex(where: { $0.id == payload.sender.id }) ?? 0
        let opponentIndex = senderIndex == 0 ? 1 : 0
        let senderScore = value(state.scores, senderIndex)
        let opponentScore = value(state.scores, opponentIndex)
        let senderAttempts = value(state.attempts, senderIndex)

        ("KICK \(min(5, senderAttempts + 1))/5" as NSString).draw(at: CGPoint(x: 392, y: 52), withAttributes: [
            .font: UIFont.systemFont(ofSize: 16, weight: .heavy),
            .foregroundColor: UIColor.white.withAlphaComponent(0.58)
        ])
        ("\(senderScore)" as NSString).draw(at: CGPoint(x: 388, y: 80), withAttributes: [
            .font: UIFont.monospacedDigitSystemFont(ofSize: 56, weight: .heavy),
            .foregroundColor: UIColor.white
        ])
        ("YOU" as NSString).draw(at: CGPoint(x: 492, y: 100), withAttributes: [
            .font: UIFont.systemFont(ofSize: 12, weight: .heavy),
            .foregroundColor: UIColor.white.withAlphaComponent(0.55)
        ])
        ("\(opponentScore)" as NSString).draw(at: CGPoint(x: 388, y: 154), withAttributes: [
            .font: UIFont.monospacedDigitSystemFont(ofSize: 40, weight: .bold),
            .foregroundColor: UIColor.white.withAlphaComponent(0.78)
        ])
        ("THEM" as NSString).draw(at: CGPoint(x: 492, y: 166), withAttributes: [
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
        let pill = CGRect(x: 382, y: 216, width: textSize.width + 30, height: 30)
        UIColor.black.withAlphaComponent(0.70).setFill()
        UIBezierPath(roundedRect: pill, cornerRadius: 15).fill()
        value.draw(at: CGPoint(x: pill.minX + 15, y: pill.minY + 6), withAttributes: attrs)
    }

    private static func drawFooter(size: CGSize, payload: PingoMessagePayload) {
        ("Penalty Shootout" as NSString).draw(at: CGPoint(x: 28, y: size.height - 77), withAttributes: [
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
        case .challenge: return "TAP TO SHOOT"
        case .accepted: return "PITCH READY"
        case .turn: return "YOUR KICK"
        case .resigned: return "MATCH ENDED"
        case .completed: return "SEE RESULT"
        case .rematch: return "NEXT SHOOTOUT"
        }
    }

    private static func value(_ values: [Int], _ index: Int) -> Int {
        values.indices.contains(index) ? values[index] : 0
    }
}
