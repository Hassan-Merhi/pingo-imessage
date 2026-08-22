import PingoCore
import UIKit

@MainActor
enum PingoArcheryMessagePreviewRenderer {
    static func image(payload: PingoMessagePayload) -> UIImage {
        let size = CGSize(width: 640, height: 360)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1

        return UIGraphicsImageRenderer(size: size, format: format).image { renderer in
            let context = renderer.cgContext
            drawBackground(context: context, size: size)
            drawRange(context: context, payload: payload)
            drawFooter(size: size, payload: payload)
        }
    }

    private static func drawBackground(context: CGContext, size: CGSize) {
        let colors = [
            UIColor(red: 0.12, green: 0.28, blue: 0.18, alpha: 1).cgColor,
            UIColor(red: 0.05, green: 0.10, blue: 0.08, alpha: 1).cgColor
        ] as CFArray
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
        UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 34).addClip()
        context.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: size.width, y: size.height), options: [])
        UIColor.black.withAlphaComponent(0.24).setFill()
        context.fill(CGRect(x: 0, y: size.height - 92, width: size.width, height: 92))
    }

    private static func drawRange(context: CGContext, payload: PingoMessagePayload) {
        let state = (try? PingoExtraGameEngine.state(from: payload.match.gameState, gameID: .archery, matchID: payload.match.id)) ?? PingoExtraGameState()
        let center = CGPoint(x: 195, y: 142)
        let radii: [(CGFloat, UIColor)] = [
            (104, UIColor.white),
            (82, UIColor.black),
            (62, UIColor.systemBlue),
            (42, UIColor.systemRed),
            (22, UIColor.systemYellow)
        ]
        for (radius, color) in radii {
            color.setFill()
            context.fillEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
        }
        UIColor.black.withAlphaComponent(0.20).setStroke()
        context.setLineWidth(2)
        context.strokeEllipse(in: CGRect(x: center.x - 104, y: center.y - 104, width: 208, height: 208))

        let senderIndex = payload.match.players.firstIndex(where: { $0.id == payload.sender.id }) ?? 0
        let opponentIndex = senderIndex == 0 ? 1 : 0
        let senderScore = value(state.scores, senderIndex)
        let opponentScore = value(state.scores, opponentIndex)
        let senderAttempts = value(state.attempts, senderIndex)

        ("ARROW \(min(5, senderAttempts + 1))/5" as NSString).draw(at: CGPoint(x: 370, y: 52), withAttributes: [
            .font: UIFont.systemFont(ofSize: 16, weight: .heavy),
            .foregroundColor: UIColor.white.withAlphaComponent(0.58)
        ])
        ("\(senderScore)" as NSString).draw(at: CGPoint(x: 368, y: 80), withAttributes: [
            .font: UIFont.monospacedDigitSystemFont(ofSize: 56, weight: .heavy),
            .foregroundColor: UIColor.white
        ])
        ("YOU" as NSString).draw(at: CGPoint(x: 474, y: 100), withAttributes: [
            .font: UIFont.systemFont(ofSize: 12, weight: .heavy),
            .foregroundColor: UIColor.white.withAlphaComponent(0.55)
        ])
        ("\(opponentScore)" as NSString).draw(at: CGPoint(x: 368, y: 154), withAttributes: [
            .font: UIFont.monospacedDigitSystemFont(ofSize: 40, weight: .bold),
            .foregroundColor: UIColor.white.withAlphaComponent(0.78)
        ])
        ("THEM" as NSString).draw(at: CGPoint(x: 474, y: 166), withAttributes: [
            .font: UIFont.systemFont(ofSize: 12, weight: .heavy),
            .foregroundColor: UIColor.white.withAlphaComponent(0.45)
        ])

        let status: String
        switch payload.action {
        case .challenge: status = "ARCHERY CHALLENGE"
        case .accepted: status = "RANGE READY"
        case .turn: status = state.lastScore == 10 ? "BULLSEYE • YOUR ARROW" : "\(state.lastScore) PTS • YOUR ARROW"
        case .completed: status = "MATCH COMPLETE"
        case .resigned: status = "MATCH ENDED"
        case .rematch: status = "NEW MATCH"
        }
        drawPill(status, at: CGPoint(x: 364, y: 216))
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
        ("Archery" as NSString).draw(at: CGPoint(x: 28, y: size.height - 77), withAttributes: [
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
        case .challenge: return "TAP TO AIM"
        case .accepted: return "RANGE READY"
        case .turn: return "OPEN YOUR ARROW"
        case .completed: return "SEE RESULT"
        case .resigned: return "MATCH ENDED"
        case .rematch: return "NEXT MATCH"
        }
    }

    private static func value(_ values: [Int], _ index: Int) -> Int {
        values.indices.contains(index) ? values[index] : 0
    }
}
