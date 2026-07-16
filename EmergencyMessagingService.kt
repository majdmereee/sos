import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.media.MediaPlayer
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

class EmergencyMessagingService : FirebaseMessagingService() {

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)

        // التحقق من أن الرسالة هي إنذار طوارئ
        if (remoteMessage.data.isNotEmpty() && remoteMessage.data["type"] == "EMERGENCY") {
            
            // 1. تجاوز الوضع الصامت ورفع الصوت لأعلى حد
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_ALARM)
            audioManager.setStreamVolume(AudioManager.STREAM_ALARM, maxVolume, 0)

            // 2. تشغيل صوت صفارة الإنذار (يجب أن يكون ملف siren.mp3 موجوداً في مجلد raw)
            val mediaPlayer = MediaPlayer.create(this, R.raw.siren)
            mediaPlayer.isLooping = true
            mediaPlayer.start()

            // 3. فتح واجهة الإنذار المنبثقة التي تضيء الشاشة
            val intent = Intent(this, EmergencyAlertActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
                putExtra("senderName", remoteMessage.data["senderName"])
                putExtra("location", remoteMessage.data["location"])
                putExtra("battery", remoteMessage.data["battery"])
            }
            startActivity(intent)
        }
    }
}
