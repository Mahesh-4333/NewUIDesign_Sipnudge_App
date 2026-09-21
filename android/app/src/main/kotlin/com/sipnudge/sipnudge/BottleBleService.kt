package com.sipnudge.sipnudge

import android.annotation.SuppressLint
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattDescriptor
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat
import org.json.JSONArray
import org.json.JSONObject
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import java.util.UUID
import java.util.concurrent.Executors

class BottleBleService : Service() {

    companion object {
        private const val TAG = "BottleBleService"
        private const val NOTIFICATION_ID = 8888
        private const val CHANNEL_ID = "sipnudge_ble_service_channel"
        private const val PREFS_NAME = "FlutterSharedPreferences"

        // BLE UUIDs
        private val DATA_CHAR_UUID = UUID.fromString("6E400003-B5A3-F393-E0A9-E50E24DCCA9E")
        private val RTC_CHAR_UUID  = UUID.fromString("6E400004-B5A3-F393-E0A9-E50E24DCCA9E")
        private val CCCD_UUID      = UUID.fromString("00002902-0000-1000-8000-00805F9B34FB")

        const val ACTION_START_SERVICE = "com.sipnudge.sipnudge.ACTION_START_BLE_SERVICE"
        const val ACTION_STOP_SERVICE  = "com.sipnudge.sipnudge.ACTION_STOP_BLE_SERVICE"
        const val EXTRA_DEVICE_ADDRESS = "extra_device_address"

        @Volatile
        var isFlutterEngineAlive: Boolean = false
        private var serviceInstance: BottleBleService? = null

        fun setFlutterForeground(isForeground: Boolean) {
            isFlutterEngineAlive = isForeground
            if (isForeground) {
                Log.d(TAG, "Flutter entered foreground — releasing native GATT for Flutter BleCubit")
                serviceInstance?.disconnectGatt()
            } else {
                Log.d(TAG, "Flutter entered background — activating native BottleBleService GATT connection")
                serviceInstance?.connectToDevice()
            }
        }

        fun setFlutterAlive(alive: Boolean) {
            setFlutterForeground(alive)
        }

        fun startService(context: Context, deviceAddress: String? = null) {
            try {
                val current = serviceInstance
                if (current != null) {
                    if (!deviceAddress.isNullOrEmpty()) {
                        current.targetDeviceAddress = deviceAddress
                        current.saveTargetAddress(deviceAddress)
                    }
                    if (!isFlutterEngineAlive) {
                        current.connectToDevice()
                    }
                    return
                }

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    val hasBt = androidx.core.content.ContextCompat.checkSelfPermission(
                        context,
                        android.Manifest.permission.BLUETOOTH_CONNECT
                    ) == android.content.pm.PackageManager.PERMISSION_GRANTED
                    if (!hasBt) {
                        Log.w(TAG, "Cannot start BottleBleService: BLUETOOTH_CONNECT permission not granted")
                        return
                    }
                }
                val intent = Intent(context, BottleBleService::class.java).apply {
                    action = ACTION_START_SERVICE
                    if (deviceAddress != null) {
                        putExtra(EXTRA_DEVICE_ADDRESS, deviceAddress)
                    }
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error starting BottleBleService: ${e.message}")
            }
        }

        fun stopService(context: Context) {
            try {
                val intent = Intent(context, BottleBleService::class.java).apply {
                    action = ACTION_STOP_SERVICE
                }
                context.stopService(intent)
            } catch (e: Exception) {
                Log.e(TAG, "Error stopping BottleBleService: ${e.message}")
            }
        }
    }

    private var bluetoothGatt: BluetoothGatt? = null
    private var targetDeviceAddress: String? = null
    private val httpExecutor = Executors.newSingleThreadExecutor()

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        serviceInstance = this
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP_SERVICE) {
            disconnectGatt()
            stopForeground(true)
            stopSelf()
            return START_NOT_STICKY
        }

        val addressExtra = intent?.getStringExtra(EXTRA_DEVICE_ADDRESS)
        if (!addressExtra.isNullOrEmpty()) {
            targetDeviceAddress = addressExtra
            saveTargetAddress(addressExtra)
        } else {
            targetDeviceAddress = getSavedTargetAddress()
        }

        try {
            val notification = createForegroundNotification("SipNudge Smart Bottle Connected")
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE)
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
        } catch (e: Exception) {
            Log.e(TAG, "startForeground error: ${e.message}")
            try {
                val notification = createForegroundNotification("SipNudge Smart Bottle Connected")
                startForeground(NOTIFICATION_ID, notification)
            } catch (e2: Exception) {
                Log.e(TAG, "Fallback startForeground error: ${e2.message}")
            }
        }

        // Only connect native GATT if Flutter engine is NOT alive (e.g. standalone background / boot)
        if (!isFlutterEngineAlive) {
            connectToDevice()
        } else {
            Log.d(TAG, "Flutter engine is active. Flutter manages the BLE connection.")
        }
        return START_STICKY
    }

    override fun onDestroy() {
        if (serviceInstance == this) {
            serviceInstance = null
        }
        disconnectGatt()
        httpExecutor.shutdown()
        super.onDestroy()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "SipNudge Bottle Sync",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Keeps connection to your SipNudge Smart Bottle for real-time hydration sync"
                setShowBadge(false)
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    private fun createForegroundNotification(statusText: String): Notification {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName) ?: Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_widget_drop)
            .setContentTitle("SipNudge Smart Bottle")
            .setContentText(statusText)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .setContentIntent(pendingIntent)
            .build()
    }

    private fun updateNotification(statusText: String) {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(NOTIFICATION_ID, createForegroundNotification(statusText))
    }

    @SuppressLint("MissingPermission")
    private fun connectToDevice() {
        if (isFlutterEngineAlive) {
            Log.d(TAG, "Skipping native GATT connection because Flutter engine is alive.")
            return
        }

        val address = targetDeviceAddress ?: getSavedTargetAddress()
        if (address.isNullOrEmpty()) {
            Log.w(TAG, "No target bottle MAC address found. Waiting for pairing...")
            return
        }

        val bluetoothManager = getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
        val adapter = bluetoothManager?.adapter
        if (adapter == null || !adapter.isEnabled) {
            Log.w(TAG, "Bluetooth is disabled.")
            return
        }

        try {
            val device = adapter.getRemoteDevice(address)
            Log.d(TAG, "Connecting to bottle GATT in background at $address")
            disconnectGatt()
            bluetoothGatt = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                device.connectGatt(this, false, gattCallback, BluetoothDevice.TRANSPORT_LE)
            } else {
                device.connectGatt(this, false, gattCallback)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error connecting GATT: ${e.message}")
        }
    }

    @SuppressLint("MissingPermission")
    fun disconnectGatt() {
        try {
            bluetoothGatt?.disconnect()
            bluetoothGatt?.close()
            bluetoothGatt = null
        } catch (e: Exception) {
            Log.w(TAG, "Error closing GATT: ${e.message}")
        }
    }

    private val gattCallback = object : BluetoothGattCallback() {

        @SuppressLint("MissingPermission")
        override fun onConnectionStateChange(gatt: BluetoothGatt, status: Int, newState: Int) {
            if (newState == BluetoothProfile.STATE_CONNECTED) {
                Log.i(TAG, "Connected to bottle GATT in background successfully")
                updateNotification("Connected to Smart Bottle • Auto-syncing")
                // Request MTU 512 so packets are received in full rather than 20-byte fragments
                val requested = gatt.requestMtu(512)
                if (!requested) {
                    gatt.discoverServices()
                }
            } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                Log.w(TAG, "Disconnected from bottle GATT. Scheduling background reconnect...")
                updateNotification("Searching for Smart Bottle...")
                disconnectGatt()
                if (!isFlutterEngineAlive) {
                    Handler(Looper.getMainLooper()).postDelayed({
                        if (!isFlutterEngineAlive) {
                            connectToDevice()
                        }
                    }, 5000)
                }
            }
        }

        @SuppressLint("MissingPermission")
        override fun onMtuChanged(gatt: BluetoothGatt, mtu: Int, status: Int) {
            Log.d(TAG, "Background GATT MTU changed to: $mtu (status=$status)")
            gatt.discoverServices()
        }

        @SuppressLint("MissingPermission")
        override fun onServicesDiscovered(gatt: BluetoothGatt, status: Int) {
            if (status != BluetoothGatt.GATT_SUCCESS) return

            for (service in gatt.services) {
                val dataChar = service.getCharacteristic(DATA_CHAR_UUID)
                if (dataChar != null) {
                    gatt.setCharacteristicNotification(dataChar, true)
                    val descriptor = dataChar.getDescriptor(CCCD_UUID)
                    if (descriptor != null) {
                        descriptor.value = BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
                        gatt.writeDescriptor(descriptor)
                        Log.i(TAG, "Subscribed to DATA_CHAR notifications in background")
                        return
                    }
                }
            }
        }

        @SuppressLint("MissingPermission")
        override fun onDescriptorWrite(gatt: BluetoothGatt, descriptor: BluetoothGattDescriptor, status: Int) {
            if (status == BluetoothGatt.GATT_SUCCESS) {
                Log.i(TAG, "CCCD descriptor written successfully. Now sending RTC time sync...")
                for (service in gatt.services) {
                    val rtcChar = service.getCharacteristic(RTC_CHAR_UUID)
                    if (rtcChar != null) {
                        syncRtcTime(gatt, rtcChar)
                        break
                    }
                }
            }
        }

        @SuppressLint("MissingPermission")
        private fun syncRtcTime(gatt: BluetoothGatt, rtcChar: BluetoothGattCharacteristic) {
            try {
                val now = Date()
                val offsetMinutes = TimeZone.getDefault().getOffset(now.time) / (1000 * 60)
                val sign = if (offsetMinutes >= 0) "+" else "-"
                val hours = Math.abs(offsetMinutes / 60)
                val mins = Math.abs(offsetMinutes % 60)
                val formattedOffset = String.format(Locale.US, "%s%02d:%02d", sign, hours, mins)

                val sdf = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.US)
                val timestampPayload = "${sdf.format(now)}/$formattedOffset"

                rtcChar.value = timestampPayload.toByteArray(Charsets.UTF_8)
                rtcChar.writeType = BluetoothGattCharacteristic.WRITE_TYPE_NO_RESPONSE
                gatt.writeCharacteristic(rtcChar)
                Log.d(TAG, "Sent RTC sync command: $timestampPayload")
            } catch (e: Exception) {
                Log.w(TAG, "Failed to send RTC sync: ${e.message}")
            }
        }

        @Deprecated("Deprecated in Java")
        override fun onCharacteristicChanged(gatt: BluetoothGatt, characteristic: BluetoothGattCharacteristic) {
            if (characteristic.uuid == DATA_CHAR_UUID) {
                val payload = characteristic.value?.let { String(it, Charsets.UTF_8) } ?: return
                appendAndProcessDataChunk(payload)
            }
        }

        override fun onCharacteristicChanged(gatt: BluetoothGatt, characteristic: BluetoothGattCharacteristic, value: ByteArray) {
            if (characteristic.uuid == DATA_CHAR_UUID) {
                val payload = String(value, Charsets.UTF_8)
                appendAndProcessDataChunk(payload)
            }
        }
    }

    private val dataCharBuffer = StringBuilder()
    private val bufferHandler = Handler(Looper.getMainLooper())
    private var parseBufferRunnable: Runnable? = null

    private fun appendAndProcessDataChunk(chunk: String) {
        synchronized(dataCharBuffer) {
            dataCharBuffer.append(chunk)
            val accumulated = dataCharBuffer.toString()

            // Check if full packet has arrived (contains ts= and (bq_temp= or temp=) and daily_total_ml=)
            val isComplete = accumulated.contains("ts=") &&
                    accumulated.contains("daily_total_ml=") &&
                    (accumulated.contains("bq_temp=") || accumulated.contains("temp=") || accumulated.endsWith("\n"))

            if (isComplete) {
                parseBufferRunnable?.let { bufferHandler.removeCallbacks(it) }
                val fullPayload = accumulated
                dataCharBuffer.setLength(0)
                handleDataCharPacket(fullPayload)
                return
            }

            // Debounce fallback timer: if remaining chunks are delayed, process after 350ms
            parseBufferRunnable?.let { bufferHandler.removeCallbacks(it) }
            parseBufferRunnable = Runnable {
                synchronized(dataCharBuffer) {
                    if (dataCharBuffer.isNotEmpty()) {
                        val fullPayload = dataCharBuffer.toString()
                        dataCharBuffer.setLength(0)
                        handleDataCharPacket(fullPayload)
                    }
                }
            }
            bufferHandler.postDelayed(parseBufferRunnable!!, 350L)
        }
    }

    private fun handleDataCharPacket(payload: String) {
        Log.i(TAG, "[BG-BLE] Raw packet received on DATA_CHAR: $payload")
        var batteryPct: Int? = null
        var dailyTotalMl: Int? = null
        var volumeVal: Double? = null
        var percentVal: Int? = null
        var refillVal: Double? = null
        var tempVal: Double? = null
        var bqTempVal: Double? = null
        var tsVal: String? = null

        // Parse key=value pairs: "battery=75;daily_total_ml=1240;volume=450;..."
        for (pair in payload.split(";")) {
            val parts = pair.trim().split("=")
            if (parts.size == 2) {
                val key = parts[0].trim()
                val value = parts[1].trim()
                if (key == "battery") {
                    batteryPct = value.toIntOrNull()
                } else if (key == "daily_total_ml") {
                    dailyTotalMl = value.toIntOrNull()
                } else if (key == "volume") {
                    volumeVal = value.toDoubleOrNull()
                } else if (key == "percent") {
                    percentVal = value.toIntOrNull()
                } else if (key == "refill" || key == "refills") {
                    refillVal = value.toDoubleOrNull()
                } else if (key == "temp") {
                    tempVal = value.toDoubleOrNull()
                } else if (key == "bq_temp" || key == "bqTemp") {
                    bqTempVal = value.toDoubleOrNull()
                } else if (key == "ts") {
                    tsVal = value
                }
            }
        }

        if (dailyTotalMl == null) return
        val consumed = dailyTotalMl

        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val sdf = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
        val todayStr = sdf.format(Date())

        val lastUpdateDateStr = prefs.getString("flutter.last_update_date", null)
            ?: prefs.getString("last_update_date", "")

        val isNewDay = lastUpdateDateStr != todayStr && !lastUpdateDateStr.isNullOrEmpty()

        var baseline = prefs.getInt("flutter.bottle_baseline", 0).let { if (it > 0) it else prefs.getInt("bottle_baseline", 0) }
        val lastBottleReading = prefs.getInt("flutter.last_bottle_reading", 0).let { if (it > 0) it else prefs.getInt("last_bottle_reading", 0) }
        var currentTodayIntake = prefs.getInt("flutter.current_intake", 0).let { if (it > 0) it else prefs.getInt("current_intake", 0) }
        var sipDiff = 0

        if (isNewDay) {
            prefs.edit().putInt("flutter.coffee_intake", 0).putInt("coffee_intake", 0).apply()
            prefs.edit().putInt("flutter.water_intake", 0).putInt("water_intake", 0).apply()

            if (consumed == 0) {
                baseline = 0
                currentTodayIntake = 0
                sipDiff = 0
            } else if (consumed >= lastBottleReading && lastBottleReading > 0) {
                baseline = lastBottleReading
                val newWater = consumed - baseline
                if (newWater in 40..600) {
                    sipDiff = newWater
                    currentTodayIntake = newWater
                } else {
                    sipDiff = 0
                    currentTodayIntake = 0
                }
            } else {
                if (consumed > 600) {
                    baseline = consumed
                    sipDiff = 0
                    currentTodayIntake = 0
                } else if (consumed >= 40) {
                    baseline = 0
                    sipDiff = consumed
                    currentTodayIntake = consumed
                } else {
                    baseline = 0
                    sipDiff = 0
                    currentTodayIntake = consumed
                }
            }
            prefs.edit().putInt("flutter.bottle_baseline", baseline).putInt("bottle_baseline", baseline).apply()
        } else {
            // Same day:
            if (consumed == 0) {
                // Bottle hardware temporarily reported 0 or reconnected during the day.
                sipDiff = 0
                Log.i(TAG, "[BG-BLE] Bottle hardware reported 0ml during the day — preserving currentTodayIntake ($currentTodayIntake ml)")
            } else {
                // Compare directly with lastBottleReading to accurately detect sips even if currentTodayIntake includes manual drinks
                if (lastBottleReading > 0 && consumed > lastBottleReading) {
                    val diff = consumed - lastBottleReading
                    if (diff in 40..600) {
                        sipDiff = diff
                        currentTodayIntake = if (currentTodayIntake >= lastBottleReading) currentTodayIntake + diff else consumed
                        Log.i(TAG, "[BG-BLE] Bottle sip detected: diff=$sipDiff ml, new currentTodayIntake=$currentTodayIntake ml")
                    } else if (diff > 600) {
                        Log.w(TAG, "[BG-BLE] Anomalous diff ignored: $diff ml")
                        sipDiff = 0
                    }
                } else if (lastBottleReading == 0) {
                    val calculatedTodayIntake = Math.max(0, consumed - baseline)
                    if (calculatedTodayIntake > currentTodayIntake) {
                        val diff = calculatedTodayIntake - currentTodayIntake
                        if (diff in 40..600) {
                            sipDiff = diff
                            currentTodayIntake = calculatedTodayIntake
                        }
                    } else if (currentTodayIntake == 0 && consumed in 40..600) {
                        sipDiff = consumed
                        currentTodayIntake = consumed
                    }
                }
            }
        }

        // Save updated intake & state
        val editor = prefs.edit()
        editor.putInt("flutter.last_bottle_reading", consumed)
        editor.putInt("last_bottle_reading", consumed)
        editor.putInt("flutter.current_intake", currentTodayIntake)
        editor.putInt("current_intake", currentTodayIntake)
        editor.putString("flutter.last_update_date", todayStr)
        editor.putString("last_update_date", todayStr)

        if (batteryPct != null && batteryPct > 0) {
            editor.putInt("flutter.battery", batteryPct)
            editor.putInt("battery", batteryPct)
        }
        if (volumeVal != null) {
            editor.putString("flutter.bottle_volume", volumeVal.toString())
            editor.putString("volume", volumeVal.toString())
        }
        if (tempVal != null) {
            editor.putString("flutter.bottle_temp", tempVal.toString())
            editor.putString("temp", tempVal.toString())
        }
        if (percentVal != null) {
            editor.putInt("flutter.bottle_percent", percentVal)
        }
        if (refillVal != null) {
            editor.putString("flutter.bottle_refills", refillVal.toString())
        }
        if (bqTempVal != null) {
            editor.putString("flutter.bottle_bq_temp", bqTempVal.toString())
        }
        editor.apply()

        Log.i(TAG, "[BG-BLE] DATA_CHAR consumed=$consumed ml (baseline=$baseline ml, todayIntake=$currentTodayIntake ml, diff=$sipDiff ml, vol=$volumeVal ml, temp=$tempVal°C)")

        // Update Android Home Widget
        HomeWidgetProvider.updateAllWidgets(this)

        // Upload to backend server asynchronously
        val userId = prefs.getString("flutter.user_id", null) ?: prefs.getString("user_id", null)
        if (!userId.isNullOrEmpty() && userId != "guest_user") {
            val effBattery = batteryPct ?: prefs.getInt("flutter.battery", 75)
            uploadTodayConsumed(userId, currentTodayIntake, effBattery, sipDiff >= 40)

            if (sipDiff in 40..600) {
                uploadTodayHistory(
                    userId = userId,
                    sipAmount = sipDiff.toDouble(),
                    totalAtTime = currentTodayIntake.toDouble(),
                    battery = batteryPct,
                    volume = volumeVal,
                    percent = percentVal,
                    refill = refillVal,
                    temp = tempVal,
                    bqTemp = bqTempVal,
                    ts = tsVal,
                    bottleData = payload
                )
            }
            updateWidgetDelayed(5000L)
        }
    }

    private fun updateWidgetDelayed(delayMs: Long = 5000L) {
        Handler(Looper.getMainLooper()).postDelayed({
            HomeWidgetProvider.updateAllWidgets(this)
        }, delayMs)
    }

    private fun uploadTodayConsumed(userId: String, consumed: Int, battery: Int, sendNotification: Boolean = false) {
        httpExecutor.execute {
            try {
                val url = URL("https://api.sipnudge.com/api/database/update-today-consumed-with-notification")
                val conn = url.openConnection() as HttpURLConnection
                conn.requestMethod = "PATCH"
                conn.setRequestProperty("Content-Type", "application/json")
                conn.connectTimeout = 8000
                conn.readTimeout = 8000
                conn.doOutput = true

                val now = Date()
                val isoFormat = SimpleDateFormat("yyyy-MM-dd'T'00:00:00.000'Z'", Locale.US).apply {
                    timeZone = TimeZone.getTimeZone("UTC")
                }

                val body = JSONObject().apply {
                    put("userId", userId)
                    put("date", isoFormat.format(now))
                    put("consumed", consumed.toDouble())
                    put("sendNotification", sendNotification)
                    put("battery", battery)
                    put("force", true)
                }

                OutputStreamWriter(conn.outputStream).use { writer ->
                    writer.write(body.toString())
                    writer.flush()
                }

                val code = conn.responseCode
                Log.i(TAG, "[BG-BLE] uploadTodayConsumed PATCH response: $code")
                conn.disconnect()
            } catch (e: Exception) {
                Log.w(TAG, "Error uploading today consumed: ${e.message}")
            }
        }
    }

    private fun uploadTodayHistory(
        userId: String,
        sipAmount: Double,
        totalAtTime: Double,
        battery: Int? = null,
        volume: Double? = null,
        percent: Int? = null,
        refill: Double? = null,
        temp: Double? = null,
        bqTemp: Double? = null,
        ts: String? = null,
        bottleData: String? = null
    ) {
        httpExecutor.execute {
            try {
                val url = URL("https://api.sipnudge.com/api/database/sync-today-history")
                val conn = url.openConnection() as HttpURLConnection
                conn.requestMethod = "POST"
                conn.setRequestProperty("Content-Type", "application/json")
                conn.connectTimeout = 8000
                conn.readTimeout = 8000
                conn.doOutput = true

                val now = Date()
                val isoFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US).apply {
                    timeZone = TimeZone.getTimeZone("UTC")
                }

                val historyItem = JSONObject().apply {
                    put("consumed", sipAmount)
                    put("totalAtTime", totalAtTime)
                    put("timestamp", isoFormat.format(now))
                    if (battery != null) {
                        put("battery", battery)
                        put("percentage", battery)
                        put("percent", battery)
                    }
                    if (volume != null) {
                        put("volume", volume)
                        put("remaining", volume)
                    }
                    if (percent != null) {
                        put("percentage", percent)
                        put("percent", percent)
                    }
                    if (refill != null) {
                        put("refill", refill)
                    }
                    if (temp != null) {
                        put("temp", temp)
                    }
                    if (bqTemp != null) {
                        put("bqTemp", bqTemp)
                    }
                    if (ts != null) {
                        put("ts", ts)
                    }
                    if (bottleData != null) {
                        put("bottleData", bottleData)
                    }
                    put("timezone", TimeZone.getDefault().id)
                }

                val body = JSONObject().apply {
                    put("userId", userId)
                    put("history", JSONArray().put(historyItem))
                }

                OutputStreamWriter(conn.outputStream).use { writer ->
                    writer.write(body.toString())
                    writer.flush()
                }

                val code = conn.responseCode
                Log.i(TAG, "[BG-BLE] uploadTodayHistory POST response: $code")
                conn.disconnect()
            } catch (e: Exception) {
                Log.w(TAG, "Error uploading today history: ${e.message}")
            }
        }
    }

    private fun saveTargetAddress(address: String) {
        getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE).edit()
            .putString("flutter.device_mac", address)
            .putString("device_mac", address)
            .apply()
    }

    private fun getSavedTargetAddress(): String? {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getString("flutter.last_device_id", null)
            ?: prefs.getString("last_device_id", null)
            ?: prefs.getString("flutter.device_mac", null)
            ?: prefs.getString("device_mac", null)
            ?: prefs.getString("flutter.device_id", null)
            ?: prefs.getString("device_id", null)
    }
}
