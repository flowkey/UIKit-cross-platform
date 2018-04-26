open class UIViewController: UIResponder {
    internal var _view: UIView?
    open var view: UIView! {
        get {
            loadViewIfNeeded()
            return _view
        }
        set { _view = newValue }
    }

    open var viewIsLoaded: Bool {
        return _view != nil
    }

    open var title: String? {
        didSet { navigationItem.title = title }
    }

    open internal(set) weak var navigationController: UINavigationController?
    open internal(set) weak var presentingViewController: UIViewController?

    // TODO: tablet only
    open var modalPresentationStyle: UIModalPresentationStyle = .popover
    open var popoverPresentationController: UIPopoverPresentationController?

    // The `presentedViewController` is owned by its parent, but not the other way around:
    open internal(set) var presentedViewController: UIViewController?

    public init(nibName: String?, bundle: Bundle?) {
        super.init()
        if nibName != nil || bundle != nil {
            assertionFailure("We can't load nib files (yet?)!")
        }
    }

    public func loadViewIfNeeded() {
        if !viewIsLoaded {
            loadView()
            viewDidLoad()
        }
    }

    open func loadView() {
        view = UIView()
    }

    // Most of these methods are designed to be overriden in `UIViewController` subclasses
    open func viewDidLoad() {
        view.backgroundColor = .white
        view.next = self // set responder
    }

    open func viewWillAppear(_ animated: Bool) {}
    open func viewDidAppear(_ animated: Bool) {}
    open func viewWillDisappear(_ animated: Bool) {}
    open func viewDidDisappear(_ animated: Bool) {}

    open func viewWillLayoutSubviews() {}
    open func viewDidLayoutSubviews() {}

    private let animationTime = 0.4

    open func present(
        _ otherViewController: UIViewController,
        animated: Bool,
        completion: (() -> Void)? = nil
    ) {
        if presentedViewController != nil {
            print("Warning: attempted to present \(otherViewController), but \(self) is already presenting another view controller. Ignoring request.")
            return
        }

        if otherViewController.presentingViewController != nil {
            preconditionFailure("Tried to present \(otherViewController) but it is already being presented by \(otherViewController.presentingViewController!)")
        }

        presentedViewController = otherViewController
        otherViewController.presentingViewController = self

        otherViewController.view.frame = UIScreen.main.bounds
        otherViewController.viewWillAppear(animated)

        // TODO: Add a background modal overlay here.
        self.view.addSubview(otherViewController.view)

        if animated {
            otherViewController.view.frame.origin.y = view.bounds.maxY
            UIView.animate(withDuration: animationTime, options: [.allowUserInteraction], animations: {
                otherViewController.view.frame.origin.y = view.bounds.origin.y
            }, completion: nil)
        }

        otherViewController.viewDidAppear(animated)

        otherViewController.viewWillLayoutSubviews()
        otherViewController.view.layoutSubviews()

        completion?()
    }

    open func dismiss(animated: Bool, completion: (() -> Void)? = nil) {
        // The `UINavigationController` dismisses the UIViewController at the top of its stack (potentially `self`) first.
        if let navigationController = navigationController {
            navigationController.dismiss(animated: animated, completion: completion)
            return
        }

        viewWillDisappear(animated)

        UIView.animate(
            withDuration: animated ? animationTime : 0.0,
            options: [],
            animations: {
                view.frame.origin.y = view.superview?.bounds.height ?? view.frame.height
            }, completion: { _ in
                self.view.removeFromSuperview()
                self.viewDidDisappear(animated)
                completion?()

                self.presentingViewController?.presentedViewController = nil
                self.presentingViewController = nil
        })
    }

    open private(set) lazy var navigationItem: UINavigationItem = {
        let item = UINavigationItem(title: "") // there is no public initializer that takes no `title`
        item.title = self.title // possibly set `title` back to `nil` here
        return item
    }()


    open override func handleHardwareBackButtonPress() -> Bool {
        if view.superview is UIWindow {
            // Don't dismiss the last view controller, otherwise we'll be left with a blank screen:
            return super.handleHardwareBackButtonPress()
        }

        self.dismiss(animated: true)
        return true
    }
}

public class UIPresentationController {

}

public class UIPopoverPresentationController: UIPresentationController {
    open var sourceView: UIView?
    open var sourceRect: CGRect = .zero
    open var permittedArrowDirections: UIPopoverArrowDirection = .unknown

    public override init() {
        super.init()
    }
}

public enum UIPopoverArrowDirection {
    case unknown
}

