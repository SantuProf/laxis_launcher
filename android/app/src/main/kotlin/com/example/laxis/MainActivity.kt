package com.example.laxis

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.util.Base64
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {
	private val APPS_CHANNEL = "laxis/apps"
	private val APPS_EVENTS = "laxis/appEvents"
	private var eventSink: EventChannel.EventSink? = null
	private var packageReceiver: BroadcastReceiver? = null

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APPS_CHANNEL)
			.setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
				when (call.method) {
					"getInstalledApps" -> {
						val apps = getInstalledApps()
						result.success(apps)
					}
					"launchApp" -> {
						val packageName = call.argument<String>("package")
						if (packageName == null) {
							result.error("INVALID", "No package provided", null)
						} else {
							val launched = launchApp(packageName)
							if (launched) result.success(true) else result.error("LAUNCH_FAILED", "Failed to launch: $packageName", null)
						}
					}
						"openHomeSettings" -> {
							try {
								val intent = Intent(Settings.ACTION_HOME_SETTINGS)
								intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
								startActivity(intent)
								result.success(true)
							} catch (e: Exception) {
								result.error("OPEN_FAILED", e.message, null)
							}
						}
						"openSystemSettings" -> {
							try {
								val intent = Intent(Settings.ACTION_SETTINGS)
								intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
								startActivity(intent)
								result.success(true)
							} catch (e: Exception) {
								result.error("OPEN_FAILED", e.message, null)
							}
						}
					else -> result.notImplemented()
				}
			}

		EventChannel(flutterEngine.dartExecutor.binaryMessenger, APPS_EVENTS)
			.setStreamHandler(object : EventChannel.StreamHandler {
				override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
					eventSink = events
					registerPackageReceiver()
				}

				override fun onCancel(arguments: Any?) {
					unregisterPackageReceiver()
					eventSink = null
				}
			})
	}

	private fun getInstalledApps(): List<Map<String, Any?>> {
		val pm: PackageManager = packageManager
		val intent = Intent(Intent.ACTION_MAIN, null)
		intent.addCategory(Intent.CATEGORY_LAUNCHER)
		val resolveInfos = pm.queryIntentActivities(intent, 0)

		val apps = ArrayList<Map<String, Any?>>()
		for (ri in resolveInfos) {
			val packageName = ri.activityInfo.packageName
			val appName = ri.loadLabel(pm).toString()
			val iconDrawable = ri.loadIcon(pm)
			val iconBase64 = drawableToBase64(iconDrawable)

			val map = mapOf<String, Any?>(
				"name" to appName,
				"package" to packageName,
				"icon" to iconBase64
			)
			apps.add(map)
		}

		// Sort by name
		apps.sortBy { (it["name"] as? String) ?: "" }
		return apps
	}

	private fun drawableToBase64(drawable: Drawable): String? {
		try {
			val bitmap = if (drawable is BitmapDrawable) {
				drawable.bitmap
			} else {
				val width = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else 1
				val height = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else 1
				val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
				val canvas = Canvas(bitmap)
				drawable.setBounds(0, 0, canvas.width, canvas.height)
				drawable.draw(canvas)
				bitmap
			}

			val stream = ByteArrayOutputStream()
			bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
			val bytes = stream.toByteArray()
			return Base64.encodeToString(bytes, Base64.NO_WRAP)
		} catch (e: Exception) {
			return null
		}
	}

	private fun launchApp(packageName: String): Boolean {
		return try {
			val intent = packageManager.getLaunchIntentForPackage(packageName)
			if (intent != null) {
				intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
				startActivity(intent)
				true
			} else {
				false
			}
		} catch (e: Exception) {
			false
		}
	}

	private fun registerPackageReceiver() {
		if (packageReceiver != null) return

		val filter = IntentFilter()
		filter.addAction(Intent.ACTION_PACKAGE_ADDED)
		filter.addAction(Intent.ACTION_PACKAGE_REMOVED)
		filter.addAction(Intent.ACTION_PACKAGE_CHANGED)
		filter.addDataScheme("package")

		packageReceiver = object : BroadcastReceiver() {
			override fun onReceive(context: Context, intent: Intent) {
				val action = intent.action
				val data = intent.data
				val pkg = data?.schemeSpecificPart
				val eventType = when (action) {
					Intent.ACTION_PACKAGE_ADDED -> "installed"
					Intent.ACTION_PACKAGE_REMOVED -> "removed"
					Intent.ACTION_PACKAGE_CHANGED -> "changed"
					else -> "unknown"
				}

				val payload = mapOf("event" to eventType, "package" to pkg)
				eventSink?.success(payload)
			}
		}

		registerReceiver(packageReceiver, filter)
	}

	private fun unregisterPackageReceiver() {
		try {
			if (packageReceiver != null) {
				unregisterReceiver(packageReceiver)
				packageReceiver = null
			}
		} catch (e: Exception) {
			// ignore
		}
	}
}
