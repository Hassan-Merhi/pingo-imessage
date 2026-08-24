import PingoCore
import UIKit

@MainActor
enum PingoTriviaMessagePreviewRenderer {
    static func image(payload: PingoMessagePayload) -> UIImage {
        let size = CGSize(width: 640, height: 360)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { renderer in
            let context = renderer.cgContext
            drawBackground(context: context, size: size)
            drawQuiz(context: context, payload: payload)
            drawFooter(size: size, payload: payload)
        }
    }

    private static func drawBackground(context: CGContext, size: CGSize) {
        let colors = [
            UIColor(red: 0.18, green: 0.39, blue: 0.91, alpha: 1).cgColor,
            UIColor(red: 0.10, green: 0.12, blue: 0.42, alpha: 1).cgColor
        ] as CFArray
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
        UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 34).addClip()
        context.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: size.width, y: size.height), options: [])
        UIColor.black.withAlphaComponent(0.20).setFill()
        context.fill(CGRect(x: 0, y: size.height - 92, width: size.width, height: 92))
    }

    private static func drawQuiz(context: CGContext, payload: PingoMessagePayload) {
        let state = (try? PingoExtraGameEngine.state(from: payload.match.gameState, gameID: .trivia, matchID: payload.match.id)) ?? PingoExtraGameState()
        let question = PingoExtraGameEngine.triviaQuestion(for: state)
        let senderIndex = payload.match.players.firstIndex(where: { $0.id == payload.sender.id }) ?? 0
        let opponentIndex = senderIndex == 0 ? 1 : 0
        let senderScore = value(state.scores, senderIndex)
        let opponentScore = value(state.scores, opponentIndex)
        let senderAttempts = value(state.attempts, senderIndex)

        let questionRect = CGRect(x: 34, y: 42, width: 352, height: 154)
        UIColor.white.withAlphaComponent(0.94).setFill()
        UIBezierPath(roundedRect: questionRect, cornerRadius: 22).fill()
        ("QUESTION \(state.attempts[0] + state.attempts[1] + 1)" as NSString).draw(
            at: CGPoint(x: 54, y: 58),
            withAttributes: [.font: UIFont.systemFont(ofSize: 13, weight: .heavy), .foregroundColor: UIColor(red: 0.18, green: 0.25, blue: 0.55, alpha: 1)]
        )
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
        (question.prompt as NSString).draw(
            in: CGRect(x: 54, y: 84, width: 312, height: 92),
            withAttributes: [.font: UIFont.systemFont(ofSize: 22, weight: .bold), .foregroundColor: UIColor.black, .paragraphStyle: paragraph]
        )

        ("\(senderScore)" as NSString).draw(at: CGPoint(x: 430, y: 56), withAttributes: [.font: UIFont.monospacedDigitSystemFont(ofSize: 54, weight: .heavy), .foregroundColor: UIColor.white])
        ("YOU" as NSString).draw(at: CGPoint(x: 538, y: 76), withAttributes: [.font: UIFont.systemFont(ofSize: 12, weight: .heavy), .foregroundColor: UIColor.white.withAlphaComponent(0.58)])
        ("\(opponentScore)" as NSString).draw(at: CGPoint(x: 430, y: 126), withAttributes: [.font: UIFont.monospacedDigitSystemFont(ofSize: 36, weight: .bold), .foregroundColor: UIColor.white.withAlphaComponent(0.78)])
        ("THEM" as NSString).draw(at: CGPoint(x: 538, y: 138), withAttributes: [.font: UIFont.systemFont(ofSize: 12, weight: .heavy), .foregroundColor: UIColor.white.withAlphaComponent(0.48)])
        let recent = state.lastSummary.isEmpty ? "CHOOSE THE BEST ANSWER" : state.lastSummary.uppercased()
        (recent as NSString).draw(at: CGPoint(x: 430, y: 188), withAttributes: [.font: UIFont.systemFont(ofSize: 15, weight: .heavy), .foregroundColor: UIColor.white.withAlphaComponent(0.92)])
        ("ANSWER \(senderAttempts + 1) OF 5" as NSString).draw(at: CGPoint(x: 430, y: 214), withAttributes: [.font: UIFont.systemFont(ofSize: 12, weight: .bold), .foregroundColor: UIColor.white.withAlphaComponent(0.56)])
    }

    private static func drawFooter(size: CGSize, payload: PingoMessagePayload) {
        ("Trivia" as NSString).draw(at: CGPoint(x: 28, y: size.height - 77), withAttributes: [.font: UIFont.systemFont(ofSize: 28, weight: .bold), .foregroundColor: UIColor.white])
        let action = actionText(payload) as NSString
        let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 18, weight: .semibold), .foregroundColor: UIColor.white.withAlphaComponent(0.78)]
        let actionSize = action.size(withAttributes: attrs)
        action.draw(at: CGPoint(x: size.width - actionSize.width - 28, y: size.height - 70), withAttributes: attrs)
    }

    private static func actionText(_ payload: PingoMessagePayload) -> String {
        switch payload.action {
        case .challenge: return "TAP TO QUIZ"
        case .accepted: return "QUIZ READY"
        case .turn: return "YOUR QUESTION"
        case .completed: return "SEE RESULT"
        case .resigned: return "MATCH ENDED"
        case .rematch: return "NEXT QUIZ"
        }
    }

    private static func value(_ values: [Int], _ index: Int) -> Int {
        values.indices.contains(index) ? values[index] : 0
    }
}
