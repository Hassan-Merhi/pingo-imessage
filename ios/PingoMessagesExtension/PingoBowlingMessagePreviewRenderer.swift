import PingoCore
import UIKit

@MainActor
enum PingoBowlingMessagePreviewRenderer {
    static func image(payload: PingoMessagePayload) -> UIImage {
        let size = CGSize(width: 640, height: 360)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1

        return UIGraphicsImageRenderer(size: size, format: format).image { renderer in
            let context = renderer.cgContext
            drawBackground(context: context, size: size)
            drawLane(context: context, payload: payload)
            drawFooter(size: size, payload: payload)
        }
    }

    private static func drawBackground(context: CGContext, size: CGSize) {
        let colors = [
            UIColor(red: 0.11, green: 0.08, blue: 0.18, alpha: 1).cgColor,
            UIColor(red: 0.31, green: 0.12, blue: 0.18, alpha: 1).cgColor
        ] as CFArray
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
        let card = UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 34)
        card.addClip()
        context.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: size.width, y: size.height), options: [])
        UIColor.black.withAlphaComponent(0.24).setFill()
        context.fill(CGRect(x: 0, y: size.height - 92, width: size.width, height: 92))
    }

    private static func drawLane(context: CGContext, payload: PingoMessagePayload) {
        let state = (try? PingoExtraGameEngine.state(from: payload.match.gameState, gameID: .bowling, matchID: payload.match.id)) ?? PingoExtraGameState()
        let lane = CGRect(x: 44, y: 32, width: 310, height: 224)

        UIColor(red: 0.82, green: 0.58, blue: 0.31, alpha: 1).setFill()
        UIBezierPath(roundedRect: lane, cornerRadius: 18).fill()

        UIColor.white.withAlphaComponent(0.16).setStroke()
        let boards = UIBezierPath()
        for x in stride(from: lane.minX + 18, through: lane.maxX - 18, by: 20) {
            boards.move(to: CGPoint(x: x, y: lane.minY + 8))
            boards.addLine(to: CGPoint(x: x, y: lane.maxY - 8))
        }
        boards.lineWidth = 1
        boards.stroke()

        UIColor.black.withAlphaComponent(0.55).setFill()
        UIBezierPath(roundedRect: CGRect(x: lane.minX - 12, y: lane.minY, width: 12, height: lane.height), cornerRadius: 6).fill()
        UIBezierPath(roundedRect: CGRect(x: lane.maxX, y: lane.minY, width: 12, height: lane.height), cornerRadius: 6).fill()

        drawPins(context: context, lane: lane, lastScore: state.lastScore)
        drawBall(context: context, lane: lane)
        drawScorePanel(payload: payload, state: state)
        drawStatusPill(payload: payload, state: state)
    }

    private static func drawPins(context: CGContext, lane: CGRect, lastScore: Int) {
        let rackCenter = CGPoint(x: lane.midX, y: lane.minY + 55)
        let offsets: [CGPoint] = [
            .init(x: 0, y: 0),
            .init(x: -12, y: 16), .init(x: 12, y: 16),
            .init(x: -24, y: 32), .init(x: 0, y: 32), .init(x: 24, y: 32),
            .init(x: -36, y: 48), .init(x: -12, y: 48), .init(x: 12, y: 48), .init(x: 36, y: 48)
        ]
        let standing = max(0, 10 - lastScore)
        for (index, offset) in offsets.enumerated() where index < standing || lastScore == 0 {
            let center = CGPoint(x: rackCenter.x + offset.x, y: rackCenter.y + offset.y)
            UIColor.white.setFill()
            UIBezierPath(ovalIn: CGRect(x: center.x - 5, y: center.y - 11, width: 10, height: 22)).fill()
            UIColor.systemRed.setFill()
            context.fill(CGRect(x: center.x - 4, y: center.y - 3, width: 8, height: 3))
        }
    }

    private static func drawBall(context: CGContext, lane: CGRect) {
        let center = CGPoint(x: lane.midX, y: lane.maxY - 46)
        context.saveGState()
        context.setShadow(offset: CGSize(width: 0, height: 5), blur: 8, color: UIColor.black.withAlphaComponent(0.42).cgColor)
        UIColor(red: 0.10, green: 0.12, blue: 0.18, alpha: 1).setFill()
        context.fillEllipse(in: CGRect(x: center.x - 18, y: center.y - 18, width: 36, height: 36))
        context.restoreGState()
        UIColor.white.withAlphaComponent(0.50).setFill()
        context.fillEllipse(in: CGRect(x: center.x - 6, y: center.y - 7, width: 4, height: 4))
        context.fillEllipse(in: CGRect(x: center.x + 1, y: center.y - 9, width: 4, height: 4))
        context.fillEllipse(in: CGRect(x: center.x - 1, y: center.y - 2, width: 4, height: 4))
    }

    private static func drawScorePanel(payload: PingoMessagePayload, state: PingoExtraGameState) {
        let senderIndex = payload.match.players.firstIndex(where: { $0.id == payload.sender.id }) ?? 0
        let opponentIndex = senderIndex == 0 ? 1 : 0
        let senderScore = value(state.scores, senderIndex)
        let opponentScore = value(state.scores, opponentIndex)
        let senderAttempts = value(state.attempts, senderIndex)

        ("FRAME \(min(5, senderAttempts + 1))/5" as NSString).draw(at: CGPoint(x: 388, y: 55), withAttributes: [
            .font: UIFont.systemFont(ofSize: 17, weight: .heavy),
            .foregroundColor: UIColor.white.withAlphaComponent(0.58)
        ])
        ("\(senderScore)" as NSString).draw(at: CGPoint(x: 384, y: 83), withAttributes: [
            .font: UIFont.monospacedDigitSystemFont(ofSize: 54, weight: .heavy),
            .foregroundColor: UIColor.white
        ])
        ("YOU" as NSString).draw(at: CGPoint(x: 494, y: 100), withAttributes: [
            .font: UIFont.systemFont(ofSize: 12, weight: .heavy),
            .foregroundColor: UIColor.white.withAlphaComponent(0.55)
        ])
        ("\(opponentScore)" as NSString).draw(at: CGPoint(x: 384, y: 156), withAttributes: [
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
        case .challenge: text = "BOWLING CHALLENGE"
        case .accepted: text = "LANE READY"
        case .turn: text = state.lastScore == 10 ? "STRIKE • YOUR ROLL" : "\(state.lastScore) PINS • YOUR ROLL"
        case .completed: text = "MATCH COMPLETE"
        case .resigned: text = "MATCH ENDED"
        case .rematch: text = "NEW GAME"
        }

        let value = text as NSString
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13, weight: .heavy),
            .foregroundColor: UIColor.white
        ]
        let textSize = value.size(withAttributes: attrs)
        let pill = CGRect(x: 382, y: 218, width: textSize.width + 30, height: 30)
        UIColor.black.withAlphaComponent(0.70).setFill()
        UIBezierPath(roundedRect: pill, cornerRadius: 15).fill()
        value.draw(at: CGPoint(x: pill.minX + 15, y: pill.minY + 6), withAttributes: attrs)
    }

    private static func drawFooter(size: CGSize, payload: PingoMessagePayload) {
        ("Bowling" as NSString).draw(at: CGPoint(x: 28, y: size.height - 77), withAttributes: [
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
        case .challenge: return "TAP TO BOWL"
        case .accepted: return "ROLL FIRST"
        case .turn: return "OPEN YOUR ROLL"
        case .resigned: return "MATCH ENDED"
        case .completed: return "SEE RESULT"
        case .rematch: return "NEXT GAME"
        }
    }

    private static func value(_ values: [Int], _ index: Int) -> Int {
        values.indices.contains(index) ? values[index] : 0
    }
}
