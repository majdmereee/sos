package com.example.sos

import android.app.KeyguardManager
import android.content.Context
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity

class EmergencyAlertActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // إضاءة الشاشة وتجاوز القفل
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
            val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
            keyguardManager.requestDismissKeyguard(this, null)
        } else {
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            )
        }
        
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        // يمكنك إنشاء layout xml أو الاكتفاء بواجهة برمجية بسيطة مؤقتاً
        val textView = TextView(this).apply {
            text = "إنذار طوارئ نشط الآن!\n" + intent.getStringExtra("event_data")
            textSize = 24f
            setTextColor(android.graphics.Color.RED)
            gravity = android.view.Gravity.CENTER
            setBackgroundColor(android.graphics.Color.BLACK)
        }
        
        setContentView(textView)
    }
}
