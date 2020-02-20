//
//  UIScreen+Errors.swift
//  UIKit
//
//  Created by Geordie Jay on 08.05.18.
//  Copyright © 2018 flowkey. All rights reserved.
//

import SDL_gpu

extension UIScreen {
    func clearErrors() {
        let lastError = GPU_PopErrorCode()
        if lastError.error != GPU_ERROR_NONE {
            clearErrors() // keep clearing the stack recursively
        }
    }

    /// `throw`s errors of the given type, asserts in debug if another error was present
    func throwOnErrors(ofType errorType: Set<GPU_ErrorEnum>) throws {
        let lastError = GPU_PopErrorCode()
        if lastError.error == GPU_ERROR_NONE {
            return
        }

        if errorType.contains(lastError.error) {
            clearErrors() // clear all others
            throw lastError.error
        }

        #if DEBUG
        print(String(cString: lastError.details))
        print(lastError.error)
        assertionFailure("Unexpected error when throwing GPU_Errors")
        #endif
    }
}

extension GPU_ErrorEnum: Equatable, Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.rawValue)
    }

    public static func == (lhs: GPU_ErrorEnum, rhs: GPU_ErrorEnum) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}

extension GPU_ErrorEnum: Error, CustomStringConvertible {
    public var description: String {
        switch self {
        case GPU_ERROR_DATA_ERROR:
            return "GPU_ERROR_DATA_ERROR"
        case GPU_ERROR_NULL_ARGUMENT:
            return "GPU_ERROR_NULL_ARGUMENT"
        case GPU_ERROR_BACKEND_ERROR:
            return "GPU_ERROR_BACKEND_ERROR"
        case GPU_ERROR_NONE:
            return "GPU_ERROR_NONE"
        case GPU_ERROR_USER_ERROR:
            return "GPU_ERROR_USER_ERROR"
        case GPU_ERROR_FILE_NOT_FOUND:
            return "GPU_ERROR_FILE_NOT_FOUND"
        case GPU_ERROR_UNSUPPORTED_FUNCTION:
            return "GPU_ERROR_UNSUPPORTED_FUNCTION"
        default:
            assertionFailure("Unknown GPU_ErrorEnum error type")
            return "Unknown"
        }
    }
}
