#if os(Android)

import JNI


private let TAG = "UserDefaults"

public class UserDefaults: JNIObject {
    override public static var className: String {
        return "com.flowkey.uikit.UserDefaults"
    }

    public static var standard = try! UserDefaults()

    private convenience init() throws {
        let context = try jni.call("getContext", on: getSDLView(), returningObjectType: "android.content.Context")
        try self.init(arguments: JavaContext(context))
    }

    public func has(_ itemKey: String) -> Bool {
        return try! UserDefaults.standard.call(
            methodName: "has",
            arguments: [itemKey]
        )
    }

    public func get(_ itemKey: String) -> Int {
        let defaultValue = 0
        return try! UserDefaults.standard.call(
            methodName: "getInt",
            arguments: [itemKey, defaultValue]
        )
    }

    public func get(_ itemKey: String) -> Bool {
        let defaultValue = false
        return try! UserDefaults.standard.call(
            methodName: "getBoolean",
            arguments: [itemKey, defaultValue]
        )
    }

    public func get(_ itemKey: String) -> String? {
        let defaultValue = "com.flowkey.player.UserDefaults.string.defaultValue"
        let result: String = try! UserDefaults.standard.call(
            methodName: "getString",
            arguments: [itemKey, defaultValue]
        )
        return result == defaultValue ? nil : result
    }

    public func set(_ itemKey: String, to value: JavaParameterConvertible?) {
        if let intValue = value as? Int {
            try! UserDefaults.standard.call(methodName: "setInt", arguments: [itemKey, intValue])
        } else if let boolValue = value as? Bool {
            try! UserDefaults.standard.call(methodName: "setBool", arguments: [itemKey, boolValue])
        } else if let stringValue = value as? String {
            try! UserDefaults.standard.call(methodName: "setString", arguments: [itemKey, stringValue])
        } else {
            fatalError("LocalStorage: Unsupported type")
        }
    }
}


#endif  // os(Android)
