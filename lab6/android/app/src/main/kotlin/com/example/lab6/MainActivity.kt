package com.example.lab6


import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.net.wifi.WifiManager
import android.os.BatteryManager
import android.os.Build
import android.util.Log
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import android.net.ConnectivityManager
import android.net.NetworkCapabilities

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.student_dashboard/device"
    private val LOCATION_PERMISSION_REQUEST_CODE = 100

    private var pendingResult: MethodChannel.Result? = null
    private var pendingMethodCall: MethodCall? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getBatteryLevel" -> {
                    val batteryLevel = getBatteryLevel()
                    if (batteryLevel != -1) {
                        result.success(batteryLevel)
                    } else {
                        result.error("UNAVAILABLE", "Battery level not available.", null)
                    }
                }
                "getWifiSsid" -> {
                    Log.d("WifiService", "Attempting to get WIFI SSID")
                    if (hasLocationPermission()) {
                        try {
                            val wifiSsid = getWifiSsid()
                            Log.d("WifiService", "SSID Result: $wifiSsid")
                            result.success(wifiSsid)
                        } catch (e: Exception) {
                            Log.e("WifiService", "Error getting SSID", e)
                            result.error("WIFI_ERROR", "Failed to get WIFI SSID: '${e.message}'", null)
                        }
                    } else {
                        pendingResult = result
                        pendingMethodCall = call
                        requestLocationPermission()
                    }
                }
                "sendEmail" -> {
                    val subject = call.argument<String>("subject") ?: ""
                    sendEmail(subject)
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun getBatteryLevel(): Int {
        val batteryIntent = context.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        val level = batteryIntent?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
        val scale = batteryIntent?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
        return if (level != -1 && scale != -1) {
            (level * 100 / scale.toFloat()).toInt()
        } else {
            -1
        }
    }

    private fun hasLocationPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun requestLocationPermission() {
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.ACCESS_FINE_LOCATION),
            LOCATION_PERMISSION_REQUEST_CODE
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == LOCATION_PERMISSION_REQUEST_CODE) {
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                // Разрешение получено
                pendingResult?.let { result ->
                    try {
                        val wifiSsid = getWifiSsid()
                        Log.d("WifiService", "SSID after permission granted: $wifiSsid")
                        result.success(wifiSsid)
                    } catch (e: Exception) {
                        Log.e("WifiService", "Error getting SSID after permission", e)
                        result.error("WIFI_ERROR", "Failed to get WIFI SSID: '${e.message}'", null)
                    }
                }
            } else {
                // Разрешение не получено
                pendingResult?.success("Location permission denied. Cannot get SSID.")
            }
            pendingResult = null
            pendingMethodCall = null
        }
    }

    private fun getWifiSsid(): String {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                // Для Android 10+ и выше
                val connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
                val network = connectivityManager.activeNetwork ?: return "No active network"
                val networkCapabilities = connectivityManager.getNetworkCapabilities(network) ?: return "No network capabilities"

                if (networkCapabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)) {
                    val wifiManager = context.getSystemService(Context.WIFI_SERVICE) as WifiManager
                    val connectionInfo = wifiManager.connectionInfo

                    // Проверим, что у нас есть нужные разрешения для Android 13+
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        if (ContextCompat.checkSelfPermission(context, Manifest.permission.NEARBY_WIFI_DEVICES) != PackageManager.PERMISSION_GRANTED) {
                            return "Need NEARBY_WIFI_DEVICES permission"
                        }
                    }

                    return connectionInfo.ssid.replace("\"", "")
                }
                return "Not connected to WiFi"
            } else {
                val wifiManager = context.getSystemService(Context.WIFI_SERVICE) as WifiManager
                val info = wifiManager.connectionInfo
                return info.ssid.replace("\"", "")
            }
        } catch (e: Exception) {
            return "Error: ${e.message}"
        }
    }

    private fun sendEmail(subject: String) {
        val intent = Intent(Intent.ACTION_SEND).apply {
            type = "text/plain"
            putExtra(Intent.EXTRA_SUBJECT, subject)
            putExtra(Intent.EXTRA_TEXT, "")
        }

        if (intent.resolveActivity(packageManager) != null) {
            startActivity(Intent.createChooser(intent, "Send Email"))
        }
    }
}