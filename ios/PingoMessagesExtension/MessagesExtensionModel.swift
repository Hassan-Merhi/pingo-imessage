import Foundation
import Messages

@MainActor
final class MessagesExtensionModel: ObservableObject {
    @Published var presentationStyle: MSMessagesAppPresentationStyle = .compact
    @Published var isConversationActive = false

    func activate(style: MSMessagesAppPresentationStyle) {
        presentationStyle = style
        isConversationActive = true
    }

    func transition(to style: MSMessagesAppPresentationStyle) {
        presentationStyle = style
    }

    func deactivate() {
        isConversationActive = false
    }
}
