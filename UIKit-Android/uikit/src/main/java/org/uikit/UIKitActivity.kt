package org.uikit
import android.widget.FrameLayout
import org.libsdl.app.SDLActivity

open class UIKitActivity : SDLActivity() {
    companion object {
        fun addChildLayout(layout: FrameLayout) {
            mLayout.addView(layout)
        }
    }
}
