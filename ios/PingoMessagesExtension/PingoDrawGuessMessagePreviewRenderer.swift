import PingoCore
import UIKit

@MainActor
enum PingoDrawGuessMessagePreviewRenderer {
    static func image(payload: PingoMessagePayload) -> UIImage {
        let size = CGSize(width: 640, height: 360)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { renderer in
            let context = renderer.cgContext
            drawBackground(context: context, size: size)
            drawCanvas(context: context, payload: payload)
            drawFooter(size: size, payload: payload)
        }
    }

    private static func drawBackground(context: CGContext, size: CGSize) {
        let colors = [
            UIColor(red: 0.34, green: 0.20, blue: 0.72, alpha: 1).cgColor,
            UIColor(red: 0.88, green: 0.29, blue: 0.59, alpha: 1).cgColor
        ] as CFArray
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
        UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 34).addClip()
        context.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: size.width, y: size.height), options: [])
        UIColor.black.withAlphaComponent(0.22).setFill()
        context.fill(CGRect(x: 0, y: size.height - 92, width: size.width, height: 92))
    }

    private static func drawCanvas(context: CGContext, payload: PingoMessagePayload) {
        let state = (try? PingoExtraGameEngine.state(from: payload.match.gameState, gameID: .drawAndGuess, matchID: payload.match.id)) ?? PingoExtraGameState()
        let senderIndex = payload.match.players.firstIndex(where: { $0.id == payload.sender.id }) ?? 0
        let opponentIndex = senderIndex == 0 ? 1 : 0
        let canvas = CGRect(x: 38, y: 34, width: 370, height: 220)

        UIColor.white.withAlphaComponent(0.95).setFill()
        UIBezierPath(roundedRect: canvas, cornerRadius: 24).fill()
        UIColor.black.withAlphaComponent(0.08).setStroke()
        let inner = UIBezierPath(roundedRect: canvas.insetBy(dx: 12, dy: 12), cornerRadius: 15)
        inner.lineWidth = 2
        inner.stroke()

        if state.drawing.count >= 2 {
            context.saveGState()
            context.setStrokeColor(UIColor(red: 0.19, green: 0.17, blue: 0.30, alpha: 0.86).cgColor)
            context.setLineWidth(6)
            context.setLineCap(.round)
            context.setLineJoin(.round)
            let first = point(state.drawing[0], in: canvas)
            context.move(to: first)
            for raw in state.drawing.dropFirst() {
                context.addLine(to: point(raw, in: canvas))
            }
            context.strokePath()
            context.restoreGState()
        } else {
            let symbol = state.phase == 0 ? "✎" : "?"
            (symbol as NSString).draw(in: CGRect(x: canvas.midX - 52, y: canvas.midY - 58, width: 104, height: 104), withAttributes: [
                .font: UIFont.systemFont(ofSize: 84, weight: .bold),
                .foregroundColor: UIColor.black.withAlphaComponent(0.18),
                .paragraphStyle: centeredParagraphStyle()
            ])
        }

        let you = score(state.scores, senderIndex)
        let them = score(state.scores, opponentIndex)
        ("ROUND \(state.challengeIndex + 1)" as NSString).draw(at: CGPoint(x: 444, y: 48), withAttributes: [
            .font: UIFont.systemFont(ofSize: 15, weight: .heavy),
            .foregroundColor: UIColor.white.withAlphaComponent(0.58)
        ])
        ("\(you)" as NSString).draw(at: CGPoint(x: 444, y: 78), withAttributes: [
            .font: UIFont.monospacedDigitSystemFont(ofSize: 48, weight: .heavy),
            .foregroundColor: UIColor.white
        ])
        ("YOU" as NSString).draw(at: CGPoint(x: 540, y: 98), withAttributes: [
            .font: UIFont.systemFont(ofSize: 12, weight: .heavy),
            .foregroundColor: UIColor.white.withAlphaComponent(0.54)
        ])
        ("\(them)" as NSString).draw(at: CGPoint(x: 444, y: 148), withAttributes: [
            .font: UIFont.monospacedDigitSystemFont(ofSize: 34, weight: .bold),
            .foregroundColor: UIColor.white.withAlphaComponent(0.82)
        ])
        ("THEM" as NSString).draw(at: CGPoint(x: 540, y: 163), withAttributes: [
            .font: UIFont.systemFont(ofSize: 12, weight: .heavy),
            .foregroundColor: UIColor.white.withAlphaComponent(0.46)
        ])
        drawPill(statusText(payload, state: state), at: CGPoint(x: 432, y: 210))
    }

    private static func point(_ point: PingoExtraPoint, in canvas: CGRect) -> CGPoint {
        CGPoint(
            x: canvas.minX + CGFloat(point.x) / 1000 * canvas.width,
            y: canvas.minY + CGFloat(point.y) / 1000 * canvas.height
        )
    }

    private static func statusText(_ payload: PingoMessagePayload, state: PingoExtraGameState) -> String {
        switch payload.action {
        case .challenge: return "DRAW & GUESS CHALLENGE"
        case .accepted: return "CANVAS READY"
        case .turn:
            if !state.lastSummary.isEmpty { return state.lastSummary.uppercased() }
            return state.phase == 0 ? "YOUR DRAW" : "YOUR GUESS"
        case .completed: return "MATCH COMPLETE"
        case .resigned: return "MATCH ENDED"
        case .rematch: return "NEW CANVAS"
        }
    }

    private static func drawPill(_ text: String, at point: CGPoint) {
        let value = text as NSString
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .heavy),
            .foregroundColor: UIColor.white
        ]
        let textSize = value.size(withAttributes: attrs)
        let pill = CGRect(x: point.x, y: point.y, width: min(194, textSize.width + 26), height: 30)
        UIColor.black.withAlphaComponent(0.68).setFill()
        UIBezierPath(roundedRect: pill, cornerRadius: 15).fill()
        value.draw(at: CGPoint(x: pill.minX + 13, y: pill.minY + 6), withAttributes: attrs)
    }

    private static func drawFooter(size: CGSize, payload: PingoMessagePayload) {
        ("Draw & Guess" as NSString).draw(at: CGPoint(x: 28, y: size.height - 77), withAttributes: [
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
        case .accepted: return "CANVAS READY"
        case .turn: return "OPEN YOUR TURN"
        case .completed: return "SEE RESULT"
        case .resigned: return "MATCH ENDED"
        case .rematch: return "NEXT ROUND"
        }
    }

    private static func score(_ values: [Int], _ index: Int) -> Int {
        values.indices.contains(index) ? values[index] : 0
    }

    private static func centeredParagraphStyle() -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        return style
    }
}
