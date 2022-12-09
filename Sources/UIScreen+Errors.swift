//
//  UIScreen+Errors.swift
//  UIKit
//
//  Created by Geordie Jay on 08.05.18.
//  Copyright © 2018 flowkey. All rights reserved.
//

@_implementationOnly import SDL_gpu

extension UIScreen {
    func clearErrors() {
        let lastError = GPU_PopErrorCode()
        if lastError.error != GPU_ERROR_NONE {
            clearErrors() // keep clearing the stack recursively
        }
    }

    /// `throw`s errors of the given type, asserts in debug if another error was present
    func throwOnErrors(ofType errorType: [GPU_ErrorEnum]) throws {
        let lastError = GPU_PopErrorCode()
        if lastError.error == GPU_ERROR_NONE {
            return
        }

        if errorType.contains(lastError.error) {
            clearErrors() // clear all others
            try lastError.error.throwAsSwiftGPUError()
        }

        #if DEBUG
        print(String(cString: lastError.details))
        print(lastError.error)
        assertionFailure("Unexpected error when throwing GPU_Errors")
        #endif
    }
}

enum GPUError: Error {
    case dataError, nullArgument, backendError, none, userError, fileNotFound, unsupportedFunction, unknown
}

private extension GPU_ErrorEnum {
    func throwAsSwiftGPUError() throws {
        switch self {
        case GPU_ERROR_DATA_ERROR:
            throw GPUError.dataError
        case GPU_ERROR_NULL_ARGUMENT:
            throw GPUError.nullArgument
        case GPU_ERROR_BACKEND_ERROR:
            throw GPUError.backendError
        case GPU_ERROR_NONE:
            throw GPUError.none
        case GPU_ERROR_USER_ERROR:
            throw GPUError.userError
        case GPU_ERROR_FILE_NOT_FOUND:
            throw GPUError.fileNotFound
        case GPU_ERROR_UNSUPPORTED_FUNCTION:
            throw GPUError.unsupportedFunction
        default:
            assertionFailure("Unknown GPU_ErrorEnum error type")
            throw GPUError.unknown
        }
    }
}
