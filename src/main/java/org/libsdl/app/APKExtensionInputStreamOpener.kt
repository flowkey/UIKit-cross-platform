package main.java.org.libsdl.app

import android.content.Context
import java.io.IOException
import java.io.InputStream
import java.lang.reflect.Method

/**
 * Created by erik on 23.02.18.
 */
interface APKExtensionInputStreamOpener {

    /** com.android.vending.expansion.zipfile.ZipResourceFile object or null.  */
    var expansionFile: Any?

    /** com.android.vending.expansion.zipfile.ZipResourceFile's getInputStream() or null.  */
    var expansionFileMethod: Method?

    fun nativeGetHint(name: String): String?

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
}