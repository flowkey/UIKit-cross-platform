
import Dispatch
import JNI

public extension DispatchQueue {
    private func unsafelyRunOnMainActor(_ callback: @escaping () -> Void) {
        callback()
    }

    func syncSafe(_ callback: @escaping @MainActor () -> Void) {
        print("isMainThread", isMainThread)
        if isMainThread {
            DispatchQueue.main.unsafelyRunOnMainActor(callback)
        } else {
            DispatchQueue.main.sync { callback() }
        }
    }
}
