import android.app.KeyguardManager
import android.content.Context
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import androidx.appcompat.app.AppCompatActivity

class EmergencyAlertActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // الأكواد السحرية لإضاءة الشاشة وتجاوز القفل
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
        
        // إبقاء الشاشة مضاءة طوال فترة الإنذار
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        setContentView(R.layout.activity_emergency_alert) // اربطها بتصميم الواجهة الحمراء

        // استلام البيانات وعرضها
        val sender = intent.getStringExtra("senderName")
        val location = intent.getStringExtra("location")
        val battery = intent.getStringExtra("battery")
        
        // قم بربط المتغيرات بـ TextViews داخل الواجهة هنا
    }
}
