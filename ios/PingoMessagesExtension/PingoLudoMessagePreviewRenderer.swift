import PingoCore
import UIKit

@MainActor
enum PingoLudoMessagePreviewRenderer {
    static func image(payload: PingoMessagePayload) -> UIImage {
        let size = CGSize(width: 640, height: 360)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { renderer in
            let context = renderer.cgContext
            drawBackground(context: context, size: size)
            drawBoard(context: context, payload: payload)
            drawFooter(size: size, payload: payload)
        }
    }

    private static func drawBackground(context: CGContext, size: CGSize) {
        let colors = [
            UIColor(red: 0.25, green: 0.20, blue: 0.62, alpha: 1).cgColor,
            UIColor(red: 0.10, green: 0.08, blue: 0.30, alpha: 1).cgColor
        ] as CFArray
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
        UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 34).addClip()
        context.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: size.width, y: size.height), options: [])
        UIColor.black.withAlphaComponent(0.20).setFill()
        context.fill(CGRect(x: 0, y: size.height - 92, width: size.width, height: 92))
    }

    private static func drawBoard(context: CGContext, payload: PingoMessagePayload) {
        let state = (try? PingoExtraGameEngine.state(from: payload.match.gameState, gameID: .ludo, matchID: payload.match.id)) ?? PingoExtraGameState()
        let senderIndex = payload.match.players.firstIndex(where: { $0.id == payload.sender.id }) ?? 0
        let opponentIndex = senderIndex == 0 ? 1 : 0
        let senderPieces = positions(state, senderIndex)
        let opponentPieces = positions(state, opponentIndex)
        let senderHome = senderPieces.filter { $0 >= 24 }.count
        let opponentHome = opponentPieces.filter { $0 >= 24 }.count
        let die = PingoExtraGameEngine.ludoDie(for: state)

        let board = CGRect(x: 34, y: 30, width: 300, height: 224)
        UIColor.black.withAlphaComponent(0.18).setFill()
        UIBezierPath(roundedRect: board.offsetBy(dx: 0, dy: 7), cornerRadius: 28).fill()
        UIColor(red: 0.91, green: 0.84, blue: 0.64, alpha: 1).setFill()
        UIBezierPath(roundedRect: board, cornerRadius: 28).fill()
        UIColor.white.withAlphaComponent(0.38).setStroke()
        let inner = UIBezierPath(roundedRect: board.insetBy(dx: 10, dy: 10), cornerRadius: 20)
        inner.lineWidth = 2
        inner.stroke()

        for index in 0..<24 {
            let point = trackPoint(index: index, board: board)
            let occupiedBySender = senderPieces.contains(index)
            let occupiedByOpponent = opponentPieces.contains(index)
            let fill = occupiedBySender
                ? UIColor(red: 0.21, green: 0.52, blue: 0.95, alpha: 1)
                : (occupiedByOpponent ? UIColor(red: 0.90, green: 0.22, blue: 0.25, alpha: 1) : UIColor.white.withAlphaComponent(0.76))
            fill.setFill()
            context.fillEllipse(in: CGRect(x: point.x - 8, y: point.y - 8, width: 16, height: 16))
        }

        let dieRect = CGRect(x: board.midX - 28, y: board.midY - 28, width: 56, height: 56)
        UIColor.white.withAlphaComponent(0.92).setFill()
        UIBezierPath(roundedRect: dieRect, cornerRadius: 14).fill()
        let dieText = "\(die)" as NSString
        dieText.draw(in: CGRect(x: dieRect.minX, y: dieRect.minY + 8, width: dieRect.width, height: 40), withAttributes: [
            .font: UIFont.monospacedDigitSystemFont(ofSize: 30, weight: .heavy),
            .foregroundColor: UIColor.black,
            .paragraphStyle: centeredParagraphStyle()
        ])

        ("\(senderHome)/2" as NSString).draw(at: CGPoint(x: 382, y: 58), withAttributes: [.font: UIFont.monospacedDigitSystemFont(ofSize: 48, weight: .heavy), .foregroundColor: UIColor.white])
        ("YOUR HOME" as NSString).draw(at: CGPoint(x: 490, y: 75), withAttributes: [.font: UIFont.systemFont(ofSize: 12, weight: .heavy), .foregroundColor: UIColor.white.withAlphaComponent(0.58)])
        ("\(opponentHome)/2" as NSString).draw(at: CGPoint(x: 382, y: 126), withAttributes: [.font: UIFont.monospacedDigitSystemFont(ofSize: 32, weight: .bold), .foregroundColor: UIColor.white.withAlphaComponent(0.78)])
        ("THEIR HOME" as NSString).draw(at: CGPoint(x: 490, y: 137), withAttributes: [.font: UIFont.systemFont(ofSize: 12, weight: .heavy), .foregroundColor: UIColor.white.withAlphaComponent(0.48)])

        let summary = state.lastSummary.isEmpty ? "ROLL • MOVE • RACE BOTH PIECES HOME" : state.lastSummary.uppercased()
        (summary as NSString).draw(in: CGRect(x: 382, y: 188, width: 220, height: 50), withAttributes: [.font: UIFont.systemFont(ofSize: 13, weight: .heavy), .foregroundColor: UIColor.white.withAlphaComponent(0.90)])
    }

    private static func drawFooter(size: CGSize, payload: PingoMessagePayload) {
        ("Ludo" as NSString).draw(at: CGPoint(x: 28, y: size.height - 77), withAttributes: [.font: UIFont.systemFont(ofSize: 30, weight: .bold), .foregroundColor: UIColor.white])
        let action = actionText(payload) as NSString
        let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 18, weight: .semibold), .foregroundColor: UIColor.white.withAlphaComponent(0.78)]
        let actionSize = action.size(withAttributes: attrs)
        action.draw(at: CGPoint(x: size.width - actionSize.width - 28, y: size.height - 70), withAttributes: attrs)
    }

    private static func actionText(_ payload: PingoMessagePayload) -> String {
        switch payload.action {
        case .challenge: return "TAP TO ROLL"
        case .accepted: return "BOARD READY"
        case .turn: return "YOUR MOVE"
        case .completed: return "SEE RESULT"
        case .resigned: return "MATCH ENDED"
        case .rematch: return "PLAY AGAIN"
        }
    }

    private static func positions(_ state: PingoExtraGameState, _ index: Int) -> [Int] {
        guard state.positions.indices.contains(index), state.positions[index].count == 2 else { return [-1, -1] }
        return state.positions[index]
    }

    private static func trackPoint(index: Int, board: CGRect) -> CGPoint {
        let normalized = CGFloat(index) / 24
        let angle = normalized * .pi * 2 - .pi / 2
        return CGPoint(
            x: board.midX + cos(angle) * board.width * 0.39,
            y: board.midY + sin(angle) * board.height * 0.39
        )
    }

    private static func centeredParagraphStyle() -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        return style
    }
}
