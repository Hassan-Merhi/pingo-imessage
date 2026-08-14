import Messages
import SwiftUI

@MainActor
final class MessagesViewController: MSMessagesAppViewController {
    private let model = MessagesExtensionModel()
    private var host: UIHostingController<PingoMessagesRootView>?

    override func viewDidLoad() {
        super.viewDidLoad()
        installSwiftUIRoot()
    }

    private func installSwiftUIRoot() {
        let root = PingoMessagesRootView(
            model: model,
            onRequestExpanded: { [weak self] in
                self?.requestPresentationStyle(.expanded)
            }
        )
        let host = UIHostingController(rootView: root)
        addChild(host)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        host.didMove(toParent: self)
        self.host = host
    }

    override func didBecomeActive(with conversation: MSConversation) {
        super.didBecomeActive(with: conversation)
        model.activate(style: presentationStyle)
    }

    override func didResignActive(with conversation: MSConversation) {
        model.deactivate()
        super.didResignActive(with: conversation)
    }

    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        super.didTransition(to: presentationStyle)
        model.transition(to: presentationStyle)
    }
}
