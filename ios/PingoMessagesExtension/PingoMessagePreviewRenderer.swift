import PingoCore
import UIKit

enum PingoMessagePreviewRenderer {
    static func image(for game: PingoGameDescriptor, payload: PingoMessagePayload) -> UIImage {
        let size = CGSize(width: 640, height: 360)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1

        return UIGraphicsImageRenderer(size: size, format: format).image { renderer in
            let context = renderer.cgContext
            drawBackground(in: context, size: size, game: game)
            drawGameArtwork(in: context, size: size, game: game)
            drawLabels(size: size, game: game, payload: payload)
        }
    }

    private static func drawBackground(in context: CGContext, size: CGSize, game: PingoGameDescriptor) {
        let colors = palette(for: game).map { $0.cgColor } as CFArray
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let locations: [CGFloat] = [0, 1]
        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations)

        context.saveGState()
        let path = UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 34)
        path.addClip()
        if let gradient {
            context.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: size.width, y: size.height),
                options: []
            )
        }

        context.setFillColor(UIColor.black.withAlphaComponent(0.16).cgColor)
        context.fill(CGRect(x: 0, y: size.height - 92, width: size.width, height: 92))
        context.restoreGState()
    }

    private static func drawGameArtwork(in context: CGContext, size: CGSize, game: PingoGameDescriptor) {
        if game.id == .eightBall {
            drawEightBallTable(in: context, size: size)
            return
        }

        let emoji = game.symbol as NSString
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 126)
        ]
        let emojiSize = emoji.size(withAttributes: attributes)
        emoji.draw(
            at: CGPoint(x: (size.width - emojiSize.width) / 2, y: 50),
            withAttributes: attributes
        )
    }

    private static func drawEightBallTable(in context: CGContext, size: CGSize) {
        let tableRect = CGRect(x: 82, y: 38, width: size.width - 164, height: 214)
        let rail = UIBezierPath(roundedRect: tableRect, cornerRadius: 24)
        UIColor(red: 0.34, green: 0.15, blue: 0.13, alpha: 1).setFill()
        rail.fill()

        let feltRect = tableRect.insetBy(dx: 18, dy: 18)
        let felt = UIBezierPath(roundedRect: feltRect, cornerRadius: 15)
        UIColor(red: 0.02, green: 0.50, blue: 0.44, alpha: 1).setFill()
        felt.fill()

        let pocketCenters = [
            CGPoint(x: feltRect.minX, y: feltRect.minY),
            CGPoint(x: feltRect.midX, y: feltRect.minY),
            CGPoint(x: feltRect.maxX, y: feltRect.minY),
            CGPoint(x: feltRect.minX, y: feltRect.maxY),
            CGPoint(x: feltRect.midX, y: feltRect.maxY),
            CGPoint(x: feltRect.maxX, y: feltRect.maxY)
        ]
        UIColor.black.setFill()
        for center in pocketCenters {
            context.fillEllipse(in: CGRect(x: center.x - 10, y: center.y - 10, width: 20, height: 20))
        }

        UIColor.white.setFill()
        context.fillEllipse(in: CGRect(x: feltRect.minX + 72, y: feltRect.midY - 9, width: 18, height: 18))

        let rackOrigin = CGPoint(x: feltRect.maxX - 112, y: feltRect.midY - 35)
        let colors: [UIColor] = [.systemYellow, .systemBlue, .systemRed, .systemPurple, .systemOrange, .systemGreen, .black]
        var index = 0
        for row in 0..<5 {
            for column in 0...row {
                let x = rackOrigin.x + CGFloat(row) * 15
                let y = rackOrigin.y + CGFloat(column) * 15 - CGFloat(row) * 7.5
                colors[index % colors.count].setFill()
                context.fillEllipse(in: CGRect(x: x, y: y, width: 14, height: 14))
                index += 1
            }
        }
    }

    private static func drawLabels(size: CGSize, game: PingoGameDescriptor, payload: PingoMessagePayload) {
        let title = game.name as NSString
        title.draw(
            at: CGPoint(x: 28, y: size.height - 77),
            withAttributes: [
                .font: UIFont.systemFont(ofSize: 30, weight: .bold),
                .foregroundColor: UIColor.white
            ]
        )

        let action = actionText(for: payload) as NSString
        let actionAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 19, weight: .semibold),
            .foregroundColor: UIColor.white.withAlphaComponent(0.72)
        ]
        let actionSize = action.size(withAttributes: actionAttributes)
        action.draw(
            at: CGPoint(x: size.width - actionSize.width - 28, y: size.height - 70),
            withAttributes: actionAttributes
        )
    }

    private static func actionText(for payload: PingoMessagePayload) -> String {
        switch payload.action {
        case .challenge: return "LET'S PLAY"
        case .accepted: return "READY"
        case .turn: return "YOUR MOVE"
        case .resigned: return "MATCH ENDED"
        case .completed: return "RESULT"
        case .rematch: return "NEXT GAME"
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
