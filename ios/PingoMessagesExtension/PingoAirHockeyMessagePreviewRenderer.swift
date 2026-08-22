import PingoCore
import UIKit

@MainActor
enum PingoAirHockeyMessagePreviewRenderer {
    static func image(payload: PingoMessagePayload) -> UIImage {
        let size = CGSize(width: 640, height: 360)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1

        return UIGraphicsImageRenderer(size: size, format: format).image { renderer in
            let context = renderer.cgContext
            drawBackground(context: context, size: size)
            drawTable(context: context, payload: payload)
            drawFooter(size: size, payload: payload)
        }
    }

    private static func drawBackground(context: CGContext, size: CGSize) {
        let colors = [
            UIColor(red: 0.04, green: 0.34, blue: 0.47, alpha: 1).cgColor,
            UIColor(red: 0.02, green: 0.10, blue: 0.16, alpha: 1).cgColor
        ] as CFArray
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
        UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 34).addClip()
        context.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: size.width, y: size.height), options: [])
        UIColor.black.withAlphaComponent(0.22).setFill()
        context.fill(CGRect(x: 0, y: size.height - 92, width: size.width, height: 92))
    }

    private static func drawTable(context: CGContext, payload: PingoMessagePayload) {
        let state = (try? PingoExtraGameEngine.state(from: payload.match.gameState, gameID: .airHockey, matchID: payload.match.id)) ?? PingoExtraGameState()
        let table = CGRect(x: 54, y: 34, width: 330, height: 230)

        UIColor.white.withAlphaComponent(0.10).setFill()
        UIBezierPath(roundedRect: table, cornerRadius: 24).fill()
        UIColor.white.withAlphaComponent(0.55).setStroke()
        let outline = UIBezierPath(roundedRect: table.insetBy(dx: 8, dy: 8), cornerRadius: 18)
        outline.lineWidth = 3
        outline.stroke()

        context.setStrokeColor(UIColor.white.withAlphaComponent(0.34).cgColor)
        context.setLineWidth(2)
        context.move(to: CGPoint(x: table.midX, y: table.minY + 12))
        context.addLine(to: CGPoint(x: table.midX, y: table.maxY - 12))
        context.strokePath()
        context.strokeEllipse(in: CGRect(x: table.midX - 30, y: table.midY - 30, width: 60, height: 60))

        let senderIndex = payload.match.players.firstIndex(where: { $0.id == payload.sender.id }) ?? 0
        let opponentIndex = senderIndex == 0 ? 1 : 0
        let senderScore = value(state.scores, senderIndex)
        let opponentScore = value(state.scores, opponentIndex)
        let senderAttempts = value(state.attempts, senderIndex)

        UIColor.systemBlue.setFill()
        context.fillEllipse(in: CGRect(x: table.minX + 74, y: table.midY - 24, width: 48, height: 48))
        UIColor.systemRed.setFill()
        context.fillEllipse(in: CGRect(x: table.maxX - 122, y: table.midY - 24, width: 48, height: 48))
        UIColor.black.withAlphaComponent(0.90).setFill()
        context.fillEllipse(in: CGRect(x: table.midX - 13, y: table.midY - 13, width: 26, height: 26))

        ("SHOT \(min(7, senderAttempts + 1))/7" as NSString).draw(at: CGPoint(x: 430, y: 52), withAttributes: [
            .font: UIFont.systemFont(ofSize: 16, weight: .heavy),
            .foregroundColor: UIColor.white.withAlphaComponent(0.58)
        ])
        ("\(senderScore)" as NSString).draw(at: CGPoint(x: 428, y: 80), withAttributes: [
            .font: UIFont.monospacedDigitSystemFont(ofSize: 56, weight: .heavy),
            .foregroundColor: UIColor.white
        ])
        ("YOU" as NSString).draw(at: CGPoint(x: 534, y: 100), withAttributes: [
            .font: UIFont.systemFont(ofSize: 12, weight: .heavy),
            .foregroundColor: UIColor.white.withAlphaComponent(0.55)
        ])
        ("\(opponentScore)" as NSString).draw(at: CGPoint(x: 428, y: 154), withAttributes: [
            .font: UIFont.monospacedDigitSystemFont(ofSize: 40, weight: .bold),
            .foregroundColor: UIColor.white.withAlphaComponent(0.78)
        ])
        ("THEM" as NSString).draw(at: CGPoint(x: 534, y: 166), withAttributes: [
            .font: UIFont.systemFont(ofSize: 12, weight: .heavy),
            .foregroundColor: UIColor.white.withAlphaComponent(0.45)
        ])

        let status: String
        switch payload.action {
        case .challenge: status = "AIR HOCKEY CHALLENGE"
        case .accepted: status = "TABLE READY"
        case .turn: status = state.lastScore == 1 ? "GOAL • YOUR SHOT" : "SAVE • YOUR SHOT"
        case .completed: status = "MATCH COMPLETE"
        case .resigned: status = "MATCH ENDED"
        case .rematch: status = "NEW MATCH"
        }
        drawPill(status, at: CGPoint(x: 424, y: 216))
    }

    private static func drawPill(_ text: String, at point: CGPoint) {
        let value = text as NSString
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13, weight: .heavy),
            .foregroundColor: UIColor.white
        ]
        let textSize = value.size(withAttributes: attrs)
        let pill = CGRect(x: point.x, y: point.y, width: textSize.width + 30, height: 30)
        UIColor.black.withAlphaComponent(0.70).setFill()
        UIBezierPath(roundedRect: pill, cornerRadius: 15).fill()
        value.draw(at: CGPoint(x: pill.minX + 15, y: pill.minY + 6), withAttributes: attrs)
    }

    private static func drawFooter(size: CGSize, payload: PingoMessagePayload) {
        ("Air Hockey" as NSString).draw(at: CGPoint(x: 28, y: size.height - 77), withAttributes: [
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
        case .challenge: return "TAP TO PLAY"
        case .accepted: return "TABLE READY"
        case .turn: return "OPEN YOUR SHOT"
        case .completed: return "SEE RESULT"
        case .resigned: return "MATCH ENDED"
        case .rematch: return "NEXT MATCH"
        }
    }

    private static func value(_ values: [Int], _ index: Int) -> Int {
        values.indices.contains(index) ? values[index] : 0
    }
}
