package com.myprojectapp.projectx

import android.media.AudioManager
import android.view.WindowManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private companion object {
        const val MICROPHONE_CHANNEL = "samples.flutter.dev/microphone"
        const val SCREEN_CHANNEL = "app.channel.shared.data"
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Configure microphone channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MICROPHONE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "muteMicrophone" -> {
                        val audioManager = getSystemService(AUDIO_SERVICE) as AudioManager
                        audioManager.isMicrophoneMute = true
                        result.success(null)
                    }
                    "unmuteMicrophone" -> {
                        val audioManager = getSystemService(AUDIO_SERVICE) as AudioManager
                        audioManager.isMicrophoneMute = false
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        // Configure screen channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SCREEN_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "keepScreenOn" -> {
                        val enable = call.argument<Boolean>("enable") ?: false
                        keepScreenOn(enable)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun keepScreenOn(enable: Boolean) {
        runOnUiThread {
            if (enable) {
                window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            } else {
                window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            }
        }
    }
}
