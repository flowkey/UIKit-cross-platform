//
//  CATransform3D+SDL_gpu.swift
//  UIKit
//
//  Created by Geordie Jay on 13.02.18.
//  Copyright © 2018 flowkey. All rights reserved.
//

import SDL_gpu

extension CATransform3D {
    /// Set the current transformation as SDL_GPU's current transform matrix
    internal func setAsSDLgpuMatrix() {
        let currentMatrix = UnsafeMutableBufferPointer(start: GPU_GetCurrentMatrix(), count: 16)

        // We could copy currentMatrix to a CATransform3D and save some code here,
        // but we do this thousands of times a second so it's worth saving ourselves from making a copy:
        if
            currentMatrix[0] == m11, currentMatrix[1] == m12, currentMatrix[2] == m13, currentMatrix[3] == m14,
            currentMatrix[4] == m21, currentMatrix[5] == m22, currentMatrix[6] == m23, currentMatrix[7] == m24,
            currentMatrix[8] == m31, currentMatrix[9] == m32, currentMatrix[10] == m33, currentMatrix[11] == m34,
            currentMatrix[12] == m41, currentMatrix[13] == m42, currentMatrix[14] == m43, currentMatrix[15] == m44
        {
            // The current matrix equals the one we were going to set
            // Return so we can keep our BlitBuffer intact (saves CPU work)
            return
        }

        // Force anything that hasn't yet been sent to the GPU to be rendered (using the current transform)
        GPU_FlushBlitBuffer()

        currentMatrix[0] = m11; currentMatrix[1] = m12; currentMatrix[2] = m13; currentMatrix[3] = m14;
        currentMatrix[4] = m21; currentMatrix[5] = m22; currentMatrix[6] = m23; currentMatrix[7] = m24;
        currentMatrix[8] = m31; currentMatrix[9] = m32; currentMatrix[10] = m33; currentMatrix[11] = m34;
        currentMatrix[12] = m41; currentMatrix[13] = m42; currentMatrix[14] = m43; currentMatrix[15] = m44
    }
}
