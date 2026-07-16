package com.example.sos

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.view.KeyEvent
import android.view.accessibility.AccessibilityEvent

class VolumeButtonService : AccessibilityService() {

    private val pressTimes = mutableListOf<Long>()
    private val TIME_LIMIT_MS = 3000L // 3 ثواني للضغطات الأربع

    override fun onKeyEvent(event: KeyEvent): Boolean {
        if (event.keyCode == KeyEvent.KEYCODE_VOLUME_UP && event.action == KeyEvent.ACTION_DOWN) {
            val currentTime = System.currentTimeMillis()
            pressTimes.add(currentTime)

            pressTimes.removeAll { currentTime - it > TIME_LIMIT_MS }

            if (pressTimes.size >= 4) {
                pressTimes.clear()
                triggerEmergencyApi()
                return true
            }
        }
        return super.onKeyEvent(event)
    }

    private fun triggerEmergencyApi() {
        // هنا يمكنك إرسال طلب HTTP (API) إلى سيرفرك ليقوم بدوره بنشر الحدث على بوشر
        // أو يمكنك استدعاء كود دارت عبر الـ MethodChannel
        println("تم رصد 4 ضغطات متتالية! جاري إرسال الإنذار...")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {}
    override fun onInterrupt() {}
}
