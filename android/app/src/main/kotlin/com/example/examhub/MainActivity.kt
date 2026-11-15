package com.example.examhub

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "cloud.wiseliang.examhub/external")
            .setMethodCallHandler { call, result ->
                val intent: Intent
                when (call.method) {
                    "openPalmQuiz" -> {
                        intent = packageManager.getLaunchIntentForPackage("cloud.wiseliang.palmquiz")
                            ?: Intent(Intent.ACTION_VIEW, Uri.parse("https://wiseliang.cloud/palm-quiz/"))
                                .addCategory(Intent.CATEGORY_BROWSABLE)
                    }
                    "openExternal" -> {
                        val uri = call.argument<String>("url")?.let { Uri.parse(it) }
                        if (uri == null || uri.scheme !in listOf("https", "http") || uri.host.isNullOrBlank() || uri.userInfo != null) {
                            result.error("INVALID_URL", "Invalid website URL", null)
                            return@setMethodCallHandler
                        }
                        intent = Intent(Intent.ACTION_VIEW, uri).addCategory(Intent.CATEGORY_BROWSABLE)
                    }
                    else -> {
                        result.notImplemented()
                        return@setMethodCallHandler
                    }
                }
                try {
                    startActivity(intent)
                    result.success(true)
                } catch (_: ActivityNotFoundException) {
                    result.success(false)
                } catch (_: SecurityException) {
                    result.success(false)
                }
            }
    }
}
