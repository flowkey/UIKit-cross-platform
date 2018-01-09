package org.libsdl.app

import java.io.IOException
import java.io.InputStream
import java.util.ArrayList
import java.util.Collections
import java.util.Comparator
import java.lang.reflect.Method

import android.app.*
import android.content.*
import android.view.*
import android.widget.RelativeLayout
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import android.os.*
import android.util.Log
import android.util.SparseArray
import android.graphics.*
import android.media.*
import android.hardware.*
import android.content.pm.ActivityInfo
import android.view.KeyEvent.*
import kotlin.math.min

private val TAG = "SDL"

open class SDLActivity : Activity(),
        View.OnKeyListener, View.OnTouchListener, SensorEventListener,
        View.OnGenericMotionListener, SurfaceHolder.Callback {
    /**
     * This method is called by SDL before loading the native shared libraries.
     * It can be overridden to provide names of shared libraries to be loaded.
     * The default implementation returns the defaults. It never returns null.
     * An array returned by a new implementation must at least contain "SDL2".
     * Also keep in mind that the order the libraries are loaded may matter.
     * @return names of shared libraries to be loaded (e.g. "SDL2", "main").
     */
    protected open val libraries: Array<String> get() = arrayOf("SDL2")

    /**
     * This method is called by SDL before starting the native application thread.
     * It can be overridden to provide the arguments after the application name.
     * The default implementation returns an empty array. It never returns null.
     * @return arguments for the native application.
     */
    protected open val arguments: Array<String> get() = arrayOf()

    // Handler for the messages
    private val commandHandler by lazy { SDLCommandHandler(this) }

    // APK expansion files support

    /** com.android.vending.expansion.zipfile.ZipResourceFile object or null.  */
    private var expansionFile: Any? = null

    /** com.android.vending.expansion.zipfile.ZipResourceFile's getInputStream() or null.  */
    private var expansionFileMethod: Method? = null


    // Message Box

    /** Result of current messagebox. Also used for blocking the calling thread.  */
    private val messageboxSelection = IntArray(1)

    /** Id of current dialog.  */
    private var dialogs = 0

    // Load the .so
    private fun loadLibraries() {
        for (lib in libraries) {
            System.loadLibrary(lib)
        }
    }

    // Setup
    override fun onCreate(savedInstanceState: Bundle?) {
        Log.v(TAG, "Device: " + android.os.Build.DEVICE)
        Log.v(TAG, "Model: " + android.os.Build.MODEL)
        Log.v(TAG, "onCreate(): " + this)
        super.onCreate(savedInstanceState)

        // Load shared libraries
        var errorMsgBrokenLib = ""
        try {
            loadLibraries()
        } catch (e: UnsatisfiedLinkError) {
            System.err.println(e.message)
            mBrokenLibraries = true
            errorMsgBrokenLib = e.message!!
        } catch (e: Exception) {
            System.err.println(e.message)
            mBrokenLibraries = true
            errorMsgBrokenLib = e.message!!
        }

        if (mBrokenLibraries) {
            val dlgAlert = AlertDialog.Builder(this)
            dlgAlert.setMessage("An error occurred while trying to start the application. Please try again and/or reinstall."
                    + System.getProperty("line.separator")
                    + System.getProperty("line.separator")
                    + "Error: " + errorMsgBrokenLib)
            dlgAlert.setTitle("SDL Error")
            dlgAlert.setPositiveButton("Exit") { _, _ ->
                // if this button is clicked, close current activity
                this.finish()
            }
            dlgAlert.setCancelable(false)
            dlgAlert.create().show()

            return
        }

        // Set up the surface
        val surface = SurfaceView(application)
        // Enables the alpha value for colors on the SDLSurface
        // which makes the VideoJNI SurfaceView behind it visible
        surface.holder.setFormat(PixelFormat.RGBA_8888)
        surface.isFocusable = true
        surface.isFocusableInTouchMode = true
        surface.requestFocus()
        surface.holder.addCallback(this)
        surface.setOnKeyListener(this)
        surface.setOnTouchListener(this)
        surface.setOnGenericMotionListener(this)
        mSurface = surface


        mJoystickHandler = SDLJoystickHandler(this)

        mLayout = RelativeLayout(this)
        mLayout!!.addView(surface)
        setContentView(mLayout)

        // Get filename from "Open with" of another application
        val filename = intent?.data?.path
        if (filename != null) {
            Log.v(TAG, "Got filename: " + filename)
            this.onNativeDropFile(filename)
        }
    }

    // Events
    override fun onPause() {
        Log.v(TAG, "onPause()")
        super.onPause()

        if (this.mBrokenLibraries) return
        this.handlePause()
    }

    override fun onResume() {
        Log.v(TAG, "onResume()")
        super.onResume()

        if (this.mBrokenLibraries) return
        this.handleResume()
    }


    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        Log.v(TAG, "onWindowFocusChanged(): " + hasFocus)

        if (this.mBrokenLibraries) return

        this.mHasFocus = hasFocus
        if (hasFocus) {
            handleSurfaceResume()
        }
    }

    override fun onLowMemory() {
        Log.v(TAG, "onLowMemory()")
        super.onLowMemory()

        if (this.mBrokenLibraries) return
        this.nativeLowMemory()
    }

    override fun onDestroy() {
        Log.v(TAG, "onDestroy()")

        if (mBrokenLibraries) {
            return super.onDestroy()
        }

        // Send a quit message to the application
        this.mExitCalledFromJava = true
        this.nativeQuit()

        // FIXME: Now wait for the SDL thread to quit

        super.onDestroy()
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        if (this.mBrokenLibraries) return false

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
    protected fun onUnhandledMessage(command: Int, param: Any): Boolean {
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
                    Log.e(TAG, "error handling message, getContext() returned no Activity")
                }
                COMMAND_SET_KEEP_SCREEN_ON -> {
                    val window = (context as Activity).window
                    if (window != null) {
                        if (msg.obj as? Int != 0) {
                            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        } else {
                            window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        }
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
        val lock = Object()
        var result: Any? = null
        var foundResult = false
        synchronized(lock) {
            runOnUiThread {
                synchronized(lock) {
                    result = getSystemService(name)
                    foundResult = true
                    lock.notify()
                }
            }

            if (!foundResult) {
                try {
                    lock.wait()
                } catch (ex: InterruptedException) {
                    ex.printStackTrace()
                }
            }
        }
        return result
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

    /**
     * This method is called by SDL using JNI.
     * Shows the messagebox from UI thread and block calling thread.
     * buttonFlags, buttonIds and buttonTexts must have same length.
     * @param buttonFlags array containing flags for every button.
     * @param buttonIds array containing id for every button.
     * @param buttonTexts array containing text for every button.
     * @param colors null for default or array of length 5 containing colors.
     * @return button id or -1.
     */
    fun messageboxShowMessageBox(
            flags: Int,
            title: String,
            message: String,
            buttonFlags: IntArray,
            buttonIds: IntArray,
            buttonTexts: Array<String>,
            colors: IntArray): Int {

        messageboxSelection[0] = -1

        // sanity checks

        if (buttonFlags.size != buttonIds.size && buttonIds.size != buttonTexts.size) {
            return -1 // implementation broken
        }

        // collect arguments for Dialog

        val args = Bundle()
        args.putInt("flags", flags)
        args.putString("title", title)
        args.putString("message", message)
        args.putIntArray("buttonFlags", buttonFlags)
        args.putIntArray("buttonIds", buttonIds)
        args.putStringArray("buttonTexts", buttonTexts)
        args.putIntArray("colors", colors)

        // trigger Dialog creation on UI thread

        runOnUiThread { showDialog(dialogs++, args) }

        // block the calling thread

        synchronized(messageboxSelection) {
            try {
                (messageboxSelection as? Object)?.wait()
            } catch (ex: InterruptedException) {
                ex.printStackTrace()
                return -1
            }

        }

        // return selected value

        return messageboxSelection[0]
    }

    override fun onCreateDialog(ignore: Int, args: Bundle): Dialog? {
        // TODO set values from "flags" to messagebox dialog

        // get colors

        val colors = args.getIntArray("colors")
        val backgroundColor: Int
        val textColor: Int
        val buttonBorderColor: Int
        val buttonBackgroundColor: Int
        val buttonSelectedColor: Int
        if (colors != null) {
            var i = -1
            backgroundColor = colors[++i]
            textColor = colors[++i]
            buttonBorderColor = colors[++i]
            buttonBackgroundColor = colors[++i]
            buttonSelectedColor = colors[++i]
        } else {
            backgroundColor = Color.TRANSPARENT
            textColor = Color.TRANSPARENT
            buttonBorderColor = Color.TRANSPARENT
            buttonBackgroundColor = Color.TRANSPARENT
            buttonSelectedColor = Color.TRANSPARENT
        }

        // create dialog with title and a listener to wake up calling thread

        val dialog = Dialog(this)
        dialog.setTitle(args.getString("title"))
        dialog.setCancelable(false)
        dialog.setOnDismissListener {
            synchronized(messageboxSelection) {
                (messageboxSelection as? Object)?.notify()
            }
        }

        // create text

        val message = TextView(this)
        message.gravity = Gravity.CENTER
        message.text = args.getString("message")
        if (textColor != Color.TRANSPARENT) {
            message.setTextColor(textColor)
        }

        // create buttons

        val buttonFlags = args.getIntArray("buttonFlags")
        val buttonIds = args.getIntArray("buttonIds")
        val buttonTexts = args.getStringArray("buttonTexts")

        val mapping = SparseArray<Button>()

        val buttons = LinearLayout(this)
        buttons.orientation = LinearLayout.HORIZONTAL
        buttons.gravity = Gravity.CENTER
        for (i in buttonTexts!!.indices) {
            val button = Button(this)
            val id = buttonIds!![i]
            button.setOnClickListener {
                messageboxSelection[0] = id
                dialog.dismiss()
            }
            if (buttonFlags!![i] != 0) {
                // see SDL_messagebox.h
                if (buttonFlags[i] and 0x00000001 != 0) {
                    mapping.put(KEYCODE_ENTER, button)
                }
                if (buttonFlags[i] and 0x00000002 != 0) {
                    mapping.put(111, button) /* API 11: KeyEvent.KEYCODE_ESCAPE */
                }
            }
            button.text = buttonTexts[i]
            if (textColor != Color.TRANSPARENT) {
                button.setTextColor(textColor)
            }
            if (buttonBorderColor != Color.TRANSPARENT) {
                // TODO set color for border of messagebox button
            }
            if (buttonBackgroundColor != Color.TRANSPARENT) {
                val drawable = button.background
                if (drawable == null) {
                    // setting the color this way removes the style
                    button.setBackgroundColor(buttonBackgroundColor)
                } else {
                    // setting the color this way keeps the style (gradient, padding, etc.)
                    drawable.setColorFilter(buttonBackgroundColor, PorterDuff.Mode.MULTIPLY)
                }
            }
            if (buttonSelectedColor != Color.TRANSPARENT) {
                // TODO set color for selected messagebox button
            }
            buttons.addView(button)
        }

        // create content

        val content = LinearLayout(this)
        content.orientation = LinearLayout.VERTICAL
        content.addView(message)
        content.addView(buttons)
        if (backgroundColor != Color.TRANSPARENT) {
            content.setBackgroundColor(backgroundColor)
        }

        // add content to dialog and return

        dialog.setContentView(content)
        dialog.setOnKeyListener(DialogInterface.OnKeyListener { _, keyCode, event ->
            val button = mapping.get(keyCode)
            if (button != null) {
                if (event.action == ACTION_UP) {
                    button.performClick()
                }
                return@OnKeyListener true // also for ignored actions
            }
            false
        })

        return dialog
    }

    // Keep track of the paused state
    var mIsPaused = false
    var mIsSurfaceReady = false
    var mHasFocus = false
    var mExitCalledFromJava = false

    /** If shared libraries (e.g. SDL or the native application) could not be loaded.  */
    var mBrokenLibraries = false

    // If we want to separate mouse and touch events.
    // This is only toggled in native code when a hint is set!
    var mSeparateMouseAndTouch = false

    // Main components
    private var mSurface: SurfaceView? = null
    var mTextEdit: View? = null
    var mLayout: RelativeLayout? = null
    private var mJoystickHandler: SDLJoystickHandler? = null

    // This is what SDL runs in. It invokes SDL_main(), eventually
    var mSDLThread: Thread? = null
    var isSurfaceInitialized = false

    // Audio
    protected var mAudioTrack: AudioTrack? = null
    protected var mAudioRecord: AudioRecord? = null


    /** Called by onPause or surfaceDestroyed. Even if surfaceDestroyed
     * is the first to be called, mIsSurfaceReady should still be set
     * to 'true' during the call to onPause (in a usual scenario).
     */
    fun handlePause() {
        if (!this.mIsPaused && this.mIsSurfaceReady) {
            this.mIsPaused = true
            this.nativePause()
            enableSensor(Sensor.TYPE_ACCELEROMETER, false)
        }
    }

    /** Called by onResume or surfaceCreated. An actual resume should be done only when the surface is ready.
     * Note: Some Android variants may send multiple surfaceChanged events, so we don't need to resume
     * every time we get one of those events, only if it comes after surfaceDestroyed
     */
    fun handleResume() {
        if (this.mIsPaused && this.mIsSurfaceReady && this.mHasFocus) {
            this.mIsPaused = false
            this.nativeResume()
            handleSurfaceResume()
        }
    }

    /* The native thread has finished */
    fun handleNativeExit() {
        isSurfaceInitialized = false
        finish()
    }


    companion object {
        // Messages from the SDLMain thread
        internal val COMMAND_CHANGE_TITLE = 1
        internal val COMMAND_SET_KEEP_SCREEN_ON = 5

        protected val COMMAND_USER = 0x8000
    }

    // C functions we call

    external fun render(): Int
    external fun nativeInit(arguments: Any): Int
    external fun nativeLowMemory()
    external fun nativeQuit()
    external fun nativePause()
    external fun nativeResume()
    external fun onNativeDropFile(filename: String)
    external fun onNativeResize(x: Int, y: Int, format: Int, rate: Float)
    external fun onNativePadDown(device_id: Int, keycode: Int): Int
    external fun onNativePadUp(device_id: Int, keycode: Int): Int
    external fun onNativeJoy(device_id: Int, axis: Int,
                             value: Float)

    external fun onNativeHat(device_id: Int, hat_id: Int,
                             x: Int, y: Int)

    external fun onNativeKeyDown(keycode: Int)
    external fun onNativeKeyUp(keycode: Int)
    external fun onNativeKeyboardFocusLost()
    external fun onNativeMouse(button: Int, action: Int, x: Float, y: Float)
    external fun onNativeTouch(touchDevId: Int, pointerFingerId: Int,
                               action: Int, x: Float,
                               y: Float, p: Float)

    external fun onNativeAccel(x: Float, y: Float, z: Float)
    external fun onNativeSurfaceChanged()
    external fun onNativeSurfaceDestroyed()
    external fun nativeAddJoystick(device_id: Int, name: String?,
                                   is_accelerometer: Int, nbuttons: Int,
                                   naxes: Int, nhats: Int, nballs: Int): Int

    external fun nativeRemoveJoystick(device_id: Int): Int
    external fun nativeGetHint(name: String): String?

    /**
     * This method is called by SDL using JNI.
     */
    fun setActivityTitle(title: String): Boolean {
        // Called from SDLMain() thread and can't directly affect the view
        return sendCommand(COMMAND_CHANGE_TITLE, title)
    }

    /**
     * This method is called by SDL using JNI.
     */
    fun sendMessage(command: Int, param: Int): Boolean {
        return sendCommand(command, param)
    }

    /**
     * This method is called by SDL using JNI.
     */
    private val context: Context get() = this

    /**
     * This method is called by SDL using JNI.
     */
    fun showTextInput(x: Int, y: Int, w: Int, h: Int): Boolean {
        // Transfer the task to the main thread as a Runnable
        return false //commandHandler.post(ShowTextInputTask(x, y, w, h))
    }

    /**
     * This method is called by SDL using JNI.
     */
    val nativeSurface: Surface get() = this.mSurface!!.holder.surface

    // Audio

    /**
     * This method is called by SDL using JNI.
     */
    fun audioOpen(sampleRate: Int, is16Bit: Boolean, isStereo: Boolean, desiredFrames: Int): Int {
        var desiredFrames = desiredFrames
        val channelConfig = if (isStereo) AudioFormat.CHANNEL_CONFIGURATION_STEREO else AudioFormat.CHANNEL_CONFIGURATION_MONO
        val audioFormat = if (is16Bit) AudioFormat.ENCODING_PCM_16BIT else AudioFormat.ENCODING_PCM_8BIT
        val frameSize = (if (isStereo) 2 else 1) * if (is16Bit) 2 else 1

        Log.v(TAG, "SDL audio: wanted " + (if (isStereo) "stereo" else "mono") + " " + (if (is16Bit) "16-bit" else "8-bit") + " " + sampleRate / 1000f + "kHz, " + desiredFrames + " frames buffer")

        // Let the user pick a larger buffer if they really want -- but ye
        // gods they probably shouldn't, the minimums are horrifyingly high
        // latency already
        desiredFrames = Math.max(desiredFrames, (AudioTrack.getMinBufferSize(sampleRate, channelConfig, audioFormat) + frameSize - 1) / frameSize)

        if (mAudioTrack == null) {
            mAudioTrack = AudioTrack(AudioManager.STREAM_MUSIC, sampleRate,
                    channelConfig, audioFormat, desiredFrames * frameSize, AudioTrack.MODE_STREAM)

            // Instantiating AudioTrack can "succeed" without an exception and the track may still be invalid
            // Ref: https://android.googlesource.com/platform/frameworks/base/+/refs/heads/master/media/java/android/media/AudioTrack.java
            // Ref: http://developer.android.com/reference/android/media/AudioTrack.html#getState()

            if (mAudioTrack?.state != AudioTrack.STATE_INITIALIZED) {
                Log.e(TAG, "Failed during initialization of Audio Track")
                mAudioTrack = null
                return -1
            }

            mAudioTrack?.play()
        }

        Log.v(TAG, "SDL audio: got " + (if (mAudioTrack!!.channelCount >= 2) "stereo" else "mono") + " " + (if (mAudioTrack!!.audioFormat == AudioFormat.ENCODING_PCM_16BIT) "16-bit" else "8-bit") + " " + mAudioTrack!!.sampleRate / 1000f + "kHz, " + desiredFrames + " frames buffer")

        return 0
    }

    /**
     * This method is called by SDL using JNI.
     */
    fun audioWriteShortBuffer(buffer: ShortArray) {
        var i = 0
        while (i < buffer.size) {
            val result = mAudioTrack!!.write(buffer, i, buffer.size - i)
            when {
                result > 0 -> i += result
                result == 0 -> try {
                    Thread.sleep(1)
                } catch (e: InterruptedException) {
                    // Nom nom
                }
                else -> {
                    Log.w(TAG, "SDL audio: error return from write(short)")
                    return
                }
            }
        }
    }

    /**
     * This method is called by SDL using JNI.
     */
    fun audioWriteByteBuffer(buffer: ByteArray) {
        var i = 0
        while (i < buffer.size) {
            val result = mAudioTrack!!.write(buffer, i, buffer.size - i)
            when {
                result > 0 -> i += result
                result == 0 -> try {
                    Thread.sleep(1)
                } catch (e: InterruptedException) {
                    // Nom nom
                }
                else -> {
                    Log.w(TAG, "SDL audio: error return from write(byte)")
                    return
                }
            }
        }
    }

    /**
     * This method is called by SDL using JNI.
     */
    fun captureOpen(sampleRate: Int, is16Bit: Boolean, isStereo: Boolean, desiredFrames: Int): Int {
        var desiredFrames = desiredFrames
        val channelConfig = if (isStereo) AudioFormat.CHANNEL_IN_STEREO else AudioFormat.CHANNEL_IN_MONO
        val audioFormat = if (is16Bit) AudioFormat.ENCODING_PCM_16BIT else AudioFormat.ENCODING_PCM_8BIT
        val frameSize = (if (isStereo) 2 else 1) * if (is16Bit) 2 else 1

        Log.v(TAG, "SDL capture: wanted " + (if (isStereo) "stereo" else "mono") + " " + (if (is16Bit) "16-bit" else "8-bit") + " " + sampleRate / 1000f + "kHz, " + desiredFrames + " frames buffer")

        // Let the user pick a larger buffer if they really want -- but ye
        // gods they probably shouldn't, the minimums are horrifyingly high
        // latency already
        desiredFrames = Math.max(desiredFrames, (AudioRecord.getMinBufferSize(sampleRate, channelConfig, audioFormat) + frameSize - 1) / frameSize)

        if (mAudioRecord == null) {
            mAudioRecord = AudioRecord(MediaRecorder.AudioSource.DEFAULT, sampleRate,
                    channelConfig, audioFormat, desiredFrames * frameSize)

            // see notes about AudioTrack state in audioOpen(), above. Probably also applies here.
            if (mAudioRecord!!.state != AudioRecord.STATE_INITIALIZED) {
                Log.e(TAG, "Failed during initialization of AudioRecord")
                mAudioRecord!!.release()
                mAudioRecord = null
                return -1
            }

            mAudioRecord!!.startRecording()
        }

        Log.v(TAG, "SDL capture: got " + (if (mAudioRecord!!.channelCount >= 2) "stereo" else "mono") + " " + (if (mAudioRecord!!.audioFormat == AudioFormat.ENCODING_PCM_16BIT) "16-bit" else "8-bit") + " " + mAudioRecord!!.sampleRate / 1000f + "kHz, " + desiredFrames + " frames buffer")

        return 0
    }

    /** This method is called by SDL using JNI.  */
    fun captureReadShortBuffer(buffer: ShortArray, blocking: Boolean): Int {
        // !!! FIXME: this is available in API Level 23. Until then, we always block.  :(
        //return mAudioRecord.read(buffer, 0, buffer.length, blocking ? AudioRecord.READ_BLOCKING : AudioRecord.READ_NON_BLOCKING);
        return mAudioRecord!!.read(buffer, 0, buffer.size)
    }

    /** This method is called by SDL using JNI.  */
    fun captureReadByteBuffer(buffer: ByteArray, blocking: Boolean): Int {
        // !!! FIXME: this is available in API Level 23. Until then, we always block.  :(
        //return mAudioRecord.read(buffer, 0, buffer.length, blocking ? AudioRecord.READ_BLOCKING : AudioRecord.READ_NON_BLOCKING);
        return mAudioRecord!!.read(buffer, 0, buffer.size)
    }


    /** This method is called by SDL using JNI.  */
    fun audioClose() {
        mAudioTrack?.stop()
        mAudioTrack?.release()
        mAudioTrack = null
    }

    /** This method is called by SDL using JNI.  */
    fun captureClose() {
        mAudioRecord?.stop()
        mAudioRecord?.release()
        mAudioRecord = null
    }


    // Input

    /**
     * This method is called by SDL using JNI.
     * @return an array which may be empty but is never null.
     */
    fun inputGetInputDeviceIds(sources: Int): IntArray {
        return InputDevice.getDeviceIds().fold(intArrayOf(0)) { result: IntArray, id: Int ->
            val device = InputDevice.getDevice(id)
            return if (device.sources and sources != 0) (result + device.id) else result
        }
    }

    // Joystick glue code, just a series of stubs that redirect to the SDLJoystickHandler instance
    private fun handleJoystickMotionEvent(event: MotionEvent): Boolean {
        return mJoystickHandler!!.handleMotionEvent(event)
    }

    /**
     * This method is called by SDL using JNI.
     */
    fun pollInputDevices() {
        if (isSurfaceInitialized) {
            mJoystickHandler?.pollInputDevices()
        }
    }

    // Check if a given device is considered a possible SDL joystick
    fun isDeviceSDLJoystick(deviceId: Int): Boolean {
        val device = InputDevice.getDevice(deviceId)
        // We cannot use InputDevice.isVirtual before API 16, so let's accept
        // only non-negative device ids (VIRTUAL_KEYBOARD equals -1)
        if (device == null || deviceId < 0) {
            return false
        }
        val sources = device.sources
        return sources and InputDevice.SOURCE_CLASS_JOYSTICK == InputDevice.SOURCE_CLASS_JOYSTICK ||
                sources and InputDevice.SOURCE_DPAD == InputDevice.SOURCE_DPAD ||
                sources and InputDevice.SOURCE_GAMEPAD == InputDevice.SOURCE_GAMEPAD
    }

    // Interface conformance!

    // Sensors
    // Lazy to avoid accessing context before onCreate!
    private val mSensorManager: SensorManager by lazy { getSystemService(Context.SENSOR_SERVICE) as SensorManager }
    private val mDisplay: Display by lazy { (getSystemService(Context.WINDOW_SERVICE) as WindowManager).defaultDisplay }

    // Keep track of the surface size to normalize touch events
    // Start with non-zero values to avoid potential division by zero
    private var mWidth: Float = 1.0f
    private var mHeight: Float = 1.0f

    private var isRunning = false

    private fun handleSurfaceResume() {
        mSurface?.isFocusable = true
        mSurface?.isFocusableInTouchMode = true
        mSurface?.requestFocus()
        mSurface?.setOnKeyListener(this)
        mSurface?.setOnTouchListener(this)
        enableSensor(Sensor.TYPE_ACCELEROMETER, true)
    }

    // unused:
    override fun surfaceCreated(holder: SurfaceHolder?) {}

    // Called when we lose the surface
    override fun surfaceDestroyed(holder: SurfaceHolder) {
        Log.v("SDL", "surfaceDestroyed()")
        // Call this *before* setting mIsSurfaceReady to 'false'
        this.handlePause()
        this.mIsSurfaceReady = false
        this.onNativeSurfaceDestroyed()
    }

    // Called when the surface is resized
    override fun surfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) {
        Log.v("SDL", "surfaceChanged()")

        var sdlFormat = 0x15151002 // SDL_PIXELFORMAT_RGB565 by default
        when (format) {
            PixelFormat.RGBA_8888 -> {
                Log.v("SDL", "pixel format RGBA_8888")
                sdlFormat = 0x16462004 // SDL_PIXELFORMAT_RGBA8888
            }
            PixelFormat.RGBX_8888 -> {
                Log.v("SDL", "pixel format RGBX_8888")
                sdlFormat = 0x16261804 // SDL_PIXELFORMAT_RGBX8888
            }
            PixelFormat.RGB_565 -> {
                Log.v("SDL", "pixel format RGB_565")
                sdlFormat = 0x15151002 // SDL_PIXELFORMAT_RGB565
            }
            PixelFormat.RGB_888 -> {
                Log.v("SDL", "pixel format RGB_888")
                // Not sure this is right, maybe SDL_PIXELFORMAT_RGB24 instead?
                sdlFormat = 0x16161804 // SDL_PIXELFORMAT_RGB888
            }
            else -> Log.w("SDL", "pixel format unknown " + format)
        }

        mWidth = width.toFloat()
        mHeight = height.toFloat()
        this.onNativeResize(width, height, sdlFormat, mDisplay.refreshRate)
        Log.v("SDL", "Window size: " + width + "x" + height)


        // Skip if the provided surface isn't in the requested orientation
        val skip =
                (requestedOrientation == ActivityInfo.SCREEN_ORIENTATION_PORTRAIT && mWidth > mHeight) ||
                (requestedOrientation == ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE && mWidth < mHeight)

        if (skip) {
            val min = Math.min(mWidth, mHeight)
            val max = Math.max(mWidth, mHeight)

            if (max / min < 1.20f) {
                // Special Patch for Square Resolution: Black Berry Passport
                Log.v("SDL", "Don't skip on such aspect-ratio. Could be a square resolution.")
            } else {
                Log.v("SDL", "Surface is not ready. Skipping creation for now...")
                return
            }
        }

        // Set mIsSurfaceReady to 'true' *before* making a call to handleResume
        mIsSurfaceReady = true
        onNativeSurfaceChanged()


        if (!isRunning) {
            // This is the entry point to the C app.
            // Start up the C app thread and enable sensor input for the first time
            isRunning = true

            this.nativeInit(this.arguments)
            enableSensor(Sensor.TYPE_ACCELEROMETER, true)

            val handler = Handler()
            var runnable: Runnable? = null

            val maxFrameTime = 1000.0 / 60.0

            runnable = Runnable {
                val timeTaken = this.render()
                val remainingFrameTime = (maxFrameTime - timeTaken).toLong()
                handler.postDelayed(runnable, remainingFrameTime)
            }

            handler.post(runnable)
        }

        if (mHasFocus) {
            handleSurfaceResume()
        }
    }


    // Key events
    override fun onKey(v: View, keyCode: Int, event: KeyEvent): Boolean {
        // Dispatch the different events depending on where they come from
        // Some SOURCE_JOYSTICK, SOURCE_DPAD or SOURCE_GAMEPAD are also SOURCE_KEYBOARD
        // So, we try to process them as JOYSTICK/DPAD/GAMEPAD events first, if that fails we try them as KEYBOARD
        //
        // Furthermore, it's possible a game controller has SOURCE_KEYBOARD and
        // SOURCE_JOYSTICK, while its key events arrive from the keyboard source
        // So, retrieve the device itself and check all of its sources
        if (this.isDeviceSDLJoystick(event.deviceId)) {
            // Note that we process events with specific key codes here
            if (event.action == ACTION_DOWN) {
                if (this.onNativePadDown(event.deviceId, keyCode) == 0) {
                    return true
                }
            } else if (event.action == ACTION_UP) {
                if (this.onNativePadUp(event.deviceId, keyCode) == 0) {
                    return true
                }
            }
        }

        if (event.source and InputDevice.SOURCE_KEYBOARD != 0) {
            if (event.action == ACTION_DOWN) {
                //Log.v("SDL", "key down: " + keyCode);
                this.onNativeKeyDown(keyCode)
                return true
            } else if (event.action == ACTION_UP) {
                //Log.v("SDL", "key up: " + keyCode);
                this.onNativeKeyUp(keyCode)
                return true
            }
        }

        if (event.source and InputDevice.SOURCE_MOUSE != 0) {
            // on some devices key events are sent for mouse BUTTON_BACK/FORWARD presses
            // they are ignored here because sending them as mouse input to SDL is messy
            if (keyCode == KEYCODE_BACK || keyCode == KEYCODE_FORWARD) {
                when (event.action) {
                    ACTION_DOWN, ACTION_UP ->
                        // mark the event as handled or it will be handled by system
                        // handling KEYCODE_BACK by system will call onBackPressed()
                        return true
                }
            }
        }

        return false
    }

    // Touch events
    override fun onTouch(v: View, event: MotionEvent): Boolean {
        /* Ref: http://developer.android.com/training/gestures/multi.html */
        val touchDevId = event.deviceId
        val action = event.actionMasked

        data class TouchValues(val fingerId: Int, val x: Float, val y: Float, val p: Float)

        fun MotionEvent.touchValues(i: Int): TouchValues {
            return TouchValues(
                    getPointerId(i),
                    getX(i) / mWidth,
                    getY(i) / mHeight,
                    // Pressure can be > 1.0 on some devices. See getPressure(i) docs.
                    min(this.getPressure(i), 1.0f)
            )
        }

        if (event.source == InputDevice.SOURCE_MOUSE && mSeparateMouseAndTouch) {
            val mouseButton = try { event.buttonState } catch (e: Exception) { 1 } // 1 is left button
            this.onNativeMouse(mouseButton, action, event.getX(0), event.getY(0))
            return true
        }

        when (action) {
            MotionEvent.ACTION_MOVE -> {
                for (i in 0 until event.pointerCount) {
                    val (fingerId, x, y, p) = event.touchValues(i)
                    this.onNativeTouch(touchDevId, fingerId, action, x, y, p)
                }
            }

            MotionEvent.ACTION_UP, MotionEvent.ACTION_DOWN -> {
                // Primary pointer up/down, the index is always zero
                val (fingerId, x, y, p) = event.touchValues(event.actionIndex)
                this.onNativeTouch(touchDevId, fingerId, action, x, y, p)
            }

            MotionEvent.ACTION_POINTER_UP, MotionEvent.ACTION_POINTER_DOWN -> {
                val (fingerId, x, y, p) = event.touchValues(event.actionIndex)
                this.onNativeTouch(touchDevId, fingerId, action, x, y, p)
            }

            MotionEvent.ACTION_CANCEL -> {
                for (i in 0 until event.pointerCount) {
                    val (fingerId, x, y, p) = event.touchValues(i)
                    this.onNativeTouch(touchDevId, fingerId, MotionEvent.ACTION_UP, x, y, p)
                }
            }
        }

        return true
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
        if (event.sensor.type == Sensor.TYPE_ACCELEROMETER) {
            val x: Float
            val y: Float
            when (mDisplay.rotation) {
                Surface.ROTATION_90 -> {
                    x = -event.values[1]
                    y = event.values[0]
                }
                Surface.ROTATION_270 -> {
                    x = event.values[1]
                    y = -event.values[0]
                }
                Surface.ROTATION_180 -> {
                    x = -event.values[1]
                    y = -event.values[0]
                }
                else -> {
                    x = event.values[0]
                    y = event.values[1]
                }
            }

            this.onNativeAccel(-x / SensorManager.GRAVITY_EARTH,
                    y / SensorManager.GRAVITY_EARTH,
                    event.values[2] / SensorManager.GRAVITY_EARTH)
        }
    }

    // Generic Motion (mouse hover, joystick...) events go here
    override fun onGenericMotion(v: View, event: MotionEvent): Boolean {
        when (event.source) {
            InputDevice.SOURCE_JOYSTICK, InputDevice.SOURCE_GAMEPAD, InputDevice.SOURCE_DPAD ->
                return this.handleJoystickMotionEvent(event)

            InputDevice.SOURCE_MOUSE -> {
                val action = event.actionMasked
                when (action) {
                    MotionEvent.ACTION_SCROLL -> {
                        val x = event.getAxisValue(MotionEvent.AXIS_HSCROLL, 0)
                        val y = event.getAxisValue(MotionEvent.AXIS_VSCROLL, 0)
                        this.onNativeMouse(0, action, x, y)
                        return true
                    }

                    MotionEvent.ACTION_HOVER_MOVE -> {
                        val x = event.getX(0)
                        val y = event.getY(0)
                        this.onNativeMouse(0, action, x, y)
                        return true
                    }
                }
            }
        }

        return false // Event was not managed
    }
}

internal class SDLJoystickHandler (private val activity: SDLActivity) {
    private val mJoysticks: ArrayList<SDLJoystick> = ArrayList()

    internal data class SDLJoystick
        (val deviceId: Int,
         val name: String,
         val axes: ArrayList<InputDevice.MotionRange> = ArrayList(),
         val hats: ArrayList<InputDevice.MotionRange> = ArrayList())

    internal class RangeComparator : Comparator<InputDevice.MotionRange> {
        override fun compare(arg0: InputDevice.MotionRange, arg1: InputDevice.MotionRange): Int {
            return arg0.axis - arg1.axis
        }
    }

    fun pollInputDevices() {
        val deviceIds = InputDevice.getDeviceIds()
        // It helps processing the device ids in reverse order
        // For example, in the case of the XBox 360 wireless dongle,
        // so the first controller seen by SDL matches what the receiver
        // considers to be the first controller
        deviceIds.reversed().forEach { i ->
            var joystick = getJoystick(deviceIds[i])
            if (joystick != null) { return } // we already have this joystick cached

            val joystickDevice = InputDevice.getDevice(deviceIds[i])
            if (activity.isDeviceSDLJoystick(deviceIds[i])) {
                joystick = SDLJoystick(deviceIds[i], joystickDevice.name)

                val ranges = joystickDevice.motionRanges
                Collections.sort<InputDevice.MotionRange>(ranges, RangeComparator())
                for (range in ranges) {
                    if (range.source and InputDevice.SOURCE_CLASS_JOYSTICK == 0) break

                    when (range.axis) {
                        MotionEvent.AXIS_HAT_X, MotionEvent.AXIS_HAT_Y ->
                            joystick.hats.add(range)
                        else ->
                            joystick.axes.add(range)
                    }
                }

                mJoysticks.add(joystick)
                activity.nativeAddJoystick(joystick.deviceId, joystick.name, 0, -1,
                        joystick.axes.size, joystick.hats.size / 2, 0)
            }
        }

        /* Check removed devices */
        mJoysticks.map { it.deviceId }
                // get all cached joysticks that aren't present in current deviceIds:
                .filterNotTo(ArrayList()) { deviceIds.contains(it) }
                .forEach { deviceId ->
                    activity.nativeRemoveJoystick(deviceId)
                    mJoysticks.removeAll { it.deviceId == deviceId }
                }
    }

    private fun getJoystick(device_id: Int): SDLJoystick? {
        return mJoysticks.firstOrNull { it.deviceId == device_id }
    }

    fun handleMotionEvent(event: MotionEvent): Boolean {
        if (event.source and InputDevice.SOURCE_JOYSTICK == 0) return true

        val actionPointerIndex = event.actionIndex
        when (event.actionMasked) {
            MotionEvent.ACTION_MOVE -> {
                val joystick = getJoystick(event.deviceId) ?: return true

                for (i in joystick.axes.indices) {
                    val range = joystick.axes[i]
                    /* Normalize the value to -1...1 */
                    val value = (event.getAxisValue(range.axis, actionPointerIndex) - range.min) / range.range * 2.0f - 1.0f
                    activity.onNativeJoy(joystick.deviceId, i, value)
                }

                for (i in 0 until joystick.hats.size step 2) {
                    val hatX = Math.round(event.getAxisValue(joystick.hats[i].axis, actionPointerIndex))
                    val hatY = Math.round(event.getAxisValue(joystick.hats[i + 1].axis, actionPointerIndex))
                    activity.onNativeHat(joystick.deviceId, i / 2, hatX, hatY)
                }
            }
        }

        return true
    }
}
