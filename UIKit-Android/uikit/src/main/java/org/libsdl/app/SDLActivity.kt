package org.libsdl.app

import java.io.IOException
import java.io.InputStream
import java.lang.reflect.Method

import android.app.*
import android.view.*
import android.widget.RelativeLayout
import android.os.*
import android.util.Log
import android.graphics.*
import android.hardware.*
import android.content.pm.ActivityInfo
import android.view.KeyEvent.*
import android.content.Context
import android.view.Surface.*
import main.java.org.libsdl.app.SDLOnKeyListener
import main.java.org.libsdl.app.SDLOnTouchListener

private val TAG = "SDLActivity"

open class SDLActivity(context: Context?) : RelativeLayout(context),
                                            SDLOnKeyListener,
                                            SDLOnTouchListener,
                                            SensorEventListener,
                                            SurfaceHolder.Callback,
                                            Choreographer.FrameCallback {



    companion object {
        internal val COMMAND_CHANGE_TITLE = 1
        internal val COMMAND_SET_KEEP_SCREEN_ON = 5

        // If we want to separate mouse and touch events.
        // This is only toggled in native code when a hint is set!
        // This is the only property that remains static - we probably won't use it at all long-term
        // and it is a major overhaul to change the native C code (there are a lot of dependencies)
        @JvmStatic private var mSeparateMouseAndTouch = false
    }

    // Keep track of the paused state
    private var mIsPaused = false
    private var mIsSurfaceReady = false
    private var mHasFocus = false

    // Main components
    private var mSurface: SurfaceView

    // Handler for the messages
    private val commandHandler by lazy { SDLCommandHandler(this.context) }

    // APK expansion files support

    /** com.android.vending.expansion.zipfile.ZipResourceFile object or null.  */
    private var expansionFile: Any? = null

    /** com.android.vending.expansion.zipfile.ZipResourceFile's getInputStream() or null.  */
    private var expansionFileMethod: Method? = null


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

    // Events

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
     * This method is called by SDL if SDL did not handle a message itself.
     * This happens if a received message contains an unsupported command.
     * Method can be overwritten to handle Messages in a different class.
     * @param command the command of the message.
     * @param param the parameter of the message. May be null.
     * @return if the message was handled in overridden method.
     */
    @Suppress("UNUSED_PARAMETER")
    protected fun onUnhandledMessage(command: Int, param: Any): Boolean {
        Log.v(TAG, "onUnhandledMessage()")
        return false
    }

    /**
     * A Handler class for Messages from native SDL applications.
     * It uses current Activities as target (e.g. for the title).
     * static to prevent implicit references to enclosing object.
     */
    protected class SDLCommandHandler(private val context: Context) : Handler() {
        override fun handleMessage(msg: Message) {
            when (msg.arg1) {
                COMMAND_CHANGE_TITLE -> if (context is Activity) {
                    context.title = msg.obj as String
                } else {
                    Log.e(TAG, "Error changing title, getContext() didn't return an Activity")
                }
                COMMAND_SET_KEEP_SCREEN_ON -> {
                    val window = (context as? Activity)?.window ?: return
                    if (msg.obj as? Int != 0) {
                        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    } else {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    }
                }
                else -> if (context is SDLActivity && !context.onUnhandledMessage(msg.arg1, msg.obj)) {
                    Log.e(TAG, "error handling message, command is " + msg.arg1)
                }
            }
        }
    }

    // Send a message from the SDLMain thread
    private fun sendCommand(command: Int, data: Any?): Boolean {
        val msg = commandHandler.obtainMessage()
        msg.arg1 = command
        msg.obj = data
        return commandHandler.sendMessage(msg)
    }

    /**
     * This method is called by SDL using JNI.
     * @return result of getSystemService(name) but executed on UI thread.
     */
    fun getSystemServiceFromUiThread(name: String): Any? {
        return context.getSystemService(name)
    }

    /**
     * This method is called by SDL using JNI.
     * @return an InputStream on success or null if no expansion file was used.
     * @throws IOException on errors. Message is set for the SDL error message.
     */
    @Throws(IOException::class)
    fun openAPKExpansionInputStream(fileName: String): InputStream? {
        // Get a ZipResourceFile representing a merger of both the main and patch files
        if (expansionFile == null) {
            val mainHint = nativeGetHint("SDL_ANDROID_APK_EXPANSION_MAIN_FILE_VERSION") ?: return null // no expansion use if no main version was set
            val patchHint = nativeGetHint("SDL_ANDROID_APK_EXPANSION_PATCH_FILE_VERSION") ?: return null // no expansion use if no patch version was set

            val mainVersion: Int?
            val patchVersion: Int?
            try {
                mainVersion = Integer.valueOf(mainHint)
                patchVersion = Integer.valueOf(patchHint)
            } catch (ex: NumberFormatException) {
                ex.printStackTrace()
                throw IOException("No valid file versions set for APK expansion files", ex)
            }

            try {
                // To avoid direct dependency on Google APK expansion library that is
                // not a part of Android SDK we access it using reflection
                expansionFile = Class.forName("com.android.vending.expansion.zipfile.APKExpansionSupport")
                        .getMethod("getAPKExpansionZipFile", Context::class.java, Int::class.javaPrimitiveType, Int::class.javaPrimitiveType)
                        .invoke(null, this, mainVersion, patchVersion)

                expansionFileMethod = expansionFile!!.javaClass
                        .getMethod("getInputStream", String::class.java)
            } catch (ex: Exception) {
                ex.printStackTrace()
                expansionFile = null
                expansionFileMethod = null
                throw IOException("Could not access APK expansion support library", ex)
            }
        }

        // Get an input stream for a known file inside the expansion file ZIPs
        val fileStream: InputStream?
        try {
            fileStream = expansionFileMethod?.invoke(expansionFile, fileName) as? InputStream
        } catch (ex: Exception) {
            // calling "getInputStream" failed
            ex.printStackTrace()
            throw IOException("Could not open stream from APK expansion file", ex)
        }

        if (fileStream == null) {
            // calling "getInputStream" was successful but null was returned
            throw IOException("Could not find path in APK expansion file")
        }

        return fileStream
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

    /** Called by onPause or surfaceDestroyed. Even if surfaceDestroyed
     * is the first to be called, mIsSurfaceReady should still be set
     * to 'true' during the call to onPause (in a usual scenario).
     */
    private fun handlePause() {
        Log.v(TAG, "handlePause()")
        if (!this.mIsPaused && this.mIsSurfaceReady) {
            this.mIsPaused = true
            this.nativePause()
            this.enableSensor(Sensor.TYPE_ACCELEROMETER, false)
        }
    }

    /** Called by onResume or surfaceCreated. An actual resume should be done only when the surface is ready.
     * Note: Some Android variants may send multiple surfaceChanged events, so we don't need to resume
     * every time we get one of those events, only if it comes after surfaceDestroyed
     */
    private fun handleResume() {
        Log.v(TAG, "handleResume()")
        if (this.mIsPaused && this.mIsSurfaceReady && this.mHasFocus) {
            this.mIsPaused = false
            this.nativeResume()
            this.handleSurfaceResume()
        }
    }

    // C functions we call

    private external fun render(): Int
    private external fun nativeInit(): Int
    private external fun nativeQuit()
    private external fun nativePause()
    private external fun nativeResume()
    private external fun onNativeResize(x: Int, y: Int, format: Int, rate: Float)


    external override fun onNativeKeyDown(keycode: Int)
    external override fun onNativeKeyUp(keycode: Int)
    external override fun onNativeMouse(button: Int, action: Int, x: Float, y: Float)
    external override fun onNativeTouch(touchDevId: Int, pointerFingerId: Int,
                                    action: Int, x: Float,
                                    y: Float, p: Float)

    private external fun onNativeAccel(x: Float, y: Float, z: Float)
    private external fun onNativeSurfaceChanged()
    private external fun onNativeSurfaceDestroyed()
    private external fun nativeGetHint(name: String): String?

    /** Called by SDL using JNI. */
    @Suppress("unused")
    private fun setActivityTitle(title: String): Boolean {
        // Called from SDLMain() thread and can't directly affect the view
        return sendCommand(COMMAND_CHANGE_TITLE, title)
    }

    /** Called by SDL using JNI. */
    @Suppress("unused")
    private fun sendMessage(command: Int, param: Int): Boolean {
        return sendCommand(command, param)
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

    // Interface conformance!

    // Sensors
    // Lazy to avoid accessing context before onCreate!
    private val mSensorManager: SensorManager by lazy { context!!.getSystemService(Context.SENSOR_SERVICE) as SensorManager }

    // Keep track of the surface size to normalize touch events
    // Start with non-zero values to avoid potential division by zero
    override var mWidth: Float = 1.0f
    override var mHeight: Float = 1.0f

    private fun handleSurfaceResume() {
        Log.v(TAG, "handleSurfaceResume()")
        mSurface.isFocusable = true
        mSurface.isFocusableInTouchMode = true
        mSurface.requestFocus()
        mSurface.setOnKeyListener(this)
        mSurface.setOnTouchListener(this)
        enableSensor(Sensor.TYPE_ACCELEROMETER, true)
    }

    override fun surfaceCreated(holder: SurfaceHolder?) {
        Log.v(TAG, "surfaceCreated()")
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

        // This is the entry point to the C app.
        // Start up the C app thread and enable sensor input for the first time
        this.nativeInit()
        enableSensor(Sensor.TYPE_ACCELEROMETER, true)
        Choreographer.getInstance().postFrameCallback(this)


        if (mHasFocus) {
            handleSurfaceResume()
        }
    }

    override fun doFrame(frameTimeNanos: Long) {
        Choreographer.getInstance().postFrameCallback(this)
        this.render()
    }

    // Called when we lose the surface
    override fun surfaceDestroyed(holder: SurfaceHolder) {
        Log.v(TAG, "surfaceDestroyed()")
        // Call this *before* setting mIsSurfaceReady to 'false'
        handlePause()
        mIsSurfaceReady = false
        onNativeSurfaceDestroyed()

        // Send a quit message to the application
        // This eventually stops the run loop and nulls the native SDL.window
        // nativeQuit()
        Choreographer.getInstance().removeFrameCallback(this)
        enableSensor(Sensor.TYPE_ACCELEROMETER, false)
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

    override fun onAccuracyChanged(sensor: Sensor, accuracy: Int) {
        // TODO
    }

    override fun onSensorChanged(event: SensorEvent) {
        if (event.sensor.type != Sensor.TYPE_ACCELEROMETER) return

        val x: Float
        val y: Float
        when (display.rotation) {
            ROTATION_90 -> {
                x = -event.values[1]
                y = event.values[0]
            }
            ROTATION_270 -> {
                x = event.values[1]
                y = -event.values[0]
            }
            ROTATION_180 -> {
                x = -event.values[1]
                y = -event.values[0]
            }
            else -> {
                x = event.values[0]
                y = event.values[1]
            }
        }

        onNativeAccel(
            -x / SensorManager.GRAVITY_EARTH,
            y / SensorManager.GRAVITY_EARTH,
            event.values[2] / SensorManager.GRAVITY_EARTH
        )
    }
}
