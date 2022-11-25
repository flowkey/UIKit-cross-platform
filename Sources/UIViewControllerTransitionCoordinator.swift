public protocol UIViewControllerTransitionCoordinator {}

class DefaultTransitionCoordinator: UIViewControllerTransitionCoordinator {
    static let shared = DefaultTransitionCoordinator()
}
