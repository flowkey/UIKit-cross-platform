open class UINavigationController: UIViewController {
    public init(rootViewController: UIViewController) {
        super.init(nibName: nil, bundle: nil)
        viewControllers.append(rootViewController)
        updateUIFromViewControllerStack(animated: false)
    }

    internal var transitionView = UIView() // animates the other views
    open internal(set) var viewControllers: [UIViewController] = []

    private func updateUIFromViewControllerStack(animated: Bool) {
        // update stack in self.navigationBar
        // ensure top of stack is currently visible
    }

    open internal(set) var navigationBar = UINavigationBar()

    open func pushViewController(_ otherViewController: UIViewController, animated: Bool) {
        viewControllers.append(otherViewController)
        updateUIFromViewControllerStack(animated: animated)
    }

    open func popViewController(animated: Bool) -> UIViewController? {
        // You can't pop the rootViewController (per iOS docs)
        if viewControllers.count == 1 { return nil }

        let topOfStack = viewControllers.popLast()
        updateUIFromViewControllerStack(animated: animated)
        return topOfStack
    }

    open override func viewWillAppear(_ animated: Bool) {
        if viewControllers.isEmpty {
            preconditionFailure(
                "A UINavigationController must contain at least one other view controller")
        }

        super.viewWillAppear(animated)
    }
}
