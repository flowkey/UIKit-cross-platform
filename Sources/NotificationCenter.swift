#if os(Android)
import var JNI.isMainThread
#elseif canImport(Darwin)
import class Foundation.Thread
private var isMainThread: Bool {
    return Thread.isMainThread
}
#endif

public class NotificationCenter {
    public internal(set) static var `default` = NotificationCenter()

    internal init() {}

    private var observers: [Notification.Name: [NotificationCenterObserver]] = [:]

    public func addObserver(
        forName name: Notification.Name,
        object: AnyObject?,
        queue: OperationQueue?,
        using callback: @escaping (@Sendable (Notification) -> Void)
    ) -> NotificationCenterObserver {
        let observer = NotificationCenterObserver(object: object, queue: queue, callback: callback)
        observers[name] = observers[name] ?? []
        observers[name]?.append(observer)
        return observer
    }

    public func removeObserver(
        _ observer: NotificationCenterObserver,
        name: Notification.Name? = nil,
        object anObject: AnyObject? = nil // unused
    ) {
        for notificationName in observers.keys {
            if let name = name, name != notificationName { continue }
            observers[notificationName]!.removeAll(where: { $0 === observer })
        }
    }

    public func post(name: Notification.Name, object: AnyObject?) {
        let notification = Notification(name: name, object: object)
        observers[name]?.forEach({ observer in
            if let object = object, observer.object !== object { return }
            if observer.queue == .main {
                if isMainThread {
                    observer.callback(notification)
                } else {
                    Task { @MainActor in observer.callback(notification) }
                }
            } else {
                observer.callback(notification)
            }
        })
    }
}

public class NotificationCenterObserver {
    weak private(set) internal var object: AnyObject?
    let callback: (@Sendable (Notification) -> Void)
    let queue: OperationQueue?

    fileprivate init(object: AnyObject?, queue: OperationQueue?, callback: @escaping (@Sendable (Notification) -> Void)) {
        self.callback = callback
        self.object = object
        self.queue = queue
    }
}

public struct OperationQueue: Equatable {
    private var id: String
    public static let main = OperationQueue(id: "main")
}
