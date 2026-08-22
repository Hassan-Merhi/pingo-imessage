import PingoCore
import UIKit

@MainActor
enum PingoWordHuntMessagePreviewRenderer {
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
        let colors = [UIColor(red: 0.16, green: 0.52, blue: 0.86, alpha: 1).cgColor, UIColor(red: 0.05, green: 0.18, blue: 0.42, alpha: 1).cgColor] as CFArray
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
        UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 34).addClip()
        context.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: size.width, y: size.height), options: [])
        UIColor.black.withAlphaComponent(0.22).setFill()
        context.fill(CGRect(x: 0, y: size.height - 92, width: size.width, height: 92))
    }

    private static func drawBoard(context: CGContext, payload: PingoMessagePayload) {
        let state = (try? PingoExtraGameEngine.state(from: payload.match.gameState, gameID: .wordHunt, matchID: payload.match.id)) ?? PingoExtraGameState()
        let board = PingoExtraGameEngine.wordHuntBoard(for: state)
        let boardRect = CGRect(x: 48, y: 28, width: 246, height: 246)
        let gap: CGFloat = 7
        let tile = (boardRect.width - gap * 3) / 4
        UIColor.black.withAlphaComponent(0.22).setFill()
        UIBezierPath(roundedRect: boardRect.insetBy(dx: -12, dy: -12), cornerRadius: 26).fill()
        for index in 0..<min(16, board.letters.count) {
            let row = index / 4
            let column = index % 4
            let rect = CGRect(x: boardRect.minX + CGFloat(column) * (tile + gap), y: boardRect.minY + CGFloat(row) * (tile + gap), width: tile, height: tile)
            UIColor.white.withAlphaComponent(0.94).setFill()
            UIBezierPath(roundedRect: rect, cornerRadius: 12).fill()
            let letter = String(board.letters[index]).uppercased() as NSString
            let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 27, weight: .heavy), .foregroundColor: UIColor(red: 0.05, green: 0.20, blue: 0.42, alpha: 1)]
            let textSize = letter.size(withAttributes: attrs)
            letter.draw(at: CGPoint(x: rect.midX - textSize.width / 2, y: rect.midY - textSize.height / 2), withAttributes: attrs)
        }
        let senderIndex = payload.match.players.firstIndex(where: { $0.id == payload.sender.id }) ?? 0
        let opponentIndex = senderIndex == 0 ? 1 : 0
        let senderScore = value(state.scores, senderIndex)
        let opponentScore = value(state.scores, opponentIndex)
        let senderAttempts = value(state.attempts, senderIndex)
        ("BOARD \(state.challengeIndex + 1)" as NSString).draw(at: CGPoint(x: 340, y: 44), withAttributes: [.font: UIFont.systemFont(ofSize: 14, weight: .heavy), .foregroundColor: UIColor.white.withAlphaComponent(0.58)])
        ("\(senderScore)" as NSString).draw(at: CGPoint(x: 338, y: 72), withAttributes: [.font: UIFont.monospacedDigitSystemFont(ofSize: 54, weight: .heavy), .foregroundColor: UIColor.white])
        ("YOU" as NSString).draw(at: CGPoint(x: 444, y: 91), withAttributes: [.font: UIFont.systemFont(ofSize: 12, weight: .heavy), .foregroundColor: UIColor.white.withAlphaComponent(0.55)])
        ("\(opponentScore)" as NSString).draw(at: CGPoint(x: 338, y: 139), withAttributes: [.font: UIFont.monospacedDigitSystemFont(ofSize: 38, weight: .bold), .foregroundColor: UIColor.white.withAlphaComponent(0.78)])
        ("THEM" as NSString).draw(at: CGPoint(x: 444, y: 151), withAttributes: [.font: UIFont.systemFont(ofSize: 12, weight: .heavy), .foregroundColor: UIColor.white.withAlphaComponent(0.45)])
        let recent = state.usedWords.last?.uppercased() ?? "TRACE A WORD"
        (recent as NSString).draw(at: CGPoint(x: 338, y: 194), withAttributes: [.font: UIFont.systemFont(ofSize: 17, weight: .heavy), .foregroundColor: UIColor.white.withAlphaComponent(0.92)])
        ("WORD \(min(6, senderAttempts + 1))/6" as NSString).draw(at: CGPoint(x: 338, y: 220), withAttributes: [.font: UIFont.systemFont(ofSize: 12, weight: .bold), .foregroundColor: UIColor.white.withAlphaComponent(0.56)])
    }

    private static func drawFooter(size: CGSize, payload: PingoMessagePayload) {
        ("Word Hunt" as NSString).draw(at: CGPoint(x: 28, y: size.height - 77), withAttributes: [.font: UIFont.systemFont(ofSize: 28, weight: .bold), .foregroundColor: UIColor.white])
        let action = actionText(payload) as NSString
        let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 18, weight: .semibold), .foregroundColor: UIColor.white.withAlphaComponent(0.78)]
        let actionSize = action.size(withAttributes: attrs)
        action.draw(at: CGPoint(x: size.width - actionSize.width - 28, y: size.height - 70), withAttributes: attrs)
    }

    private static func actionText(_ payload: PingoMessagePayload) -> String {
        switch payload.action {
        case .challenge: return "TAP TO HUNT"
        case .accepted: return "BOARD READY"
        case .turn: return "FIND A WORD"
        case .completed: return "SEE RESULT"
        case .resigned: return "MATCH ENDED"
        case .rematch: return "NEXT BOARD"
        }
    }

    private static func value(_ values: [Int], _ index: Int) -> Int { values.indices.contains(index) ? values[index] : 0 }
}
