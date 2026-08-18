import PingoCore
import SwiftUI

struct PingoCompactHomeView: View {
    let onOpen: () -> Void

    var body: some View {
        ZStack {
            Color.pingoMessagesChrome
                .ignoresSafeArea()

            HStack(spacing: 13) {
                PingoMark(size: 50)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Pingo")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.black)
                    Text("22 games ready to challenge")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.black.opacity(0.46))
                }

                Spacer(minLength: 8)

                Button("Play", action: onOpen)
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .tint(.pingoPrimary)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 13)
            .background(.white)
        }
        .accessibilityElement(children: .contain)
    }
}
