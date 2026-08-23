import PingoCore
import UIKit

@MainActor
enum PingoAnagramsMessagePreviewRenderer {
    static func image(payload: PingoMessagePayload) -> UIImage {
        let size = CGSize(width: 640, height: 360)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { renderer in
            let context = renderer.cgContext
            drawBackground(context: context, size: size)
            drawPuzzle(context: context, payload: payload)
            drawFooter(size: size, payload: payload)
        }
    }

    private static func drawBackground(context: CGContext, size: CGSize) {
        let colors = [UIColor(red: 0.98, green: 0.67, blue: 0.18, alpha: 1).cgColor, UIColor(red: 0.76, green: 0.31, blue: 0.08, alpha: 1).cgColor] as CFArray
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
        UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 34).addClip()
        context.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: size.width, y: size.height), options: [])
        UIColor.black.withAlphaComponent(0.20).setFill()
        context.fill(CGRect(x: 0, y: size.height - 92, width: size.width, height: 92))
    }

    private static func drawPuzzle(context: CGContext, payload: PingoMessagePayload) {
        let state = (try? PingoExtraGameEngine.state(from: payload.match.gameState, gameID: .anagrams, matchID: payload.match.id)) ?? PingoExtraGameState()
        let prompt = PingoExtraGameEngine.anagramPrompt(for: state).uppercased()
        let letters = Array(prompt)
        let rackRect = CGRect(x: 42, y: 70, width: 300, height: 92)
        let gap: CGFloat = 7
        let tileWidth = min(48, (rackRect.width - gap * CGFloat(max(0, letters.count - 1))) / CGFloat(max(1, letters.count)))
        let totalWidth = CGFloat(letters.count) * tileWidth + CGFloat(max(0, letters.count - 1)) * gap
        var x = rackRect.midX - totalWidth / 2
        for letter in letters {
            let rect = CGRect(x: x, y: rackRect.minY, width: tileWidth, height: 70)
            UIColor.white.withAlphaComponent(0.94).setFill()
            UIBezierPath(roundedRect: rect, cornerRadius: 12).fill()
            let text = String(letter) as NSString
            let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 25, weight: .heavy), .foregroundColor: UIColor(red: 0.42, green: 0.17, blue: 0.02, alpha: 1)]
            let textSize = text.size(withAttributes: attrs)
            text.draw(at: CGPoint(x: rect.midX - textSize.width / 2, y: rect.midY - textSize.height / 2), withAttributes: attrs)
            x += tileWidth + gap
        }

        let senderIndex = payload.match.players.firstIndex(where: { $0.id == payload.sender.id }) ?? 0
        let opponentIndex = senderIndex == 0 ? 1 : 0
        let senderScore = value(state.scores, senderIndex)
        let opponentScore = value(state.scores, opponentIndex)
        let senderAttempts = value(state.attempts, senderIndex)

        ("PUZZLE \(state.challengeIndex + 1)" as NSString).draw(at: CGPoint(x: 390, y: 44), withAttributes: [.font: UIFont.systemFont(ofSize: 14, weight: .heavy), .foregroundColor: UIColor.white.withAlphaComponent(0.62)])
        ("\(senderScore)" as NSString).draw(at: CGPoint(x: 386, y: 74), withAttributes: [.font: UIFont.monospacedDigitSystemFont(ofSize: 52, weight: .heavy), .foregroundColor: UIColor.white])
        ("YOU" as NSString).draw(at: CGPoint(x: 492, y: 92), withAttributes: [.font: UIFont.systemFont(ofSize: 12, weight: .heavy), .foregroundColor: UIColor.white.withAlphaComponent(0.56)])
        ("\(opponentScore)" as NSString).draw(at: CGPoint(x: 386, y: 140), withAttributes: [.font: UIFont.monospacedDigitSystemFont(ofSize: 36, weight: .bold), .foregroundColor: UIColor.white.withAlphaComponent(0.78)])
        ("THEM" as NSString).draw(at: CGPoint(x: 492, y: 151), withAttributes: [.font: UIFont.systemFont(ofSize: 12, weight: .heavy), .foregroundColor: UIColor.white.withAlphaComponent(0.46)])
        let recent = state.lastSummary.isEmpty ? "UNSCRAMBLE THE RACK" : state.lastSummary.uppercased()
        (recent as NSString).draw(at: CGPoint(x: 388, y: 196), withAttributes: [.font: UIFont.systemFont(ofSize: 16, weight: .heavy), .foregroundColor: UIColor.white.withAlphaComponent(0.92)])
        ("ATTEMPT \(senderAttempts + 1)" as NSString).draw(at: CGPoint(x: 388, y: 221), withAttributes: [.font: UIFont.systemFont(ofSize: 12, weight: .bold), .foregroundColor: UIColor.white.withAlphaComponent(0.56)])
    }

    private static func drawFooter(size: CGSize, payload: PingoMessagePayload) {
        ("Anagrams" as NSString).draw(at: CGPoint(x: 28, y: size.height - 77), withAttributes: [.font: UIFont.systemFont(ofSize: 28, weight: .bold), .foregroundColor: UIColor.white])
        let action = actionText(payload) as NSString
        let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 18, weight: .semibold), .foregroundColor: UIColor.white.withAlphaComponent(0.78)]
        let actionSize = action.size(withAttributes: attrs)
        action.draw(at: CGPoint(x: size.width - actionSize.width - 28, y: size.height - 70), withAttributes: attrs)
    }

    private static func actionText(_ payload: PingoMessagePayload) -> String {
        switch payload.action {
        case .challenge: return "TAP TO SOLVE"
        case .accepted: return "PUZZLE READY"
        case .turn: return "YOUR ANSWER"
        case .completed: return "SEE RESULT"
        case .resigned: return "MATCH ENDED"
        case .rematch: return "NEXT PUZZLE"
        }
    }

    private static func value(_ values: [Int], _ index: Int) -> Int { values.indices.contains(index) ? values[index] : 0 }
}
