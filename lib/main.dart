import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_accessibility_service/flutter_accessibility_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const InstantSOSApp());
}

class InstantSOSApp extends StatelessWidget {
  const InstantSOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Instant SOS',
      theme: ThemeData(primarySwatch: Colors.red, useMaterial3: true),
      home: const SOSHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SOSHomePage extends StatefulWidget {
  const SOSHomePage({super.key});

  @override
  State<SOSHomePage> createState() => _SOSHomePageState();
}

class _SOSHomePageState extends State<SOSHomePage> {
  String username = "جاري التحميل...";
  bool isAccessibilityGranted = false;

  @override
  void initState() {
    super.initState();
    _initUser();
    _checkPermissions();
    _listenToVolumeButtons();
  }

  // توليد وحفظ اسم مستخدم خاص بكل شخص يحمل التطبيق
  Future<void> _initUser() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedName = prefs.getString('username');
    
    if (savedName == null) {
      // إذا كان مستخدم جديد، اصنع له اسم عشوائي
      savedName = "User_${Random().nextInt(9999)}";
      await prefs.setString('username', savedName);
    }
    
    setState(() {
      username = savedName!;
    });
  }

  // التحقق من صلاحيات Accessibility
  Future<void> _checkPermissions() async {
    bool granted = await FlutterAccessibilityService.isAccessibilityPermissionEnabled();
    setState(() {
      isAccessibilityGranted = granted;
    });
  }

  // طلب الصلاحية (سيفتح إعدادات الهاتف للمستخدم)
  Future<void> _requestPermission() async {
    await FlutterAccessibilityService.requestAccessibilityPermission();
    _checkPermissions();
  }

  // مراقبة أزرار الصوت في الخلفية
  void _listenToVolumeButtons() {
    FlutterAccessibilityService.accessStream.listen((event) {
      // هنا نقوم بالتقاط الأحداث، سنقوم لاحقاً بكتابة كود التمييز 
      // بين رفع وخفض الصوت معاً لمدة ثانية.
      print("تم اكتشاف حركة: ${event.eventType}");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Instant SOS'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'معرفك الخاص:',
              style: const TextStyle(fontSize: 20, color: Colors.grey),
            ),
            Text(
              username,
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(height: 50),
            
            // إظهار حالة الصلاحية
            Icon(
              isAccessibilityGranted ? Icons.check_circle : Icons.warning,
              color: isAccessibilityGranted ? Colors.green : Colors.orange,
              size: 60,
            ),
            const SizedBox(height: 10),
            Text(
              isAccessibilityGranted 
                  ? 'خدمة الاستغاثة في الخلفية مفعلة' 
                  : 'التطبيق يحتاج صلاحية للعمل في الخلفية',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            
            // زر لطلب الصلاحية إذا لم تكن مفعلة
            if (!isAccessibilityGranted)
              ElevatedButton(
                onPressed: _requestPermission,
                child: const Text('تفعيل الصلاحية من الإعدادات'),
              ),
          ],
        ),
      ),
    );
  }
}
