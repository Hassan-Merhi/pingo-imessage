import Messages
import SwiftUI

struct PingoMessagesRootView: View {
    @ObservedObject var model: MessagesExtensionModel
    let onRequestExpanded: () -> Void

    var body: some View {
        Group {
            if model.presentationStyle == .compact {
                PingoCompactHomeView(onOpen: onRequestExpanded)
            } else {
                NavigationStack {
                    PingoHomeView()
                        .navigationTitle("Pingo")
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: model.presentationStyle)
    }
}
