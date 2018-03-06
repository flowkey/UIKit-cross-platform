package org.libsdl.app

import java.lang.reflect.Method

import android.view.*
import android.widget.RelativeLayout
import android.util.Log
import android.graphics.*
import android.hardware.*
import android.content.pm.ActivityInfo
import android.view.KeyEvent.*
import android.content.Context
import main.java.org.libsdl.app.*

private val TAG = "SDLActivity"

open class SDLActivity(context: Context?) : RelativeLayout(context),
                                            SDLOnKeyListener,
                                            SDLOnTouchListener,
                                            SDLSensorEventListener,
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
        @JvmStatic private var mSeparateMouseAndTouch = false
    }

    private var mSurface: SurfaceView
    private var mIsPaused = false
    private var mIsSurfaceReady = false
    private var mHasFocus = false

    private external fun render(): Int
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

    // SDLSensorEventListener conformance
    external override fun onNativeAccel(x: Float, y: Float, z: Float)
    override val rotation: Int
        get() = display.rotation

    // APKExtensionStreamOpener conformance
    external override fun nativeGetHint(name: String): String?
    override var expansionFile: Any? = null
    override var expansionFileMethod: Method? = null


    // Handler for the messages
    private val commandHandler by lazy { SDLCommandHandler(this.context) }

    // Lazy to avoid accessing context before onCreate!
    private val mSensorManager: SensorManager by lazy { context!!.getSystemService(Context.SENSOR_SERVICE) as SensorManager }

    private var isRunning: Boolean = false

    init {
        Log.v(TAG, "Device: " + android.os.Build.DEVICE)
        Log.v(TAG, "Model: " + android.os.Build.MODEL)

        System.loadLibrary("JNI")
        System.loadLibrary("AndroidPlayer")
        System.loadLibrary("SDL2")

        // Set up the surface
        mSurface = SurfaceView(context)

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
    fun removeCallbacks() {
        Log.v(TAG, "removeCallbacks()")
        mSurface.setOnTouchListener(null)
        mSurface.holder?.removeCallback(this)
        nativeSurface.release()
    }

    @Suppress("unused") // accessed via JNI
    private fun getDeviceDensity(): Float = context.resources.displayMetrics.density

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        Log.v(TAG, "onWindowFocusChanged(): " + hasFocus)

        this.mHasFocus = hasFocus
        if (hasFocus) {
            handleSurfaceResume()
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


    /** Called by onPause or surfaceDestroyed. Even if surfaceDestroyed
     * is the first to be called, mIsSurfaceReady should still be set
     * to 'true' during the call to onPause (in a usual scenario).
     */
    private fun handlePause() {
        if (!this.mIsPaused && this.mIsSurfaceReady) {
            this.mIsPaused = true
            this.nativePause()
            this.enableSensor(Sensor.TYPE_ACCELEROMETER, false)
        }
    }

    private fun startIfNotRunning() {
        // This is the entry point to the C app.
        // Start up the C app thread and enable sensor input for the first time
        if (this.isRunning) return
        this.isRunning = true
        this.nativeInit()
        this.enableSensor(Sensor.TYPE_ACCELEROMETER, true)
        Choreographer.getInstance().postFrameCallback(this)
    }


    private fun stop() {
        // Send a quit message to the application
        // This eventually stops the run loop and nulls the native SDL.window
        Choreographer.getInstance().removeFrameCallback(this)
        this.enableSensor(Sensor.TYPE_ACCELEROMETER, false)
        this.isRunning = false
    }

    fun quit() {
        this.stop()
        this.nativeQuit()
    }

    override fun doFrame(frameTimeNanos: Long) {
        Choreographer.getInstance().postFrameCallback(this)
        this.render()
    }


    /** Called by SDL using JNI. */
    @Suppress("unused")
    private fun setActivityTitle(title: String): Boolean {
        // Called from SDLMain() thread and can't directly affect the view
        return commandHandler.sendCommand(COMMAND_CHANGE_TITLE, title)
    }

    /** Called by SDL using JNI. */
    @Suppress("unused")
    private fun sendMessage(command: Int, param: Int): Boolean {
        return commandHandler.sendCommand(command, param)
    }

    /** Called by SDL using JNI. */
    @Suppress("unused")
    private val nativeSurface: Surface get() = this.mSurface.holder.surface


    // Input

    /** Called by SDL using JNI. */
    @Suppress("unused")
    private fun inputGetInputDeviceIds(sources: Int): IntArray {
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
        if (this.mIsPaused && this.mIsSurfaceReady && this.mHasFocus) {
            this.mIsPaused = false
            this.nativeResume()
            this.handleSurfaceResume()
        }
    }


    private fun handleSurfaceResume() {
        mSurface.isFocusable = true
        mSurface.isFocusableInTouchMode = true
        mSurface.requestFocus()
        mSurface.setOnKeyListener(this)
        mSurface.setOnTouchListener(this)
        enableSensor(Sensor.TYPE_ACCELEROMETER, true)
    }

    override fun surfaceCreated(holder: SurfaceHolder?) {
        handleResume()
    }

    // Called when the surface is resized
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
        startIfNotRunning()

        if (mHasFocus) {
            handleSurfaceResume()
        }
    }

    // Called when we lose the surface
    override fun surfaceDestroyed(holder: SurfaceHolder) {
        Log.v(TAG, "surfaceDestroyed()")
        // Call this *before* setting mIsSurfaceReady to 'false'
        handlePause()
        mIsSurfaceReady = false
        onNativeSurfaceDestroyed()
        stop()
    }


    // Sensor events
    private fun enableSensor(sensortype: Int, enabled: Boolean) {
        // TODO: This uses getDefaultSensor - what if we have >1 accels?
        if (enabled) {
            mSensorManager.registerListener(this,
                    mSensorManager.getDefaultSensor(sensortype),
                    SensorManager.SENSOR_DELAY_GAME, null)
        } else {
            mSensorManager.unregisterListener(this,
                    mSensorManager.getDefaultSensor(sensortype))
        }
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

