import PingoCore
import UIKit

@MainActor
enum PingoMessagePreviewRenderer {
    static func image(for game: PingoGameDescriptor, payload: PingoMessagePayload) -> UIImage {
        let size = CGSize(width: 640, height: 360)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1

        return UIGraphicsImageRenderer(size: size, format: format).image { renderer in
            let context = renderer.cgContext
            drawBackground(in: context, size: size, game: game)
            drawGameArtwork(in: context, size: size, game: game, payload: payload)
            drawLabels(size: size, game: game, payload: payload)
        }
    }

    private static func drawBackground(in context: CGContext, size: CGSize, game: PingoGameDescriptor) {
        let colors = palette(for: game).map(\.cgColor) as CFArray
        let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: colors,
            locations: [0, 1]
        )

        context.saveGState()
        UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 34).addClip()
        if let gradient {
            context.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: size.width, y: size.height),
                options: []
            )
        }
        context.setFillColor(UIColor.black.withAlphaComponent(0.19).cgColor)
        context.fill(CGRect(x: 0, y: size.height - 94, width: size.width, height: 94))
        context.restoreGState()
    }

    private static func drawGameArtwork(
        in context: CGContext,
        size: CGSize,
        game: PingoGameDescriptor,
        payload: PingoMessagePayload
    ) {
        if game.id == .eightBall {
            drawEightBallTable(in: context, size: size, payload: payload)
            return
        }

        let emoji = game.symbol as NSString
        let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 126)]
        let emojiSize = emoji.size(withAttributes: attributes)
        emoji.draw(
            at: CGPoint(x: (size.width - emojiSize.width) / 2, y: 50),
            withAttributes: attributes
        )
    }

    private static func drawEightBallTable(in context: CGContext, size: CGSize, payload: PingoMessagePayload) {
        let tableRect = CGRect(x: 58, y: 24, width: size.width - 116, height: 236)

        context.saveGState()
        context.setShadow(offset: CGSize(width: 0, height: 8), blur: 14, color: UIColor.black.withAlphaComponent(0.36).cgColor)
        UIColor(red: 0.22, green: 0.09, blue: 0.075, alpha: 1).setFill()
        UIBezierPath(roundedRect: tableRect, cornerRadius: 30).fill()
        context.restoreGState()

        let innerRail = tableRect.insetBy(dx: 9, dy: 9)
        UIColor(red: 0.47, green: 0.22, blue: 0.16, alpha: 1).setFill()
        UIBezierPath(roundedRect: innerRail, cornerRadius: 23).fill()

        let feltRect = tableRect.insetBy(dx: 25, dy: 25)
        UIColor(red: 0.015, green: 0.43, blue: 0.37, alpha: 1).setFill()
        UIBezierPath(roundedRect: feltRect, cornerRadius: 15).fill()

        UIColor.white.withAlphaComponent(0.08).setStroke()
        let feltStroke = UIBezierPath(roundedRect: feltRect.insetBy(dx: 2, dy: 2), cornerRadius: 13)
        feltStroke.lineWidth = 2
        feltStroke.stroke()

        let pocketCenters = [
            CGPoint(x: feltRect.minX, y: feltRect.minY),
            CGPoint(x: feltRect.midX, y: feltRect.minY - 1),
            CGPoint(x: feltRect.maxX, y: feltRect.minY),
            CGPoint(x: feltRect.minX, y: feltRect.maxY),
            CGPoint(x: feltRect.midX, y: feltRect.maxY + 1),
            CGPoint(x: feltRect.maxX, y: feltRect.maxY)
        ]
        UIColor.black.setFill()
        for center in pocketCenters {
            context.fillEllipse(in: CGRect(x: center.x - 12, y: center.y - 12, width: 24, height: 24))
        }

        let cueCenter = CGPoint(x: feltRect.minX + 102, y: feltRect.midY)
        drawAimLine(in: context, from: cueCenter, to: CGPoint(x: feltRect.midX + 58, y: feltRect.midY - 15))
        drawBall(in: context, center: cueCenter, radius: 11, color: .white, number: nil)

        let rackOrigin = CGPoint(x: feltRect.maxX - 132, y: feltRect.midY)
        let rack: [(UIColor, Int)] = [
            (.systemYellow, 1), (.systemBlue, 2), (.systemRed, 3), (.systemPurple, 4),
            (.black, 8), (.systemOrange, 5), (.systemGreen, 6), (.systemRed, 11),
            (.systemBlue, 10), (.systemYellow, 9), (.systemOrange, 13), (.systemPurple, 12),
            (.systemGreen, 14), (.systemRed, 7), (.systemBlue, 15)
        ]
        var rackIndex = 0
        for row in 0..<5 {
            for column in 0...row {
                let center = CGPoint(
                    x: rackOrigin.x + CGFloat(row) * 17,
                    y: rackOrigin.y + (CGFloat(column) - CGFloat(row) / 2) * 17
                )
                let item = rack[rackIndex]
                drawBall(in: context, center: center, radius: 8, color: item.0, number: item.1)
                rackIndex += 1
            }
        }

        drawEightBallStatusBadge(in: context, size: size, payload: payload)
    }

    private static func drawAimLine(in context: CGContext, from start: CGPoint, to end: CGPoint) {
        context.saveGState()
        context.setStrokeColor(UIColor.white.withAlphaComponent(0.48).cgColor)
        context.setLineWidth(2)
        context.setLineDash(phase: 0, lengths: [7, 7])
        context.move(to: start)
        context.addLine(to: end)
        context.strokePath()
        context.restoreGState()
    }

    private static func drawBall(
        in context: CGContext,
        center: CGPoint,
        radius: CGFloat,
        color: UIColor,
        number: Int?
    ) {
        let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        context.saveGState()
        context.setShadow(offset: CGSize(width: 0, height: 2), blur: 3, color: UIColor.black.withAlphaComponent(0.34).cgColor)
        color.setFill()
        context.fillEllipse(in: rect)
        context.restoreGState()

        guard let number else { return }
        let dotRadius = max(4, radius * 0.58)
        UIColor.white.setFill()
        context.fillEllipse(in: CGRect(x: center.x - dotRadius, y: center.y - dotRadius, width: dotRadius * 2, height: dotRadius * 2))
        let text = "\(number)" as NSString
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: max(6, radius * 0.9), weight: .bold),
            .foregroundColor: UIColor.black
        ]
        let textSize = text.size(withAttributes: attributes)
        text.draw(at: CGPoint(x: center.x - textSize.width / 2, y: center.y - textSize.height / 2), withAttributes: attributes)
    }

    private static func drawEightBallStatusBadge(in context: CGContext, size: CGSize, payload: PingoMessagePayload) {
        let text = eightBallStatus(for: payload) as NSString
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .heavy),
            .foregroundColor: UIColor.white
        ]
        let textSize = text.size(withAttributes: attributes)
        let badge = CGRect(x: size.width - textSize.width - 64, y: 40, width: textSize.width + 28, height: 32)
        UIColor.black.withAlphaComponent(0.66).setFill()
        UIBezierPath(roundedRect: badge, cornerRadius: 16).fill()
        text.draw(at: CGPoint(x: badge.minX + 14, y: badge.midY - textSize.height / 2), withAttributes: attributes)
    }

    private static func drawLabels(size: CGSize, game: PingoGameDescriptor, payload: PingoMessagePayload) {
        let title = (game.id == .eightBall ? "8 BALL" : game.name) as NSString
        title.draw(
            at: CGPoint(x: 28, y: size.height - 78),
            withAttributes: [
                .font: UIFont.systemFont(ofSize: 29, weight: .heavy),
                .foregroundColor: UIColor.white
            ]
        )

        let detail = detailText(for: payload, game: game) as NSString
        detail.draw(
            at: CGPoint(x: 29, y: size.height - 43),
            withAttributes: [
                .font: UIFont.systemFont(ofSize: 15, weight: .semibold),
                .foregroundColor: UIColor.white.withAlphaComponent(0.62)
            ]
        )

        let action = actionText(for: payload) as NSString
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18, weight: .bold),
            .foregroundColor: UIColor.white.withAlphaComponent(0.84)
        ]
        let actionSize = action.size(withAttributes: attributes)
        action.draw(
            at: CGPoint(x: size.width - actionSize.width - 28, y: size.height - 64),
            withAttributes: attributes
        )
    }

    private static func eightBallStatus(for payload: PingoMessagePayload) -> String {
        switch payload.action {
        case .challenge: return "CHALLENGE"
        case .accepted: return "BREAK READY"
        case .turn: return "SHOT \(payload.match.turnNumber + 1)"
        case .resigned: return "ENDED"
        case .completed: return "FINAL"
        case .rematch: return "REMATCH"
        }
    }

    private static func detailText(for payload: PingoMessagePayload, game: PingoGameDescriptor) -> String {
        guard game.id == .eightBall else { return "@\(payload.sender.username)" }
        switch payload.action {
        case .challenge: return "@\(payload.sender.username) wants to play"
        case .accepted: return "Table ready • take the first shot"
        case .turn: return "@\(payload.sender.username) sent the table back"
        case .resigned: return "Match ended"
        case .completed: return payload.match.series?.completed == true ? "Series complete" : "Match complete"
        case .rematch: return "New table ready"
        }
    }

    private static func actionText(for payload: PingoMessagePayload) -> String {
        switch payload.action {
        case .challenge: return "TAP TO PLAY"
        case .accepted: return "OPEN TABLE"
        case .turn: return "YOUR MOVE"
        case .resigned: return "VIEW RESULT"
        case .completed: return "VIEW RESULT"
        case .rematch: return "PLAY AGAIN"
        }
    }

    private static func palette(for game: PingoGameDescriptor) -> [UIColor] {
        switch game.family {
        case .precision:
            return [UIColor(red: 0.02, green: 0.53, blue: 0.49, alpha: 1), UIColor(red: 0.01, green: 0.31, blue: 0.34, alpha: 1)]
        case .arcade:
            return [UIColor(red: 0.96, green: 0.34, blue: 0.25, alpha: 1), UIColor(red: 0.55, green: 0.14, blue: 0.36, alpha: 1)]
        case .strategy:
            return [UIColor(red: 0.12, green: 0.32, blue: 0.58, alpha: 1), UIColor(red: 0.06, green: 0.13, blue: 0.29, alpha: 1)]
        case .board:
            return [UIColor(red: 0.42, green: 0.34, blue: 0.80, alpha: 1), UIColor(red: 0.20, green: 0.17, blue: 0.48, alpha: 1)]
        case .party:
            return [UIColor(red: 0.88, green: 0.29, blue: 0.59, alpha: 1), UIColor(red: 0.43, green: 0.20, blue: 0.68, alpha: 1)]
        case .word:
            return [UIColor(red: 0.20, green: 0.61, blue: 0.87, alpha: 1), UIColor(red: 0.11, green: 0.35, blue: 0.64, alpha: 1)]
        case .cards:
            return [UIColor(red: 0.20, green: 0.58, blue: 0.35, alpha: 1), UIColor(red: 0.08, green: 0.31, blue: 0.18, alpha: 1)]
        case .racing:
            return [UIColor(red: 0.93, green: 0.55, blue: 0.10, alpha: 1), UIColor(red: 0.78, green: 0.20, blue: 0.12, alpha: 1)]
        }
    }
}
