package org.uikit
import android.support.v4.app.ActivityCompat
import android.widget.FrameLayout
import org.libsdl.app.SDLActivity

open class UIKitActivity : SDLActivity(), ActivityCompat.OnRequestPermissionsResultCallback {
    override fun getLibraries() = arrayOf("JNI", "SDL2", "SDL2_gpu", "AndroidPlayer")

    companion object {
        fun addChildLayout(layout: FrameLayout) {
            mLayout.addView(layout)
        }
    }
}
