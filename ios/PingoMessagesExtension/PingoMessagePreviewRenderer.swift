import PingoCore
import UIKit

@MainActor
enum PingoMessagePreviewRenderer {
    static func image(for game: PingoGameDescriptor, payload: PingoMessagePayload) -> UIImage {
        if game.id == .bowling {
            return PingoBowlingMessagePreviewRenderer.image(payload: payload)
        }
        if game.id == .penaltyShootout {
            return PingoPenaltyShootoutMessagePreviewRenderer.image(payload: payload)
        }
        if game.id == .archery {
            return PingoArcheryMessagePreviewRenderer.image(payload: payload)
        }
        if game.id == .airHockey {
            return PingoAirHockeyMessagePreviewRenderer.image(payload: payload)
        }

        let size = CGSize(width: 640, height: 360)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1

        return UIGraphicsImageRenderer(size: size, format: format).image { renderer in
            let context = renderer.cgContext
            drawBackground(in: context, size: size, game: game)
            if game.id == .eightBall {
                drawEightBallCard(in: context, size: size, payload: payload)
            } else {
                drawGameArtwork(in: context, size: size, game: game)
            }
            drawLabels(size: size, game: game, payload: payload)
        }
    }

    private static func drawBackground(in context: CGContext, size: CGSize, game: PingoGameDescriptor) {
        let colors = palette(for: game).map { $0.cgColor } as CFArray
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0, 1])

        context.saveGState()
        let path = UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 34)
        path.addClip()
        if let gradient {
            context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: size.width, y: size.height), options: [])
        }
        context.setFillColor(UIColor.black.withAlphaComponent(0.18).cgColor)
        context.fill(CGRect(x: 0, y: size.height - 92, width: size.width, height: 92))
        context.restoreGState()
    }

    private static func drawGameArtwork(in context: CGContext, size: CGSize, game: PingoGameDescriptor) {
        let emoji = game.symbol as NSString
        let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 126)]
        let emojiSize = emoji.size(withAttributes: attributes)
        emoji.draw(at: CGPoint(x: (size.width - emojiSize.width) / 2, y: 50), withAttributes: attributes)
    }

    private static func drawEightBallCard(in context: CGContext, size: CGSize, payload: PingoMessagePayload) {
        let tableRect = CGRect(x: 48, y: 30, width: size.width - 96, height: 238)
        let outerShadow = UIBezierPath(roundedRect: tableRect.offsetBy(dx: 0, dy: 8), cornerRadius: 28)
        UIColor.black.withAlphaComponent(0.24).setFill()
        outerShadow.fill()

        let rail = UIBezierPath(roundedRect: tableRect, cornerRadius: 28)
        UIColor(red: 0.24, green: 0.085, blue: 0.045, alpha: 1).setFill()
        rail.fill()

        let railHighlight = UIBezierPath(roundedRect: tableRect.insetBy(dx: 7, dy: 7), cornerRadius: 22)
        UIColor(red: 0.48, green: 0.22, blue: 0.10, alpha: 1).setStroke()
        railHighlight.lineWidth = 5
        railHighlight.stroke()

        let feltRect = tableRect.insetBy(dx: 25, dy: 25)
        let felt = UIBezierPath(roundedRect: feltRect, cornerRadius: 14)
        UIColor(red: 0.015, green: 0.43, blue: 0.38, alpha: 1).setFill()
        felt.fill()

        let pocketCenters = [CGPoint(x: feltRect.minX, y: feltRect.minY), CGPoint(x: feltRect.midX, y: feltRect.minY), CGPoint(x: feltRect.maxX, y: feltRect.minY), CGPoint(x: feltRect.minX, y: feltRect.maxY), CGPoint(x: feltRect.midX, y: feltRect.maxY), CGPoint(x: feltRect.maxX, y: feltRect.maxY)]
        for center in pocketCenters {
            UIColor.black.withAlphaComponent(0.42).setFill()
            context.fillEllipse(in: CGRect(x: center.x - 14, y: center.y - 14, width: 28, height: 28))
            UIColor.black.setFill()
            context.fillEllipse(in: CGRect(x: center.x - 10, y: center.y - 10, width: 20, height: 20))
        }

        let state = (try? PingoPhysicsGameEngine.eightBallState(from: payload.match.gameState)) ?? PingoEightBallState()
        let visibleBalls = state.balls.filter { !$0.pocketed }
        for ball in visibleBalls { drawPoolBall(ball.id, at: poolPoint(ball.position, in: feltRect), in: context) }

        if payload.match.status == .active, let cue = visibleBalls.first(where: { $0.id == 0 }) {
            let cuePoint = poolPoint(cue.position, in: feltRect)
            context.saveGState(); context.setStrokeColor(UIColor.white.withAlphaComponent(0.34).cgColor); context.setLineWidth(2); context.setLineDash(phase: 0, lengths: [8, 8]); context.move(to: cuePoint); context.addLine(to: CGPoint(x: min(feltRect.maxX - 8, cuePoint.x + 110), y: cuePoint.y)); context.strokePath(); context.restoreGState()
        }
        drawEightBallStatusPill(payload: payload, state: state, in: context, tableRect: tableRect)
    }

    private static func poolPoint(_ point: PingoVector2, in feltRect: CGRect) -> CGPoint { CGPoint(x: feltRect.minX + feltRect.width * CGFloat(point.x), y: feltRect.minY + feltRect.height * CGFloat(point.y)) }

    private static func drawPoolBall(_ id: Int, at center: CGPoint, in context: CGContext) {
        let diameter: CGFloat = id == 0 ? 17 : 16
        let rect = CGRect(x: center.x - diameter / 2, y: center.y - diameter / 2, width: diameter, height: diameter)
        let color = poolBallColor(id)
        context.saveGState(); context.setShadow(offset: CGSize(width: 1.5, height: 2), blur: 2.5, color: UIColor.black.withAlphaComponent(0.36).cgColor); color.setFill(); context.fillEllipse(in: rect); context.restoreGState()
        if id >= 9 { let stripe = CGRect(x: rect.minX + 1, y: rect.midY - 3.1, width: rect.width - 2, height: 6.2); UIColor.white.setFill(); UIBezierPath(roundedRect: stripe, cornerRadius: 3).fill() }
        if id != 0 {
            let badge = CGRect(x: center.x - 4.4, y: center.y - 4.4, width: 8.8, height: 8.8); (id == 8 ? UIColor.black : UIColor.white).setFill(); context.fillEllipse(in: badge)
            let number = "\(id)" as NSString
            number.draw(in: CGRect(x: center.x - 4, y: center.y - 3.8, width: 8, height: 8), withAttributes: [.font: UIFont.systemFont(ofSize: 5.2, weight: .heavy), .foregroundColor: id == 8 ? UIColor.white : UIColor.black, .paragraphStyle: centeredParagraphStyle()])
        }
        UIColor.white.withAlphaComponent(0.34).setFill(); context.fillEllipse(in: CGRect(x: rect.minX + 2.4, y: rect.minY + 2.2, width: 3.3, height: 3.3))
    }

    private static func drawEightBallStatusPill(payload: PingoMessagePayload, state: PingoEightBallState, in context: CGContext, tableRect: CGRect) {
        let title: String
        switch payload.match.status { case .awaitingOpponent: title = "CHALLENGE"; case .active: title = state.groups == [0, 0] ? "OPEN TABLE" : "8 BALL"; case .completed: title = "MATCH COMPLETE"; case .resigned: title = "MATCH ENDED"; case .draft: title = "PREPARING"; case .expired: title = "EXPIRED" }
        let text = title as NSString
        let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 13, weight: .heavy), .foregroundColor: UIColor.white]
        let textSize = text.size(withAttributes: attrs)
        let pill = CGRect(x: tableRect.midX - (textSize.width + 28) / 2, y: tableRect.minY + 13, width: textSize.width + 28, height: 28)
        UIColor.black.withAlphaComponent(0.66).setFill(); UIBezierPath(roundedRect: pill, cornerRadius: 14).fill(); text.draw(at: CGPoint(x: pill.minX + 14, y: pill.minY + 6), withAttributes: attrs)
    }

    private static func drawLabels(size: CGSize, game: PingoGameDescriptor, payload: PingoMessagePayload) {
        let title = game.name as NSString
        title.draw(at: CGPoint(x: 28, y: size.height - 77), withAttributes: [.font: UIFont.systemFont(ofSize: 30, weight: .bold), .foregroundColor: UIColor.white])
        let action = actionText(for: payload) as NSString
        let actionAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 19, weight: .semibold), .foregroundColor: UIColor.white.withAlphaComponent(0.78)]
        let actionSize = action.size(withAttributes: actionAttributes)
        action.draw(at: CGPoint(x: size.width - actionSize.width - 28, y: size.height - 70), withAttributes: actionAttributes)
    }

    private static func actionText(for payload: PingoMessagePayload) -> String {
        if payload.match.gameID == .eightBall {
            switch payload.action { case .challenge: return "TAP TO PLAY"; case .accepted: return "TABLE READY"; case .turn: return "OPEN YOUR TURN"; case .resigned: return "MATCH ENDED"; case .completed: return "SEE RESULT"; case .rematch: return "NEXT RACK" }
        }
        switch payload.action { case .challenge: return "LET'S PLAY"; case .accepted: return "READY"; case .turn: return "YOUR MOVE"; case .resigned: return "MATCH ENDED"; case .completed: return "RESULT"; case .rematch: return "NEXT GAME" }
    }

    private static func poolBallColor(_ id: Int) -> UIColor {
        switch id { case 0: return .white; case 1, 9: return .systemYellow; case 2, 10: return .systemBlue; case 3, 11: return .systemRed; case 4, 12: return .systemPurple; case 5, 13: return .systemOrange; case 6, 14: return .systemGreen; case 7, 15: return UIColor(red: 0.48, green: 0.10, blue: 0.10, alpha: 1); case 8: return .black; default: return .systemGray }
    }

    private static func centeredParagraphStyle() -> NSParagraphStyle { let style = NSMutableParagraphStyle(); style.alignment = .center; return style }

    private static func palette(for game: PingoGameDescriptor) -> [UIColor] {
        switch game.family {
        case .precision: return [UIColor(red: 0.02, green: 0.53, blue: 0.49, alpha: 1), UIColor(red: 0.01, green: 0.31, blue: 0.34, alpha: 1)]
        case .arcade: return [UIColor(red: 0.96, green: 0.34, blue: 0.25, alpha: 1), UIColor(red: 0.55, green: 0.14, blue: 0.36, alpha: 1)]
        case .strategy: return [UIColor(red: 0.12, green: 0.32, blue: 0.58, alpha: 1), UIColor(red: 0.06, green: 0.13, blue: 0.29, alpha: 1)]
        case .board: return [UIColor(red: 0.42, green: 0.34, blue: 0.80, alpha: 1), UIColor(red: 0.20, green: 0.17, blue: 0.48, alpha: 1)]
        case .party: return [UIColor(red: 0.88, green: 0.29, blue: 0.59, alpha: 1), UIColor(red: 0.43, green: 0.20, blue: 0.68, alpha: 1)]
        case .word: return [UIColor(red: 0.20, green: 0.61, blue: 0.87, alpha: 1), UIColor(red: 0.11, green: 0.35, blue: 0.64, alpha: 1)]
        case .cards: return [UIColor(red: 0.20, green: 0.58, blue: 0.35, alpha: 1), UIColor(red: 0.08, green: 0.31, blue: 0.18, alpha: 1)]
        case .racing: return [UIColor(red: 0.93, green: 0.55, blue: 0.10, alpha: 1), UIColor(red: 0.78, green: 0.20, blue: 0.12, alpha: 1)]
        }
    }
}
