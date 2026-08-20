import PingoCore
import UIKit

@MainActor
enum PingoMiniGolfMessagePreviewRenderer {
    static func image(payload: PingoMessagePayload) -> UIImage {
        let size = CGSize(width: 640, height: 360)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1

        return UIGraphicsImageRenderer(size: size, format: format).image { renderer in
            let context = renderer.cgContext
            drawBackground(context: context, size: size)
            drawCourse(context: context, payload: payload)
            drawFooter(size: size, payload: payload)
        }
    }

    private static func drawBackground(context: CGContext, size: CGSize) {
        let colors = [
            UIColor(red: 0.035, green: 0.18, blue: 0.10, alpha: 1).cgColor,
            UIColor(red: 0.08, green: 0.34, blue: 0.16, alpha: 1).cgColor
        ] as CFArray
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
        let card = UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 34)
        card.addClip()
        context.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: size.width, y: size.height), options: [])
        UIColor.black.withAlphaComponent(0.22).setFill()
        context.fill(CGRect(x: 0, y: size.height - 92, width: size.width, height: 92))
    }

    private static func drawCourse(context: CGContext, payload: PingoMessagePayload) {
        let state = (try? PingoPhysicsGameEngine.miniGolfState(from: payload.match.gameState)) ?? PingoMiniGolfState()
        let holeIndex = min(max(state.holeIndex, 0), PingoMiniGolf.course.count - 1)
        let course = PingoMiniGolf.course[holeIndex]
        let courseRect = CGRect(x: 34, y: 34, width: 300, height: 220)

        UIColor(red: 0.16, green: 0.48, blue: 0.23, alpha: 1).setFill()
        UIBezierPath(roundedRect: courseRect, cornerRadius: 34).fill()

        UIColor.white.withAlphaComponent(0.08).setStroke()
        let stripe = UIBezierPath()
        for y in stride(from: courseRect.minY + 20, through: courseRect.maxY - 20, by: 24) {
            stripe.move(to: CGPoint(x: courseRect.minX + 12, y: y))
            stripe.addLine(to: CGPoint(x: courseRect.maxX - 12, y: y))
        }
        stripe.lineWidth = 10
        stripe.stroke()

        for obstacle in course.obstacles {
            let rect = CGRect(
                x: courseRect.minX + CGFloat(obstacle.minX) * courseRect.width,
                y: courseRect.minY + CGFloat(obstacle.minY) * courseRect.height,
                width: CGFloat(obstacle.maxX - obstacle.minX) * courseRect.width,
                height: CGFloat(obstacle.maxY - obstacle.minY) * courseRect.height
            )
            UIColor(red: 0.35, green: 0.25, blue: 0.14, alpha: 1).setFill()
            UIBezierPath(roundedRect: rect, cornerRadius: 6).fill()
        }

        let cup = point(course.hole, in: courseRect)
        UIColor.black.withAlphaComponent(0.72).setFill()
        context.fillEllipse(in: CGRect(x: cup.x - 7, y: cup.y - 4, width: 14, height: 8))
        UIColor.white.setStroke()
        context.setLineWidth(3)
        context.move(to: CGPoint(x: cup.x, y: cup.y - 2))
        context.addLine(to: CGPoint(x: cup.x, y: cup.y - 42))
        context.strokePath()
        UIColor.systemRed.setFill()
        let flag = UIBezierPath()
        flag.move(to: CGPoint(x: cup.x + 1, y: cup.y - 41))
        flag.addLine(to: CGPoint(x: cup.x + 34, y: cup.y - 31))
        flag.addLine(to: CGPoint(x: cup.x + 1, y: cup.y - 22))
        flag.close()
        flag.fill()

        let senderIndex = payload.match.players.firstIndex(where: { $0.id == payload.sender.id }) ?? 0
        let opponentIndex = senderIndex == 0 ? 1 : 0
        drawBall(context: context, position: value(state.positions, senderIndex, fallback: course.start), in: courseRect, color: .white)
        drawBall(context: context, position: value(state.positions, opponentIndex, fallback: course.start), in: courseRect, color: UIColor.systemYellow.withAlphaComponent(0.94))

        drawScores(payload: payload, state: state, senderIndex: senderIndex, opponentIndex: opponentIndex)
        drawStatusPill(payload: payload, state: state)
    }

    private static func drawBall(context: CGContext, position: PingoVector2, in rect: CGRect, color: UIColor) {
        let center = point(position, in: rect)
        context.saveGState()
        context.setShadow(offset: CGSize(width: 0, height: 4), blur: 7, color: UIColor.black.withAlphaComponent(0.42).cgColor)
        color.setFill()
        context.fillEllipse(in: CGRect(x: center.x - 9, y: center.y - 9, width: 18, height: 18))
        context.restoreGState()
    }

    private static func drawScores(payload: PingoMessagePayload, state: PingoMiniGolfState, senderIndex: Int, opponentIndex: Int) {
        let senderTotal = value(state.totals, senderIndex) + value(state.holeStrokes, senderIndex)
        let opponentTotal = value(state.totals, opponentIndex) + value(state.holeStrokes, opponentIndex)
        let hole = min(max(state.holeIndex + 1, 1), PingoMiniGolf.course.count)

        ("HOLE \(hole)/\(PingoMiniGolf.course.count)" as NSString).draw(at: CGPoint(x: 368, y: 55), withAttributes: [
            .font: UIFont.systemFont(ofSize: 17, weight: .heavy),
            .foregroundColor: UIColor.white.withAlphaComponent(0.58)
        ])
        ("\(senderTotal)" as NSString).draw(at: CGPoint(x: 364, y: 83), withAttributes: [
            .font: UIFont.monospacedDigitSystemFont(ofSize: 54, weight: .heavy),
            .foregroundColor: UIColor.white
        ])
        ("YOU" as NSString).draw(at: CGPoint(x: 474, y: 100), withAttributes: [
            .font: UIFont.systemFont(ofSize: 12, weight: .heavy),
            .foregroundColor: UIColor.white.withAlphaComponent(0.55)
        ])
        ("\(opponentTotal)" as NSString).draw(at: CGPoint(x: 364, y: 156), withAttributes: [
            .font: UIFont.monospacedDigitSystemFont(ofSize: 38, weight: .bold),
            .foregroundColor: UIColor.white.withAlphaComponent(0.78)
        ])
        ("THEM" as NSString).draw(at: CGPoint(x: 474, y: 166), withAttributes: [
            .font: UIFont.systemFont(ofSize: 12, weight: .heavy),
            .foregroundColor: UIColor.white.withAlphaComponent(0.45)
        ])
    }

    private static func drawStatusPill(payload: PingoMessagePayload, state: PingoMiniGolfState) {
        let text: String
        switch payload.action {
        case .challenge: text = "MINI GOLF CHALLENGE"
        case .accepted: text = "TEE READY"
        case .turn: text = state.lastAutoFinished ? "STROKE LIMIT • YOUR PUTT" : "PUTT SENT • YOUR TURN"
        case .completed: text = "COURSE COMPLETE"
        case .resigned: text = "MATCH ENDED"
        case .rematch: text = "NEW ROUND"
        }

        let value = text as NSString
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13, weight: .heavy),
            .foregroundColor: UIColor.white
        ]
        let textSize = value.size(withAttributes: attrs)
        let pill = CGRect(x: 362, y: 218, width: textSize.width + 30, height: 30)
        UIColor.black.withAlphaComponent(0.70).setFill()
        UIBezierPath(roundedRect: pill, cornerRadius: 15).fill()
        value.draw(at: CGPoint(x: pill.minX + 15, y: pill.minY + 6), withAttributes: attrs)
    }

    private static func drawFooter(size: CGSize, payload: PingoMessagePayload) {
        ("Mini Golf" as NSString).draw(at: CGPoint(x: 28, y: size.height - 77), withAttributes: [
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
        case .accepted: return "PUTT FIRST"
        case .turn: return "OPEN YOUR PUTT"
        case .resigned: return "MATCH ENDED"
        case .completed: return "SEE RESULT"
        case .rematch: return "NEXT ROUND"
        }
    }

    private static func point(_ vector: PingoVector2, in rect: CGRect) -> CGPoint {
        CGPoint(x: rect.minX + CGFloat(vector.x) * rect.width, y: rect.minY + CGFloat(vector.y) * rect.height)
    }

    private static func value(_ values: [Int], _ index: Int) -> Int {
        values.indices.contains(index) ? values[index] : 0
    }

    private static func value(_ values: [PingoVector2], _ index: Int, fallback: PingoVector2) -> PingoVector2 {
        values.indices.contains(index) ? values[index] : fallback
    }
}
