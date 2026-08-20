import PingoCore
import UIKit

@MainActor
enum PingoDartsMessagePreviewRenderer {
    static func image(payload: PingoMessagePayload) -> UIImage {
        let size = CGSize(width: 640, height: 360)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1

        return UIGraphicsImageRenderer(size: size, format: format).image { renderer in
            let context = renderer.cgContext
            drawBackground(context: context, size: size)
            drawBoard(context: context, size: size, payload: payload)
            drawFooter(size: size, payload: payload)
        }
    }

    private static func drawBackground(context: CGContext, size: CGSize) {
        let colors = [
            UIColor(red: 0.035, green: 0.045, blue: 0.055, alpha: 1).cgColor,
            UIColor(red: 0.10, green: 0.12, blue: 0.14, alpha: 1).cgColor
        ] as CFArray
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
        let card = UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 34)
        card.addClip()
        context.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: size.width, y: size.height), options: [])
        UIColor.black.withAlphaComponent(0.24).setFill()
        context.fill(CGRect(x: 0, y: size.height - 92, width: size.width, height: 92))
    }

    private static func drawBoard(context: CGContext, size: CGSize, payload: PingoMessagePayload) {
        let center = CGPoint(x: 196, y: 148)
        let radius: CGFloat = 112

        context.saveGState()
        context.setShadow(offset: CGSize(width: 0, height: 8), blur: 18, color: UIColor.black.withAlphaComponent(0.5).cgColor)
        UIColor(red: 0.06, green: 0.065, blue: 0.07, alpha: 1).setFill()
        context.fillEllipse(in: CGRect(x: center.x - radius - 10, y: center.y - radius - 10, width: (radius + 10) * 2, height: (radius + 10) * 2))
        context.restoreGState()

        let sectorColors = [
            UIColor(red: 0.93, green: 0.88, blue: 0.72, alpha: 1),
            UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1)
        ]
        let accentColors = [
            UIColor(red: 0.74, green: 0.10, blue: 0.10, alpha: 1),
            UIColor(red: 0.08, green: 0.42, blue: 0.20, alpha: 1)
        ]

        for index in 0..<20 {
            let start = CGFloat(index) * (.pi / 10) - .pi / 2 - .pi / 20
            let end = start + .pi / 10
            drawWedge(context: context, center: center, inner: 0, outer: radius * 0.83, start: start, end: end, color: sectorColors[index % 2])
            drawWedge(context: context, center: center, inner: radius * 0.50, outer: radius * 0.59, start: start, end: end, color: accentColors[index % 2])
            drawWedge(context: context, center: center, inner: radius * 0.86, outer: radius, start: start, end: end, color: accentColors[index % 2])
        }

        UIColor(red: 0.08, green: 0.42, blue: 0.20, alpha: 1).setFill()
        context.fillEllipse(in: CGRect(x: center.x - radius * 0.11, y: center.y - radius * 0.11, width: radius * 0.22, height: radius * 0.22))
        UIColor(red: 0.74, green: 0.10, blue: 0.10, alpha: 1).setFill()
        context.fillEllipse(in: CGRect(x: center.x - radius * 0.055, y: center.y - radius * 0.055, width: radius * 0.11, height: radius * 0.11))

        let state = (try? PingoPhysicsGameEngine.dartsState(from: payload.match.gameState)) ?? PingoDartsState()
        drawScores(payload: payload, state: state)
        drawStatusPill(payload: payload, state: state)
    }

    private static func drawWedge(context: CGContext, center: CGPoint, inner: CGFloat, outer: CGFloat, start: CGFloat, end: CGFloat, color: UIColor) {
        let path = UIBezierPath()
        path.addArc(withCenter: center, radius: outer, startAngle: start, endAngle: end, clockwise: true)
        path.addArc(withCenter: center, radius: inner, startAngle: end, endAngle: start, clockwise: false)
        path.close()
        color.setFill()
        path.fill()
    }

    private static func drawScores(payload: PingoMessagePayload, state: PingoDartsState) {
        let senderIndex = payload.match.players.firstIndex(where: { $0.id == payload.sender.id }) ?? 0
        let opponentIndex = senderIndex == 0 ? 1 : 0
        let senderRemaining = state.remaining.indices.contains(senderIndex) ? state.remaining[senderIndex] : 301
        let opponentRemaining = state.remaining.indices.contains(opponentIndex) ? state.remaining[opponentIndex] : 301

        ("301" as NSString).draw(at: CGPoint(x: 358, y: 52), withAttributes: [
            .font: UIFont.systemFont(ofSize: 18, weight: .heavy),
            .foregroundColor: UIColor.white.withAlphaComponent(0.56)
        ])
        ("\(senderRemaining)" as NSString).draw(at: CGPoint(x: 354, y: 82), withAttributes: [
            .font: UIFont.monospacedDigitSystemFont(ofSize: 54, weight: .heavy),
            .foregroundColor: UIColor.white
        ])
        ("YOU" as NSString).draw(at: CGPoint(x: 468, y: 98), withAttributes: [
            .font: UIFont.systemFont(ofSize: 12, weight: .heavy),
            .foregroundColor: UIColor.white.withAlphaComponent(0.55)
        ])
        ("\(opponentRemaining)" as NSString).draw(at: CGPoint(x: 354, y: 154), withAttributes: [
            .font: UIFont.monospacedDigitSystemFont(ofSize: 38, weight: .bold),
            .foregroundColor: UIColor.white.withAlphaComponent(0.78)
        ])
        ("THEM" as NSString).draw(at: CGPoint(x: 468, y: 164), withAttributes: [
            .font: UIFont.systemFont(ofSize: 12, weight: .heavy),
            .foregroundColor: UIColor.white.withAlphaComponent(0.45)
        ])
    }

    private static func drawStatusPill(payload: PingoMessagePayload, state: PingoDartsState) {
        let text: String
        switch payload.action {
        case .challenge: text = "301 CHALLENGE"
        case .accepted: text = "OCHE READY"
        case .turn: text = state.lastVisitScore > 0 ? "VISIT \(state.lastVisitScore) • YOUR TURN" : "NO SCORE • YOUR TURN"
        case .completed: text = "CHECKOUT COMPLETE"
        case .resigned: text = "MATCH ENDED"
        case .rematch: text = "NEXT LEG"
        }

        let value = text as NSString
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13, weight: .heavy),
            .foregroundColor: UIColor.white
        ]
        let textSize = value.size(withAttributes: attrs)
        let pill = CGRect(x: 352, y: 218, width: textSize.width + 30, height: 30)
        UIColor.black.withAlphaComponent(0.72).setFill()
        UIBezierPath(roundedRect: pill, cornerRadius: 15).fill()
        value.draw(at: CGPoint(x: pill.minX + 15, y: pill.minY + 6), withAttributes: attrs)
    }

    private static func drawFooter(size: CGSize, payload: PingoMessagePayload) {
        ("Darts 301" as NSString).draw(at: CGPoint(x: 28, y: size.height - 77), withAttributes: [
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
        case .challenge: return "TAP TO PLAY"
        case .accepted: return "THROW FIRST"
        case .turn: return "OPEN YOUR VISIT"
        case .resigned: return "MATCH ENDED"
        case .completed: return "SEE RESULT"
        case .rematch: return "NEXT LEG"
        }
    }
}
