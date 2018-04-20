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

    open internal(set) var navigationController: UINavigationController?
    open internal(set) var presentingViewController: UIViewController?
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
    open func viewDidAppear() {}
    open func viewWillDisappear() {}
    open func viewDidDisappear() {}

    open func viewWillLayoutSubviews() {}

    open func present(_ otherViewController: UIViewController, animated: Bool, completion: (() -> Void)? = nil) {
        otherViewController.view.frame = self.view.bounds
        otherViewController.viewWillAppear(animated)

        // TODO: Add a background modal overlay here first. Also, actually animate the transition in.
        self.view.addSubview(otherViewController.view)

        otherViewController.viewDidAppear()

        otherViewController.viewWillLayoutSubviews()
        otherViewController.view.layoutSubviews()

        completion?()
    }

    open func dismiss(animated: Bool, completion: (() -> Void)? = nil) {
        // TODO: Actually animate.
        if let navigationController = navigationController {
            navigationController.dismiss(animated: animated, completion: completion)
        } else {
            self.viewWillDisappear()
            self.view.removeFromSuperview()
            self.viewDidDisappear()
            completion?()
        }
    }

    open private(set) lazy var navigationItem: UINavigationItem = {
        let item = UINavigationItem(title: "") // there is no public initializer that takes no `title`
        item.title = self.title // possibly set `title` back to `nil` here
        return item
    }()
}
