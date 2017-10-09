package org.uikit
import android.widget.FrameLayout
import org.libsdl.app.SDLActivity

open class UIKitActivity : SDLActivity() {
//    override fun getLibraries() = arrayOf("JNI", "SDL2", "SDL2_gpu")

    companion object {
        fun addChildLayout(layout: FrameLayout) {
            mLayout.addView(layout)
        }
    }
}
