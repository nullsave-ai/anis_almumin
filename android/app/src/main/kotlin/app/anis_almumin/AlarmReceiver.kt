package app.anis_almumin

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(c: Context, i: Intent) {
        val nm = c.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val b: Notification.Builder
        if (Build.VERSION.SDK_INT >= 26) {
            if (nm.getNotificationChannel(CH) == null)
                nm.createNotificationChannel(NotificationChannel(CH, "أوقات الصلاة", NotificationManager.IMPORTANCE_HIGH))
            b = Notification.Builder(c, CH)
        } else {
            @Suppress("DEPRECATION")
            b = Notification.Builder(c).setPriority(Notification.PRIORITY_HIGH)
        }
        val open = PendingIntent.getActivity(
            c, 0, c.packageManager.getLaunchIntentForPackage(c.packageName), PendingIntent.FLAG_IMMUTABLE
        )
        b.setSmallIcon(c.applicationInfo.icon)
            .setContentTitle(i.getStringExtra("t"))
            .setContentText(i.getStringExtra("b"))
            .setCategory(Notification.CATEGORY_ALARM)
            .setAutoCancel(true)
            .setContentIntent(open)
        nm.notify((System.currentTimeMillis() % Int.MAX_VALUE).toInt(), b.build())
    }

    companion object { const val CH = "prayer" }
}
