package com.example.sos

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import com.pusher.client.Pusher
import com.pusher.client.PusherOptions
import com.pusher.client.connection.ConnectionEventListener
import com.pusher.client.connection.ConnectionState
import com.pusher.client.connection.ConnectionStateChange

class EmergencyPusherService : Service() {

    private lateinit var pusher: Pusher
    private var mediaPlayer: MediaPlayer? = null

    override fun onCreate() {
        super.onCreate()
        startMyForegroundService()
        setupPusher()
    }

    private fun startMyForegroundService() {
        val channelId = "sos_alert_channel"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "SOS Background Service",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }

        val notification: Notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle("نظام الطوارئ نشط")
            .setContentText("جاري مراقبة الإنذارات في الخلفية...")
            .setSmallIcon(android.R.drawable.ic_dialog_alert) // تأكد من وجود أيقونة بهذا الاسم أو استبدلها
            .build()

        startForeground(1, notification)
    }

    private fun setupPusher() {
        val options = PusherOptions().apply {
            setCluster("YOUR_CLUSTER") // استبدلها بـ Cluster الخاص بك
        }
        
        pusher = Pusher("YOUR_APP_KEY", options) // استبدلها بـ App Key الخاص بك

        pusher.connect(object : ConnectionEventListener {
            override fun onConnectionStateChange(change: ConnectionStateChange) {}
            override fun onError(message: String, code: String?, e: Exception?) {}
        }, ConnectionState.ALL)

        val channel = pusher.subscribe("emergency-channel")

        channel.bind("new-alarm") { event ->
            triggerSystemAlarm(event.data)
        }
    }

    private fun triggerSystemAlarm(eventData: String) {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_ALARM)
        audioManager.setStreamVolume(AudioManager.STREAM_ALARM, maxVolume, 0)

        // يجب أن يكون لديك ملف siren.mp3 في مجلد res/raw
        if (mediaPlayer == null) {
            val resId = resources.getIdentifier("siren", "raw", packageName)
            if(resId != 0) {
                mediaPlayer = MediaPlayer.create(this, resId)
                mediaPlayer?.isLooping = true
            }
        }
        mediaPlayer?.start()

        val intent = Intent(this, EmergencyAlertActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
            putExtra("event_data", eventData)
        }
        startActivity(intent)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        pusher.disconnect()
        mediaPlayer?.stop()
        mediaPlayer?.release()
        super.onDestroy()
    }
}
