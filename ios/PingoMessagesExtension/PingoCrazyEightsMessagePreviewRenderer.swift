import PingoCore
import UIKit

@MainActor
enum PingoCrazyEightsMessagePreviewRenderer {
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
            UIColor(red: 0.08, green: 0.38, blue: 0.20, alpha: 1).cgColor,
            UIColor(red: 0.03, green: 0.16, blue: 0.10, alpha: 1).cgColor
        ] as CFArray
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
        UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 34).addClip()
        context.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: size.width, y: size.height), options: [])
        UIColor.black.withAlphaComponent(0.20).setFill()
        context.fill(CGRect(x: 0, y: size.height - 92, width: size.width, height: 92))
    }

    private static func drawTable(context: CGContext, payload: PingoMessagePayload) {
        let state = (try? PingoExtraGameEngine.state(from: payload.match.gameState, gameID: .crazyEights, matchID: payload.match.id)) ?? PingoExtraGameState()
        let senderIndex = payload.match.players.firstIndex(where: { $0.id == payload.sender.id }) ?? 0
        let opponentIndex = senderIndex == 0 ? 1 : 0
        let senderCount = value(state.hands, senderIndex).count
        let opponentCount = value(state.hands, opponentIndex).count

        let tableRect = CGRect(x: 32, y: 32, width: 374, height: 218)
        UIColor.black.withAlphaComponent(0.18).setFill()
        UIBezierPath(roundedRect: tableRect.offsetBy(dx: 0, dy: 7), cornerRadius: 28).fill()
        UIColor(red: 0.06, green: 0.47, blue: 0.25, alpha: 1).setFill()
        UIBezierPath(roundedRect: tableRect, cornerRadius: 28).fill()
        UIColor.white.withAlphaComponent(0.10).setStroke()
        let inner = UIBezierPath(roundedRect: tableRect.insetBy(dx: 10, dy: 10), cornerRadius: 21)
        inner.lineWidth = 2
        inner.stroke()

        drawCard(label: "DRAW", rect: CGRect(x: 86, y: 84, width: 82, height: 118), faceUp: false)
        drawCard(label: PingoExtraGameEngine.cardLabel(state.topCard), rect: CGRect(x: 242, y: 84, width: 82, height: 118), faceUp: true)

        ("DRAW" as NSString).draw(at: CGPoint(x: 101, y: 211), withAttributes: [.font: UIFont.systemFont(ofSize: 11, weight: .heavy), .foregroundColor: UIColor.white.withAlphaComponent(0.52)])
        ("TOP CARD" as NSString).draw(at: CGPoint(x: 250, y: 211), withAttributes: [.font: UIFont.systemFont(ofSize: 11, weight: .heavy), .foregroundColor: UIColor.white.withAlphaComponent(0.52)])

        ("\(senderCount)" as NSString).draw(at: CGPoint(x: 455, y: 57), withAttributes: [.font: UIFont.monospacedDigitSystemFont(ofSize: 54, weight: .heavy), .foregroundColor: UIColor.white])
        ("YOUR CARDS" as NSString).draw(at: CGPoint(x: 522, y: 77), withAttributes: [.font: UIFont.systemFont(ofSize: 12, weight: .heavy), .foregroundColor: UIColor.white.withAlphaComponent(0.58)])
        ("\(opponentCount)" as NSString).draw(at: CGPoint(x: 455, y: 130), withAttributes: [.font: UIFont.monospacedDigitSystemFont(ofSize: 36, weight: .bold), .foregroundColor: UIColor.white.withAlphaComponent(0.78)])
        ("THEIR CARDS" as NSString).draw(at: CGPoint(x: 522, y: 142), withAttributes: [.font: UIFont.systemFont(ofSize: 12, weight: .heavy), .foregroundColor: UIColor.white.withAlphaComponent(0.48)])
        let recent = state.lastSummary.isEmpty ? "MATCH SUIT OR RANK — EIGHTS ARE WILD" : state.lastSummary.uppercased()
        (recent as NSString).draw(in: CGRect(x: 455, y: 190, width: 156, height: 44), withAttributes: [.font: UIFont.systemFont(ofSize: 13, weight: .heavy), .foregroundColor: UIColor.white.withAlphaComponent(0.88)])
    }

    private static func drawCard(label: String, rect: CGRect, faceUp: Bool) {
        (faceUp ? UIColor.white : UIColor(red: 0.08, green: 0.18, blue: 0.38, alpha: 1)).setFill()
        UIBezierPath(roundedRect: rect, cornerRadius: 12).fill()
        UIColor.black.withAlphaComponent(faceUp ? 0.12 : 0.30).setStroke()
        let border = UIBezierPath(roundedRect: rect.insetBy(dx: 2, dy: 2), cornerRadius: 10)
        border.lineWidth = 2
        border.stroke()
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        (label as NSString).draw(in: CGRect(x: rect.minX + 5, y: rect.midY - 16, width: rect.width - 10, height: 34), withAttributes: [.font: UIFont.systemFont(ofSize: faceUp ? 24 : 13, weight: .heavy), .foregroundColor: faceUp ? UIColor.black : UIColor.white.withAlphaComponent(0.76), .paragraphStyle: paragraph])
    }

    private static func drawFooter(size: CGSize, payload: PingoMessagePayload) {
        ("Crazy Eights" as NSString).draw(at: CGPoint(x: 28, y: size.height - 77), withAttributes: [.font: UIFont.systemFont(ofSize: 28, weight: .bold), .foregroundColor: UIColor.white])
        let action = actionText(payload) as NSString
        let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 18, weight: .semibold), .foregroundColor: UIColor.white.withAlphaComponent(0.78)]
        let actionSize = action.size(withAttributes: attrs)
        action.draw(at: CGPoint(x: size.width - actionSize.width - 28, y: size.height - 70), withAttributes: attrs)
    }

    private static func actionText(_ payload: PingoMessagePayload) -> String {
        switch payload.action {
        case .challenge: return "TAP TO DEAL"
        case .accepted: return "TABLE READY"
        case .turn: return "YOUR PLAY"
        case .completed: return "SEE RESULT"
        case .resigned: return "MATCH ENDED"
        case .rematch: return "NEXT HAND"
        }
    }

    private static func value(_ values: [[Int]], _ index: Int) -> [Int] {
        values.indices.contains(index) ? values[index] : []
    }
}
