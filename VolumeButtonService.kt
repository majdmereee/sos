import android.accessibilityservice.AccessibilityService
import android.view.KeyEvent
import android.view.accessibility.AccessibilityEvent

class VolumeButtonService : AccessibilityService() {

    private val pressTimes = mutableListOf<Long>()
    private val TIME_LIMIT_MS = 3000L // 3 ثواني كحد أقصى للـ 4 ضغطات

    override fun onKeyEvent(event: KeyEvent): Boolean {
        if (event.keyCode == KeyEvent.KEYCODE_VOLUME_UP && event.action == KeyEvent.ACTION_DOWN) {
            val currentTime = System.currentTimeMillis()
            pressTimes.add(currentTime)

            // تنظيف الضغطات القديمة التي تجاوزت 3 ثواني
            pressTimes.removeAll { currentTime - it > TIME_LIMIT_MS }

            if (pressTimes.size >= 4) {
                pressTimes.clear()
                triggerEmergency() // استدعاء دالة الطوارئ
                return true // إيقاف رفع الصوت الفعلي في النظام
            }
        }
        return super.onKeyEvent(event)
    }

    private fun triggerEmergency() {
        // هنا نقوم بجمع الموقع والبطارية وإرسالها لـ Firebase
        EmergencyManager.collectDataAndSend(applicationContext)
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {}
    override fun onInterrupt() {}
}
