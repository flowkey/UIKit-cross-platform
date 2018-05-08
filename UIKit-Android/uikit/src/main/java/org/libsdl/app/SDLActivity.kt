package org.libsdl.app

import java.lang.reflect.Method

import android.view.*
import android.widget.RelativeLayout
import android.util.Log
import android.graphics.*
import android.content.pm.ActivityInfo
import android.view.KeyEvent.*
import android.content.Context
import main.java.org.libsdl.app.*

private val TAG = "SDLActivity"

open class SDLActivity(context: Context?) : RelativeLayout(context),
                                            SDLOnKeyListener,
                                            SDLOnTouchListener,
                                            SurfaceHolder.Callback,
                                            Choreographer.FrameCallback,
                                            APKExtensionInputStreamOpener {

    companion object {
        internal val COMMAND_CHANGE_TITLE = 1
        internal val COMMAND_SET_KEEP_SCREEN_ON = 5

        // If we want to separate mouse and touch events.
        // This is only toggled in native code when a hint is set!
        // This is the only property that remains static - we probably won't use it at all long-term
        // and it is a major overhaul to change the native C code (there are a lot of dependencies)
        @JvmStatic
        internal var mSeparateMouseAndTouch = false
    }

    private var mSurface: SurfaceView
    private var mIsSurfaceReady = false
    private var mHasFocus = false

    private external fun nativeRender()
    private external fun nativeInit(): Int
    private external fun nativeQuit()
    private external fun nativePause()
    private external fun nativeResume()
    private external fun onNativeResize(x: Int, y: Int, format: Int, rate: Float)
    private external fun onNativeSurfaceChanged()
    private external fun onNativeSurfaceDestroyed()

    // SDLOnKeyListener conformance
    external override fun onNativeKeyDown(keycode: Int)
    external override fun onNativeKeyUp(keycode: Int)

    // SDLOnTouchListener conformance
    external override fun onNativeMouse(button: Int, action: Int, x: Float, y: Float)
    external override fun onNativeTouch(touchDevId: Int, pointerFingerId: Int, action: Int, x: Float, y: Float, p: Float)
    override var mWidth: Float = 1.0f // Keep track of the surface size to normalize touch events
    override var mHeight: Float = 1.0f // Start with non-zero values to avoid potential division by zero

    // APKExtensionStreamOpener conformance
    external override fun nativeGetHint(name: String): String?
    override var expansionFile: Any? = null
    override var expansionFileMethod: Method? = null

    // Handler for the messages
    private val commandHandler by lazy { SDLCommandHandler(this.context) }

    private var isRunning = false

    open val libraries: Array<String> get() = arrayOf("JNI", "SDL2")

    init {
        Log.v(TAG, "Device: " + android.os.Build.DEVICE)
        Log.v(TAG, "Model: " + android.os.Build.MODEL)

        libraries.forEach { System.loadLibrary(it) }

        // Set up the surface
        mSurface = SurfaceView(context)
        mSurface.setZOrderOnTop(true) // so we can cover the video (fixes Android 8 bug)

        // Enables the alpha value for colors on the SDLSurface
        // which makes the VideoJNI SurfaceView behind it visible
        mSurface.holder?.setFormat(PixelFormat.RGBA_8888)
        mSurface.isFocusable = true
        mSurface.isFocusableInTouchMode = true
        mSurface.requestFocus()

        mSurface.holder?.addCallback(this)
        mSurface.setOnTouchListener(this)

        this.addView(mSurface)
    }

    @Suppress("unused") // accessed via JNI
    fun getDeviceDensity(): Float = context.resources.displayMetrics.density

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        Log.v(TAG, "onWindowFocusChanged(): " + hasFocus)

        this.mHasFocus = hasFocus

        if (hasFocus) {
            handleResume()
        } else {
            removeFrameCallback()
        }
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        // Ignore certain special keys so they're handled by Android
        return when (event.keyCode) {
            KEYCODE_VOLUME_DOWN, KEYCODE_VOLUME_UP, KEYCODE_CAMERA, KEYCODE_ZOOM_IN, KEYCODE_ZOOM_OUT ->
                false
            else ->
                super.dispatchKeyEvent(event)
        }
    }

    /**
     * This method is called by SDLCommandHandler if SDL did not handle a message itself.
     * This happens if a received message contains an unsupported command.
     * Method can be overwritten to handle Messages in a different class.
     * @param command the command of the message.
     * @param param the parameter of the message. May be null.
     * @return if the message was handled in overridden method.
     */
    @Suppress("UNUSED_PARAMETER")
    fun onUnhandledMessage(command: Int, param: Any): Boolean {
        Log.v(TAG, "onUnhandledMessage()")
        return false
    }

    /**
     * This method is called by SDL using JNI.
     * @return result of getSystemService(name) but executed on UI thread.
     */
    fun getSystemServiceFromUiThread(name: String): Any? {
        return context.getSystemService(name)
    }

    private fun postFrameCallbackIfNotRunning() {
        if (isRunning) return

        isRunning = true
        Choreographer.getInstance().postFrameCallback(this)
    }

    private fun doNativeInitAndPostFrameCallbackIfNotRunning() {
        nativeInit()
        postFrameCallbackIfNotRunning()
    }

    fun removeFrameCallbackAndQuit() {
        // Without this check it's possible to try to "nativeRender" when the SDL.window is nil
        if (!isRunning) { return }

        // Remove any frame callback that may exist to ensure we don't try to render after destroy
        removeFrameCallback()

        // This eventually stops the run loop and nulls the native SDL.window
        this.nativeQuit()

        // cleanup UIKit after nativeQuit
        this.nativeRender()
    }

    fun removeFrameCallback() {
        Choreographer.getInstance().removeFrameCallback(this)
        this.isRunning = false
    }

    override fun doFrame(frameTimeNanos: Long) {
        if (isRunning && mIsSurfaceReady) {
            this.nativeRender()
            // Request the next frame only after rendering the current one.
            // This should skip next frame if the current one takes too long.
            Choreographer.getInstance().postFrameCallback(this)
        }
    }

    /** Called by SDL using JNI. */
    @Suppress("unused")
    fun setActivityTitle(title: String): Boolean {
        // Called from SDLMain() thread and can't directly affect the view
        return commandHandler.sendCommand(COMMAND_CHANGE_TITLE, title)
    }

    /** Called by SDL using JNI. */
    @Suppress("unused")
    fun sendMessage(command: Int, param: Int): Boolean {
        return commandHandler.sendCommand(command, param)
    }

    /** Called by SDL using JNI. */
    @Suppress("unused")
    val nativeSurface: Surface get() = this.mSurface.holder.surface


    // Input

    /** Called by SDL using JNI. */
    @Suppress("unused")
    fun inputGetInputDeviceIds(sources: Int): IntArray {
        return InputDevice.getDeviceIds().fold(intArrayOf(0)) { result: IntArray, id: Int ->
            val device = InputDevice.getDevice(id)
            return if (device.sources and sources != 0) (result + device.id) else result
        }
    }

    /** Called by onResume or surfaceCreated. An actual resume should be done only when the surface is ready.
     * Note: Some Android variants may send multiple surfaceChanged events, so we don't need to resume
     * every time we get one of those events, only if it comes after surfaceDestroyed
     */
    private fun handleResume() {
        Log.v(TAG, "handleResume()")

        if (!isRunning && mIsSurfaceReady && mHasFocus) {
            Log.d(TAG, "handleResume, all conditions met")
            this.nativeResume()
            this.handleSurfaceResume()
            doNativeInitAndPostFrameCallbackIfNotRunning() // does what nativeResume used to
        }

        postFrameCallbackIfNotRunning()
    }

    private fun handleSurfaceResume() {
        Log.v(TAG, "handleSurfaceResume()")
        mSurface.isFocusable = true
        mSurface.isFocusableInTouchMode = true
        mSurface.requestFocus()
        mSurface.setOnKeyListener(this)
        mSurface.setOnTouchListener(this)
    }

    override fun surfaceCreated(holder: SurfaceHolder?) {
        Log.v(TAG, "surfaceCreated()")
        handleResume()
    }

    // Called when the surface is resized, e.g. orientation change or activity creation
    override fun surfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) {
        Log.v(TAG, "surfaceChanged()")

        var sdlFormat = 0x15151002 // SDL_PIXELFORMAT_RGB565 by default
        when (format) {
            PixelFormat.RGBA_8888 -> {
                Log.v(TAG, "pixel format RGBA_8888")
                sdlFormat = 0x16462004 // SDL_PIXELFORMAT_RGBA8888
            }
            PixelFormat.RGBX_8888 -> {
                Log.v(TAG, "pixel format RGBX_8888")
                sdlFormat = 0x16261804 // SDL_PIXELFORMAT_RGBX8888
            }
            PixelFormat.RGB_565 -> {
                Log.v(TAG, "pixel format RGB_565")
                sdlFormat = 0x15151002 // SDL_PIXELFORMAT_RGB565
            }
            PixelFormat.RGB_888 -> {
                Log.v(TAG, "pixel format RGB_888")
                // Not sure this is right, maybe SDL_PIXELFORMAT_RGB24 instead?
                sdlFormat = 0x16161804 // SDL_PIXELFORMAT_RGB888
            }
            else -> Log.w("SDL", "pixel format unknown " + format)
        }

        mWidth = width.toFloat()
        mHeight = height.toFloat()
        this.onNativeResize(width, height, sdlFormat, display.refreshRate)
        Log.v(TAG, "Window size: " + width + "x" + height)


        // FIXME: Remove this hack
        val requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE

        // Skip if the provided surface isn't in the requested orientation
        val skip =
                (requestedOrientation == ActivityInfo.SCREEN_ORIENTATION_PORTRAIT && mWidth > mHeight) ||
                (requestedOrientation == ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE && mWidth < mHeight)

        if (skip) {
            val min = Math.min(mWidth, mHeight)
            val max = Math.max(mWidth, mHeight)

            if (max / min < 1.20f) {
                // Special Patch for Square Resolution: Black Berry Passport
                Log.v(TAG, "Avoid skip on near-square aspect-ratio, just in case.")
            } else {
                Log.v(TAG, "Surface is not ready. Skipping creation for now...")
                return
            }
        }

        // Set mIsSurfaceReady to 'true' *before* making a call to handleResume
        mIsSurfaceReady = true
        onNativeSurfaceChanged()

        doNativeInitAndPostFrameCallbackIfNotRunning()


        if (mHasFocus) {
            handleSurfaceResume()
        }
    }

    // Called when we lose the surface
    override fun surfaceDestroyed(holder: SurfaceHolder) {
        Log.v(TAG, "surfaceDestroyed()")
        mIsSurfaceReady = false
        onNativeSurfaceDestroyed()
        removeFrameCallbackAndQuit()
    }


    fun removeCallbacks() {
        Log.v(TAG, "removeCallbacks()")
        mSurface.setOnTouchListener(null)
        mSurface.holder?.removeCallback(this)
        nativeSurface.release()
    }
}


    // The code below was unused and used a deprecated API anyway.
    // It would be good to have some access to native dialogs though, so
    // we should rethink it based on the up-to-date information at:
    // https://developer.android.com/guide/topics/ui/dialogs.html#FullscreenDialog

//    /**
//     * This method is called by SDL using JNI.
//     * Shows the messagebox from UI thread and block calling thread.
//     * buttonFlags, buttonIds and buttonTexts must have same length.
//     * @param buttonFlags array containing flags for every button.
//     * @param buttonIds array containing id for every button.
//     * @param buttonTexts array containing text for every button.
//     * @param colors null for default or array of length 5 containing colors.
//     * @return button id or -1.
//     */
//    fun messageboxShowMessageBox(
//            flags: Int,
//            title: String,
//            message: String,
//            buttonFlags: IntArray,
//            buttonIds: IntArray,
//            buttonTexts: Array<String>,
//            colors: IntArray): Int {
//    }

//    override fun onCreateDialog(ignore: Int, args: Bundle): Dialog? {
//    }

