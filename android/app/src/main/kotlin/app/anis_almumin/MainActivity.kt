package app.anis_almumin

import android.Manifest
import android.app.NotificationManager
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.json.JSONObject

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(engine: FlutterEngine) {
        super.configureFlutterEngine(engine)
        MethodChannel(engine.dartExecutor.binaryMessenger, "app.anis_almumin/native").setMethodCallHandler { call, result ->
            when (call.method) {
                "schedule" -> {
                    val list = call.argument<List<Map<String, Any>>>("items") ?: emptyList()
                    CoroutineScope(Dispatchers.IO).launch {
                        AlarmScheduler.replaceAll(applicationContext, JSONArray().apply { list.forEach { put(JSONObject(it)) } })
                        runOnUiThread { result.success(null) }
                    }
                }
                "cancelAll" -> CoroutineScope(Dispatchers.IO).launch {
                    AlarmScheduler.cancelAll(applicationContext)
                    runOnUiThread { result.success(null) }
                }
                "status" -> result.success(mapOf(
                    "notif" to (getSystemService(NOTIFICATION_SERVICE) as NotificationManager).areNotificationsEnabled(),
                    "exact" to AlarmScheduler.canExact(this),
                    "battery" to (getSystemService(POWER_SERVICE) as PowerManager).isIgnoringBatteryOptimizations(packageName)
                ))
                "requestNotifications" -> {
                    if (Build.VERSION.SDK_INT >= 33 &&
                        checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != android.content.pm.PackageManager.PERMISSION_GRANTED
                    ) requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 1)
                    result.success(null)
                }
                "openExactSettings" -> {
                    if (Build.VERSION.SDK_INT >= 31)
                        startActivity(Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM, Uri.parse("package:$packageName")))
                    result.success(null)
                }
                "openBatterySettings" -> {
                    startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
