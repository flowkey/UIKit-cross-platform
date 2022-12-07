
import Dispatch
import JNI

extension DispatchQueue {
    func syncSafe(callback: @escaping @MainActor () -> Void) {
        if isMainThread {
            unsafeBitCast(callback, to: (() -> Void).self)()
            return
        }

        DispatchQueue.main.sync {
            callback()
        }
    }
}
