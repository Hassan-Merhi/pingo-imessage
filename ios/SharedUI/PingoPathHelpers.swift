import SwiftUI

extension Path {
    init(_ rect: CGRect) {
        self.init()
        addRect(rect)
    }
}
