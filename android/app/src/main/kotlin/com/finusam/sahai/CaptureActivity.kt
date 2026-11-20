package com.finusam.sahai

import android.content.Intent
import android.widget.Toast
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterActivityLaunchConfigs.BackgroundMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * The small capture dialog over whatever is on screen, opened by the
 * home-screen widget or by text shared from another app (decision 0007,
 * E-009, E-017). A see-through window that runs the `captureMain` Dart
 * entry point instead of the whole app. Save is always the user's tap in
 * Dart; this class only passes the shared text in and closes the window.
 *
 * Nothing here logs: the text is the user's capture.
 */
class CaptureActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private var hadFocus = false

    override fun getDartEntrypointFunctionName() = "captureMain"

    override fun getBackgroundMode() = BackgroundMode.transparent

    // The text field asks for the keyboard on Flutter's first frame, which
    // comes before this see-through window gets focus, so Android ignores
    // it. Once focus first arrives, the dialog asks again.
    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus && !hadFocus) {
            hadFocus = true
            channel?.invokeMethod("focused", null)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "request" -> result.success(
                    mapOf("text" to sharedText(intent), "source" to sourceOf(intent)),
                )
                "saved" -> {
                    // Shown by Android, so it stays up after this window closes
                    // (frame 17).
                    Toast.makeText(applicationContext, call.arguments as String, Toast.LENGTH_SHORT)
                        .show()
                    result.success(null)
                    finish()
                }
                "cancel" -> {
                    result.success(null)
                    finish()
                }
                else -> result.notImplemented()
            }
        }
        this.channel = channel
    }

    private companion object {
        const val CHANNEL = "sahai/capture_dialog"

        /** The text another app shared, or null when the widget opened the dialog. */
        fun sharedText(intent: Intent?): String? =
            if (intent?.action == Intent.ACTION_SEND) intent.getStringExtra(Intent.EXTRA_TEXT) else null

        /** Stored in the `captured` event's payload (M6 decision 5). */
        fun sourceOf(intent: Intent?): String =
            if (intent?.action == Intent.ACTION_SEND) "share" else "widget"
    }
}
