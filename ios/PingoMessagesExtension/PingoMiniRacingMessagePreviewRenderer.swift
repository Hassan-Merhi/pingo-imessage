import PingoCore
import UIKit

@MainActor
enum PingoMiniRacingMessagePreviewRenderer {
    static func image(payload: PingoMessagePayload) -> UIImage {
        let size = CGSize(width: 640, height: 360)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { renderer in
            let context = renderer.cgContext
            drawBackground(context: context, size: size)
            drawTrack(context: context, payload: payload)
            drawFooter(size: size, payload: payload)
        }
    }

    private static func drawBackground(context: CGContext, size: CGSize) {
        let colors = [UIColor(red: 0.95, green: 0.55, blue: 0.10, alpha: 1).cgColor, UIColor(red: 0.55, green: 0.08, blue: 0.08, alpha: 1).cgColor] as CFArray
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
        UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 34).addClip()
        context.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: size.width, y: size.height), options: [])
        UIColor.black.withAlphaComponent(0.22).setFill()
        context.fill(CGRect(x: 0, y: size.height - 92, width: size.width, height: 92))
    }

    private static func drawTrack(context: CGContext, payload: PingoMessagePayload) {
        let state = (try? PingoExtraGameEngine.state(from: payload.match.gameState, gameID: .miniRacing, matchID: payload.match.id)) ?? PingoExtraGameState()
        let senderIndex = payload.match.players.firstIndex(where: { $0.id == payload.sender.id }) ?? 0
        let opponentIndex = senderIndex == 0 ? 1 : 0
        let senderDistance = progress(state, senderIndex)
        let opponentDistance = progress(state, opponentIndex)
        let senderAttempts = value(state.attempts, senderIndex)

        let track = CGRect(x: 40, y: 42, width: 360, height: 214)
        UIColor.black.withAlphaComponent(0.34).setFill()
        UIBezierPath(roundedRect: track, cornerRadius: 22).fill()
        context.setStrokeColor(UIColor.white.withAlphaComponent(0.28).cgColor)
        context.setLineWidth(2)
        context.setLineDash(phase: 0, lengths: [16, 12])
        context.move(to: CGPoint(x: track.minX + 20, y: track.midY))
        context.addLine(to: CGPoint(x: track.maxX - 20, y: track.midY))
        context.strokePath()
        context.setLineDash(phase: 0, lengths: [])

        let finishX = track.maxX - 28
        context.setStrokeColor(UIColor.white.withAlphaComponent(0.92).cgColor)
        context.setLineWidth(4)
        context.move(to: CGPoint(x: finishX, y: track.minY + 12))
        context.addLine(to: CGPoint(x: finishX, y: track.maxY - 12))
        context.strokePath()

        drawCar(context: context, x: track.minX + 28 + CGFloat(senderDistance) / 100 * (track.width - 82), y: track.minY + 55, color: .systemBlue)
        drawCar(context: context, x: track.minX + 28 + CGFloat(opponentDistance) / 100 * (track.width - 82), y: track.minY + 145, color: .systemRed)

        ("RUN \(min(8, senderAttempts + 1))/8" as NSString).draw(at: CGPoint(x: 440, y: 52), withAttributes: [.font: UIFont.systemFont(ofSize: 16, weight: .heavy), .foregroundColor: UIColor.white.withAlphaComponent(0.60)])
        ("\(senderDistance)m" as NSString).draw(at: CGPoint(x: 438, y: 82), withAttributes: [.font: UIFont.monospacedDigitSystemFont(ofSize: 46, weight: .heavy), .foregroundColor: UIColor.white])
        ("YOU" as NSString).draw(at: CGPoint(x: 548, y: 100), withAttributes: [.font: UIFont.systemFont(ofSize: 12, weight: .heavy), .foregroundColor: UIColor.white.withAlphaComponent(0.55)])
        ("\(opponentDistance)m" as NSString).draw(at: CGPoint(x: 438, y: 154), withAttributes: [.font: UIFont.monospacedDigitSystemFont(ofSize: 34, weight: .bold), .foregroundColor: UIColor.white.withAlphaComponent(0.80)])
        ("THEM" as NSString).draw(at: CGPoint(x: 548, y: 166), withAttributes: [.font: UIFont.systemFont(ofSize: 12, weight: .heavy), .foregroundColor: UIColor.white.withAlphaComponent(0.45)])
        drawPill(statusText(payload, state: state), at: CGPoint(x: 430, y: 216))
    }

    private static func drawCar(context: CGContext, x: CGFloat, y: CGFloat, color: UIColor) {
        let body = CGRect(x: x - 20, y: y - 12, width: 40, height: 24)
        color.setFill(); UIBezierPath(roundedRect: body, cornerRadius: 8).fill()
        UIColor.black.withAlphaComponent(0.78).setFill()
        context.fillEllipse(in: CGRect(x: body.minX + 4, y: body.maxY - 2, width: 9, height: 9))
        context.fillEllipse(in: CGRect(x: body.maxX - 13, y: body.maxY - 2, width: 9, height: 9))
    }

    private static func statusText(_ payload: PingoMessagePayload, state: PingoExtraGameState) -> String {
        switch payload.action {
        case .challenge: return "RACE CHALLENGE"
        case .accepted: return "GRID READY"
        case .turn: return state.lastSummary.isEmpty ? "YOUR RUN" : state.lastSummary.uppercased()
        case .completed: return "RACE COMPLETE"
        case .resigned: return "RACE ENDED"
        case .rematch: return "NEW RACE"
        }
    }

    private static func drawPill(_ text: String, at point: CGPoint) {
        let value = text as NSString
        let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 13, weight: .heavy), .foregroundColor: UIColor.white]
        let textSize = value.size(withAttributes: attrs)
        let pill = CGRect(x: point.x, y: point.y, width: min(185, textSize.width + 30), height: 30)
        UIColor.black.withAlphaComponent(0.70).setFill(); UIBezierPath(roundedRect: pill, cornerRadius: 15).fill()
        value.draw(at: CGPoint(x: pill.minX + 15, y: pill.minY + 6), withAttributes: attrs)
    }

    private static func drawFooter(size: CGSize, payload: PingoMessagePayload) {
        ("Mini Racing" as NSString).draw(at: CGPoint(x: 28, y: size.height - 77), withAttributes: [.font: UIFont.systemFont(ofSize: 28, weight: .bold), .foregroundColor: UIColor.white])
        let action = actionText(payload) as NSString
        let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 18, weight: .semibold), .foregroundColor: UIColor.white.withAlphaComponent(0.78)]
        let actionSize = action.size(withAttributes: attrs)
        action.draw(at: CGPoint(x: size.width - actionSize.width - 28, y: size.height - 70), withAttributes: attrs)
    }

    private static func actionText(_ payload: PingoMessagePayload) -> String {
        switch payload.action {
        case .challenge: return "TAP TO RACE"
        case .accepted: return "GRID READY"
        case .turn: return "OPEN YOUR RUN"
        case .completed: return "SEE RESULT"
        case .resigned: return "RACE ENDED"
        case .rematch: return "NEXT RACE"
        }
    }

    private static func progress(_ state: PingoExtraGameState, _ index: Int) -> Int {
        guard state.positions.indices.contains(index), let value = state.positions[index].first else { return 0 }
        return min(100, max(0, value))
    }

    private static func value(_ values: [Int], _ index: Int) -> Int { values.indices.contains(index) ? values[index] : 0 }
}
