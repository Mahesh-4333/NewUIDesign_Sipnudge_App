package com.sipnudge.sipnudge

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action == Intent.ACTION_BOOT_COMPLETED ||
            intent?.action == "android.intent.action.QUICKBOOT_POWERON" ||
            intent?.action == "com.htc.intent.action.QUICKBOOT_POWERON") {
            Log.i("BootReceiver", "Device booted. Refreshing SipNudge Home Widget...")
            HomeWidgetProvider.updateAllWidgets(context)
        }
    }
}
