package com.aitasadduq.arabic_ocr

import android.app.ActivityManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Small native helpers; see ios/Runner/AppDelegate.swift for the iOS side.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "arabic_ocr/platform")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "totalMemory" -> {
                        val info = ActivityManager.MemoryInfo()
                        (getSystemService(ACTIVITY_SERVICE) as ActivityManager).getMemoryInfo(info)
                        result.success(info.totalMem)
                    }
                    // Android backups skip the model through res/xml/backup_rules.xml
                    "excludeFromBackup" -> result.success(true)
                    else -> result.notImplemented()
                }
            }
    }
}
