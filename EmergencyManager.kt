import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import com.google.android.gms.location.LocationServices
import com.google.firebase.database.FirebaseDatabase

object EmergencyManager {

    fun collectDataAndSend(context: Context) {
        val fusedLocationClient = LocationServices.getFusedLocationProviderClient(context)
        
        // جلب نسبة البطارية
        val batteryStatus: Intent? = IntentFilter(Intent.ACTION_BATTERY_CHANGED).let { ifilter ->
            context.registerReceiver(null, ifilter)
        }
        val batteryPct: Float? = batteryStatus?.let { intent ->
            val level: Int = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
            val scale: Int = intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
            level * 100 / scale.toFloat()
        }

        // جلب الموقع وإرسال البيانات
        fusedLocationClient.lastLocation.addOnSuccessListener { location ->
            if (location != null) {
                val mapsLink = "https://maps.google.com/?q=${location.latitude},${location.longitude}"
                sendToFirebase(mapsLink, batteryPct.toString())
            }
        }
    }

    private fun sendToFirebase(locationLink: String, battery: String) {
        val database = FirebaseDatabase.getInstance().getReference("EmergencyAlerts")
        val alertId = database.push().key ?: return
        
        val alertData = hashMapOf(
            "senderName" to "أحمد", // اجلب اسم المستخدم الفعلي
            "location" to locationLink,
            "battery" to "$battery%",
            "timestamp" to System.currentTimeMillis()
        )

        // إرسال البيانات لقاعدة البيانات (مما سيؤدي برمجياً في الخادم لإرسال إشعار FCM للجميع)
        database.child(alertId).setValue(alertData)
    }
}
