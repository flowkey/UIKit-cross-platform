package com.flowkey.uikit

import android.content.Context
import android.content.Context.MODE_PRIVATE

private const val FILE_NAME = "com.flowkey.uikit.UserDefaults"

@Suppress("unused")
class UserDefaults(private val context: Context) {
    private val preferences = context.getSharedPreferences(FILE_NAME, MODE_PRIVATE)

    fun has(key: String): Boolean {
        return preferences.contains(key)
    }

    fun getInt(key: String, defValue: Int): Int {
       return preferences.getInt(key, defValue)
    }

    fun getBoolean(key: String, defValue: Boolean): Boolean {
        return preferences.getBoolean(key, defValue)
    }

    fun getString(key: String, defValue: String): String {
        return preferences.getString(key, defValue) ?: defValue
    }

    fun setInt(key: String, value: Int) {
        preferences.edit().putInt(key, value).commit()
    }

    fun setBool(key: String, value: Boolean) {
        preferences.edit().putBoolean(key, value).commit()
    }

    fun setString(key: String, value: String) {
        preferences.edit().putString(key, value).commit()
    }
}