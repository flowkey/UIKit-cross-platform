package com.flowkey.uikit

import android.content.Context
import org.libsdl.app.SDLActivity

// SDLActivity has to keep its name for now for JNI compatibility,
// but UIKitView is what we'd rather export to the world:
class UIKitView(context: Context) : SDLActivity(context) {
    // react native breaks layouting
    // this is a temporary / hacky fix for missing videos on android 6
    override fun requestLayout() {
        super.requestLayout()

        post {
            measure(MeasureSpec.makeMeasureSpec(width, MeasureSpec.EXACTLY), MeasureSpec.makeMeasureSpec(height, MeasureSpec.EXACTLY))
            layout(left, top, right, bottom)
        }
    }
}
