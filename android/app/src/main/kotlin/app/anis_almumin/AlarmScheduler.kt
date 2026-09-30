package app.anis_almumin

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.first
import org.json.JSONArray

private val Context.store by preferencesDataStore("alarms")

object AlarmScheduler {
    private val KEY = stringPreferencesKey("items")

    private fun am(c: Context) = c.getSystemService(Context.ALARM_SERVICE) as AlarmManager

    private fun pi(c: Context, id: Int, title: String = "", body: String = ""): PendingIntent =
        PendingIntent.getBroadcast(
            c, id,
            Intent(c, AlarmReceiver::class.java).putExtra("t", title).putExtra("b", body),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

    fun canExact(c: Context) = Build.VERSION.SDK_INT < 31 || am(c).canScheduleExactAlarms()

    suspend fun replaceAll(c: Context, items: JSONArray) {
        cancelStored(c)
        c.store.edit { it[KEY] = items.toString() }
        setAll(c, items)
    }

    suspend fun restore(c: Context) {
        val s = c.store.data.first()[KEY] ?: return
        setAll(c, JSONArray(s))
    }

    suspend fun cancelAll(c: Context) {
        cancelStored(c)
        c.store.edit { it.remove(KEY) }
    }

    private suspend fun cancelStored(c: Context) {
        val a = JSONArray(c.store.data.first()[KEY] ?: return)
        for (i in 0 until a.length()) am(c).cancel(pi(c, a.getJSONObject(i).getInt("id")))
    }

    private fun setAll(c: Context, items: JSONArray) {
        val a = am(c)
        val now = System.currentTimeMillis()
        val exact = canExact(c)
        for (i in 0 until items.length()) {
            val o = items.getJSONObject(i)
            val at = o.getLong("at")
            if (at <= now) continue
            val p = pi(c, o.getInt("id"), o.getString("title"), o.getString("body"))
            if (exact) a.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, p)
            else a.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, p)
        }
    }
}
