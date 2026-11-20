package com.finusam.sahai

import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * The app's main window. It also answers the small "sahai/app" channel
 * (tech plan, Send feedback): the version for About and the feedback
 * subject, and opening the email app with a draft. Sahai sends nothing
 * itself; the email app sends only when the user taps Send.
 */
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "version" -> result.success(versionName())
                    "sendFeedback" -> result.success(
                        openEmailDraft(
                            call.argument<String>("address") ?: "",
                            call.argument<String>("subject") ?: "",
                        ),
                    )
                    else -> result.notImplemented()
                }
            }
    }

    private fun versionName(): String? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            packageManager.getPackageInfo(
                packageName,
                PackageManager.PackageInfoFlags.of(0),
            ).versionName
        } else {
            @Suppress("DEPRECATION")
            packageManager.getPackageInfo(packageName, 0).versionName
        }

    /**
     * Opens an email draft with only the address and subject filled in; the
     * body stays empty so nothing about the user's tasks goes in. Returns
     * false when the phone has no email app.
     */
    private fun openEmailDraft(address: String, subject: String): Boolean {
        // mailto: limits the choice to email apps. The address and subject
        // are also passed as extras, which some email apps read instead.
        val uri = Uri.parse("mailto:${Uri.encode(address)}?subject=${Uri.encode(subject)}")
        val intent = Intent(Intent.ACTION_SENDTO, uri).apply {
            putExtra(Intent.EXTRA_EMAIL, arrayOf(address))
            putExtra(Intent.EXTRA_SUBJECT, subject)
        }
        return try {
            startActivity(intent)
            true
        } catch (e: ActivityNotFoundException) {
            false
        }
    }

    private companion object {
        const val CHANNEL = "sahai/app"
    }
}
