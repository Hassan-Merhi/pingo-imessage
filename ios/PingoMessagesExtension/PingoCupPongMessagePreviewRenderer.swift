import PingoCore
import UIKit

@MainActor
enum PingoCupPongMessagePreviewRenderer {
    static func image(payload: PingoMessagePayload) -> UIImage {
        let size = CGSize(width: 640, height: 360)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1

        return UIGraphicsImageRenderer(size: size, format: format).image { renderer in
            let context = renderer.cgContext
            drawBackground(context: context, size: size)
            drawTable(context: context, size: size, payload: payload)
            drawFooter(size: size, payload: payload)
        }
    }

    private static func drawBackground(context: CGContext, size: CGSize) {
        let colors = [
            UIColor(red: 0.02, green: 0.08, blue: 0.13, alpha: 1).cgColor,
            UIColor(red: 0.025, green: 0.20, blue: 0.29, alpha: 1).cgColor
        ] as CFArray
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
        let card = UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 34)
        card.addClip()
        context.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: size.width, y: size.height), options: [])
        UIColor.black.withAlphaComponent(0.22).setFill()
        context.fill(CGRect(x: 0, y: size.height - 92, width: size.width, height: 92))
    }

    private static func drawTable(context: CGContext, size: CGSize, payload: PingoMessagePayload) {
        let table = CGRect(x: 66, y: 28, width: size.width - 132, height: 238)
        let tablePath = UIBezierPath(roundedRect: table, cornerRadius: 28)
        context.saveGState()
        context.setShadow(offset: CGSize(width: 0, height: 8), blur: 16, color: UIColor.black.withAlphaComponent(0.45).cgColor)
        UIColor(red: 0.03, green: 0.31, blue: 0.46, alpha: 1).setFill()
        tablePath.fill()
        context.restoreGState()

        UIColor.white.withAlphaComponent(0.15).setStroke()
        tablePath.lineWidth = 3
        tablePath.stroke()

        UIColor.white.withAlphaComponent(0.12).setFill()
        UIBezierPath(roundedRect: CGRect(x: table.minX + 38, y: table.midY - 1, width: table.width - 76, height: 2), cornerRadius: 1).fill()

        let state = (try? PingoPhysicsGameEngine.cupPongState(from: payload.match.gameState)) ?? PingoCupPongState()
        let localPlayerIndex = payload.match.players.firstIndex(where: { $0.id == payload.sender.id }) ?? 0
        let otherIndex = localPlayerIndex == 0 ? 1 : 0
        drawRack(context: context, cups: cups(state, index: otherIndex), center: CGPoint(x: table.midX, y: table.minY + 65), inverted: true)
        drawRack(context: context, cups: cups(state, index: localPlayerIndex), center: CGPoint(x: table.midX, y: table.maxY - 60), inverted: false)

        drawBall(context: context, center: CGPoint(x: table.midX, y: table.midY + 26))
        drawStatusPill(context: context, payload: payload, state: state, table: table)
    }

    private static func drawRack(context: CGContext, cups: [Bool], center: CGPoint, inverted: Bool) {
        let positions = [
            CGPoint(x: -64, y: 18), CGPoint(x: 0, y: 18), CGPoint(x: 64, y: 18),
            CGPoint(x: -32, y: -10), CGPoint(x: 32, y: -10), CGPoint(x: 0, y: -38)
        ]

        for (index, offset) in positions.enumerated() {
            let active = cups.indices.contains(index) ? cups[index] : false
            let y = inverted ? -offset.y : offset.y
            let point = CGPoint(x: center.x + offset.x, y: center.y + y)
            drawCup(context: context, center: point, active: active)
        }
    }

    private static func drawCup(context: CGContext, center: CGPoint, active: Bool) {
        let alpha: CGFloat = active ? 1 : 0.18
        UIColor.black.withAlphaComponent(0.26 * alpha).setFill()
        context.fillEllipse(in: CGRect(x: center.x - 18, y: center.y + 11, width: 36, height: 10))

        let body = UIBezierPath()
        body.move(to: CGPoint(x: center.x - 17, y: center.y - 9))
        body.addLine(to: CGPoint(x: center.x + 17, y: center.y - 9))
        body.addLine(to: CGPoint(x: center.x + 12, y: center.y + 17))
        body.addLine(to: CGPoint(x: center.x - 12, y: center.y + 17))
        body.close()
        UIColor(red: 0.92, green: 0.08, blue: 0.13, alpha: alpha).setFill()
        body.fill()

        UIColor.white.withAlphaComponent(0.88 * alpha).setFill()
        context.fillEllipse(in: CGRect(x: center.x - 17, y: center.y - 13, width: 34, height: 10))
        UIColor(red: 0.26, green: 0.02, blue: 0.035, alpha: alpha).setFill()
        context.fillEllipse(in: CGRect(x: center.x - 13, y: center.y - 11, width: 26, height: 6))
    }

    private static func drawBall(context: CGContext, center: CGPoint) {
        context.saveGState()
        context.setShadow(offset: CGSize(width: 0, height: 3), blur: 4, color: UIColor.black.withAlphaComponent(0.35).cgColor)
        UIColor.white.setFill()
        context.fillEllipse(in: CGRect(x: center.x - 13, y: center.y - 13, width: 26, height: 26))
        context.restoreGState()
    }

    private static func drawStatusPill(context: CGContext, payload: PingoMessagePayload, state: PingoCupPongState, table: CGRect) {
        let text: String
        switch payload.action {
        case .challenge: text = "CHALLENGE"
        case .accepted: text = "TABLE READY"
        case .turn: text = state.lastCup == nil ? "MISS • YOUR TURN" : "CUP SUNK • YOUR TURN"
        case .completed: text = "MATCH COMPLETE"
        case .resigned: text = "MATCH ENDED"
        case .rematch: text = "NEXT GAME"
        }

        let value = text as NSString
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13, weight: .heavy),
            .foregroundColor: UIColor.white
        ]
        let textSize = value.size(withAttributes: attrs)
        let pill = CGRect(x: table.midX - (textSize.width + 30) / 2, y: table.minY + 12, width: textSize.width + 30, height: 29)
        UIColor.black.withAlphaComponent(0.72).setFill()
        UIBezierPath(roundedRect: pill, cornerRadius: 14.5).fill()
        value.draw(at: CGPoint(x: pill.minX + 15, y: pill.minY + 6), withAttributes: attrs)
    }

    private static func drawFooter(size: CGSize, payload: PingoMessagePayload) {
        let title = "Cup Pong" as NSString
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
        case .accepted: return "THROW FIRST"
        case .turn: return "OPEN YOUR THROW"
        case .resigned: return "MATCH ENDED"
        case .completed: return "SEE RESULT"
        case .rematch: return "NEXT GAME"
        }
    }

    private static func cups(_ state: PingoCupPongState, index: Int) -> [Bool] {
        guard state.cups.indices.contains(index) else { return Array(repeating: false, count: 6) }
        return state.cups[index]
    }
}
