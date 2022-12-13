public protocol UIViewControllerTransitionCoordinator {}

class DummyTransitionCoordinator: UIViewControllerTransitionCoordinator {
    static let shared = DummyTransitionCoordinator()
}
