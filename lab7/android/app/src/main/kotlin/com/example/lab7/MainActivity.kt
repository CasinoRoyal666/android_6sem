package com.example.lab7

import android.content.ContentValues
import android.content.Context
import android.os.Build
import android.provider.MediaStore
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.OutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "file_helper"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "saveFileToDownloads") {
                val values = call.argument<Map<String, String>>("values")
                val content = call.argument<String>("content")
                val uri = saveFileToDownloads(applicationContext, values, content)
                result.success(uri.toString())
            } else {
                result.notImplemented()
            }
        }
    }

    private fun saveFileToDownloads(context: Context, values: Map<String, String>?, content: String?): String? {
        if (values == null || content == null) return null

        val resolver = context.contentResolver
        val contentValues = ContentValues().apply {
            put(MediaStore.Downloads.DISPLAY_NAME, values["display_name"])
            put(MediaStore.Downloads.MIME_TYPE, values["mime_type"])
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                put(MediaStore.Downloads.RELATIVE_PATH, values["relative_path"])
            }
        }

        val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues)
        uri?.let {
            resolver.openOutputStream(it)?.use { outputStream: OutputStream ->
                outputStream.write(content.toByteArray())
            }
        }

        return uri?.toString()
    }
}
