import UIKit

#if os(iOS)
extension UIGestureRecognizer {
    private static var handlers: [UIGestureRecognizer : (() -> Void)] = [:]

    @nonobjc convenience init(onAction: @escaping (() -> Void)) {
        self.init()
        self.addTarget(self, action: #selector(actionHandler))
        UIGestureRecognizer.handlers[self] = onAction
    }

    @objc private func actionHandler() {
        UIGestureRecognizer.handlers[self]?()
    }
}
#endif
