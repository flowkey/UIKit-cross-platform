package main.java.org.libsdl.app

import android.app.Activity
import android.content.Context
import android.os.Handler
import android.os.Message
import android.util.Log
import android.view.WindowManager
import org.libsdl.app.SDLActivity

private val TAG = "SDLCommandHandler"

/**
 * A Handler class for Messages from native SDL applications.
 * It uses current Activities as target (e.g. for the title).
 * static to prevent implicit references to enclosing object.
 */
class SDLCommandHandler(private val context: Context) : Handler() {
    override fun handleMessage(msg: Message) {
        when (msg.arg1) {
            SDLActivity.COMMAND_CHANGE_TITLE -> if (context is Activity) {
                context.title = msg.obj as String
            } else {
                Log.e(TAG, "Error changing title, getContext() didn't return an Activity")
            }
            SDLActivity.COMMAND_SET_KEEP_SCREEN_ON -> {
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