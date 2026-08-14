import SwiftUI

extension Color {
    static let pingoInk = Color(red: 25/255, green: 23/255, blue: 43/255)
    static let pingoPrimary = Color(red: 102/255, green: 87/255, blue: 232/255)
    static let pingoSecondary = Color(red: 40/255, green: 199/255, blue: 183/255)
    static let pingoSurface = Color(red: 247/255, green: 246/255, blue: 255/255)
    static let pingoHighlight = Color(red: 255/255, green: 204/255, blue: 102/255)
}

struct PingoMark: View {
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.29, style: .continuous)
                .fill(Color.pingoPrimary)
            RoundedRectangle(cornerRadius: size * 0.18, style: .continuous)
                .fill(.white)
                .frame(width: size * 0.62, height: size * 0.48)
                .offset(y: -size * 0.03)
            Circle()
                .fill(Color.pingoSecondary)
                .frame(width: size * 0.13, height: size * 0.13)
                .offset(x: -size * 0.14, y: -size * 0.03)
            Circle()
                .fill(Color.pingoPrimary)
                .frame(width: size * 0.13, height: size * 0.13)
                .offset(x: size * 0.14, y: -size * 0.03)
            Path { path in
                path.move(to: CGPoint(x: size * 0.52, y: size * 0.60))
                path.addLine(to: CGPoint(x: size * 0.65, y: size * 0.76))
                path.addLine(to: CGPoint(x: size * 0.43, y: size * 0.67))
                path.closeSubpath()
            }
            .fill(.white)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
