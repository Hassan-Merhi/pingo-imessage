import PingoCore
import UIKit

@MainActor
enum PingoBasketballMessagePreviewRenderer {
    static func image(payload: PingoMessagePayload) -> UIImage {
        let size = CGSize(width: 640, height: 360)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1

        return UIGraphicsImageRenderer(size: size, format: format).image { renderer in
            let context = renderer.cgContext
            drawBackground(context: context, size: size)
            drawCourt(context: context, size: size, payload: payload)
            drawFooter(size: size, payload: payload)
        }
    }

    private static func drawBackground(context: CGContext, size: CGSize) {
        let colors = [
            UIColor(red: 0.05, green: 0.06, blue: 0.09, alpha: 1).cgColor,
            UIColor(red: 0.24, green: 0.10, blue: 0.04, alpha: 1).cgColor
        ] as CFArray
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
        let card = UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 34)
        card.addClip()
        context.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: size.width, y: size.height), options: [])
        UIColor.black.withAlphaComponent(0.22).setFill()
        context.fill(CGRect(x: 0, y: size.height - 92, width: size.width, height: 92))
    }

    private static func drawCourt(context: CGContext, size: CGSize, payload: PingoMessagePayload) {
        let court = CGRect(x: 56, y: 28, width: size.width - 112, height: 238)
        let courtPath = UIBezierPath(roundedRect: court, cornerRadius: 28)
        context.saveGState()
        context.setShadow(offset: CGSize(width: 0, height: 8), blur: 16, color: UIColor.black.withAlphaComponent(0.45).cgColor)
        UIColor(red: 0.78, green: 0.37, blue: 0.12, alpha: 1).setFill()
        courtPath.fill()
        context.restoreGState()

        UIColor.white.withAlphaComponent(0.14).setStroke()
        courtPath.lineWidth = 3
        courtPath.stroke()

        UIColor.white.withAlphaComponent(0.16).setStroke()
        let arc = UIBezierPath(arcCenter: CGPoint(x: court.midX, y: court.maxY + 28), radius: 145, startAngle: .pi, endAngle: 2 * .pi, clockwise: true)
        arc.lineWidth = 4
        arc.stroke()

        drawHoop(context: context, court: court)
        drawBall(context: context, center: CGPoint(x: court.minX + 120, y: court.maxY - 58))

        let state = (try? PingoPhysicsGameEngine.basketballState(from: payload.match.gameState)) ?? PingoBasketballState()
        drawScore(context: context, payload: payload, state: state, court: court)
        drawStatusPill(context: context, payload: payload, state: state, court: court)
    }

    private static func drawHoop(context: CGContext, court: CGRect) {
        let backboard = CGRect(x: court.maxX - 142, y: court.minY + 40, width: 92, height: 66)
        UIColor.white.withAlphaComponent(0.88).setStroke()
        let board = UIBezierPath(roundedRect: backboard, cornerRadius: 5)
        board.lineWidth = 5
        board.stroke()

        UIColor.red.setStroke()
        let rim = UIBezierPath()
        rim.move(to: CGPoint(x: backboard.midX - 26, y: backboard.maxY + 8))
        rim.addLine(to: CGPoint(x: backboard.midX + 26, y: backboard.maxY + 8))
        rim.lineWidth = 6
        rim.stroke()

        UIColor.white.withAlphaComponent(0.52).setStroke()
        for offset in stride(from: -20.0, through: 20.0, by: 10.0) {
            let net = UIBezierPath()
            net.move(to: CGPoint(x: backboard.midX + offset, y: backboard.maxY + 11))
            net.addLine(to: CGPoint(x: backboard.midX + offset * 0.48, y: backboard.maxY + 44))
            net.lineWidth = 2
            net.stroke()
        }
    }

    private static func drawBall(context: CGContext, center: CGPoint) {
        context.saveGState()
        context.setShadow(offset: CGSize(width: 0, height: 3), blur: 5, color: UIColor.black.withAlphaComponent(0.4).cgColor)
        UIColor(red: 0.95, green: 0.42, blue: 0.08, alpha: 1).setFill()
        context.fillEllipse(in: CGRect(x: center.x - 25, y: center.y - 25, width: 50, height: 50))
        context.restoreGState()
        UIColor.black.withAlphaComponent(0.58).setStroke()
        let outer = UIBezierPath(ovalIn: CGRect(x: center.x - 25, y: center.y - 25, width: 50, height: 50))
        outer.lineWidth = 2
        outer.stroke()
        let seam = UIBezierPath()
        seam.move(to: CGPoint(x: center.x - 25, y: center.y))
        seam.addLine(to: CGPoint(x: center.x + 25, y: center.y))
        seam.move(to: CGPoint(x: center.x, y: center.y - 25))
        seam.addLine(to: CGPoint(x: center.x, y: center.y + 25))
        seam.lineWidth = 2
        seam.stroke()
    }

    private static func drawScore(context: CGContext, payload: PingoMessagePayload, state: PingoBasketballState, court: CGRect) {
        let senderIndex = payload.match.players.firstIndex(where: { $0.id == payload.sender.id }) ?? 0
        let opponentIndex = senderIndex == 0 ? 1 : 0
        let senderScore = state.scores.indices.contains(senderIndex) ? state.scores[senderIndex] : 0
        let opponentScore = state.scores.indices.contains(opponentIndex) ? state.scores[opponentIndex] : 0
        let text = "\(senderScore)  –  \(opponentScore)" as NSString
        text.draw(at: CGPoint(x: court.minX + 25, y: court.minY + 24), withAttributes: [
            .font: UIFont.monospacedDigitSystemFont(ofSize: 28, weight: .heavy),
            .foregroundColor: UIColor.white
        ])
    }

    private static func drawStatusPill(context: CGContext, payload: PingoMessagePayload, state: PingoBasketballState, court: CGRect) {
        let text: String
        switch payload.action {
        case .challenge: text = "CHALLENGE"
        case .accepted: text = "TIP-OFF READY"
        case .turn:
            text = state.lastPoints == 3 ? "SWISH +3 • YOUR SHOT" : state.lastPoints == 2 ? "BUCKET +2 • YOUR SHOT" : "MISS • YOUR SHOT"
        case .completed: text = "SHOOTOUT COMPLETE"
        case .resigned: text = "MATCH ENDED"
        case .rematch: text = "NEXT GAME"
        }

        let value = text as NSString
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13, weight: .heavy),
            .foregroundColor: UIColor.white
        ]
        let textSize = value.size(withAttributes: attrs)
        let pill = CGRect(x: court.midX - (textSize.width + 30) / 2, y: court.maxY - 43, width: textSize.width + 30, height: 29)
        UIColor.black.withAlphaComponent(0.72).setFill()
        UIBezierPath(roundedRect: pill, cornerRadius: 14.5).fill()
        value.draw(at: CGPoint(x: pill.minX + 15, y: pill.minY + 6), withAttributes: attrs)
    }

    private static func drawFooter(size: CGSize, payload: PingoMessagePayload) {
        let title = "Basketball" as NSString
        title.draw(at: CGPoint(x: 28, y: size.height - 77), withAttributes: [
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
        case .accepted: return "SHOOT FIRST"
        case .turn: return "OPEN YOUR SHOT"
        case .resigned: return "MATCH ENDED"
        case .completed: return "SEE RESULT"
        case .rematch: return "NEXT GAME"
        }
    }
}
