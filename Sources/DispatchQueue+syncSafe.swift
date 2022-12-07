
import Dispatch
import JNI

public extension DispatchQueue {
    private func unsafelyRunOnMainActor(_ callback: @escaping () -> Void) {
        callback()
    }

    /// this is supposed to dispatch events on `DispatchQueue.main` only
    func syncSafe(_ callback: @escaping @MainActor () -> Void) {
        if isMainThread {
            DispatchQueue.main.unsafelyRunOnMainActor(callback)
        } else {
            DispatchQueue.main.sync { callback() }
        }
    }
}
