import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_accessibility_service/flutter_accessibility_service.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SOSHomeScreen(),
    );
  }
}

class SOSHomeScreen extends StatefulWidget {
  const SOSHomeScreen({super.key});

  @override
  State<SOSHomeScreen> createState() => _SOSHomeScreenState();
}

class _SOSHomeScreenState extends State<SOSHomeScreen> {
  PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();
  String statusText = "جاري الاتصال بالسيرفر...";
  
  // بيانات الـ Pusher الخاصة بك
  final String appId = "2176890";
  final String apiKey = "163dad2d478fe38aa1cf";
  final String apiSecret = "81ae586cffe7bf12c117";
  final String apiCluster = "eu";

  @override
  void initState() {
    super.initState();
    initPusher();
    initAccessibility();
  }

  // 1. تشغيل الاتصال اللحظي لاستقبال الإنذارات
  void initPusher() async {
    try {
      await pusher.init(
        apiKey: apiKey,
        cluster: apiCluster,
        onConnectionStateChange: (currentState, previousState) {
          setState(() {
            statusText = "حالة الاتصال: $currentState";
          });
        },
        onEvent: (event) {
          if (event.eventName == "emergency-trigger") {
            final data = jsonDecode(event.data);
            showEmergencyAlert(data['user'], data['location']);
          }
        }
      );
      
      await pusher.subscribe(channelName: "sos-channel");
      await pusher.connect();
    } catch (e) {
      print("خطأ في الاتصال بـ Pusher: $e");
    }
  }

  // 2. مراقبة أزرار الصوت في الخلفية
  void initAccessibility() async {
    bool isGranted = await FlutterAccessibilityService.isAccessibilityPermissionEnabled();
    if (!isGranted) {
      await FlutterAccessibilityService.requestAccessibilityPermission();
    }

    int volumeUpCount = 0;
    int volumeDownCount = 0;

    FlutterAccessibilityService.accessStream.listen((event) {
      if (event.description?.contains("Volume Up") ?? false) {
        volumeUpCount++;
      } else if (event.description?.contains("Volume Down") ?? false) {
        volumeDownCount++;
      }

      if (volumeUpCount >= 2 && volumeDownCount >= 2) {
        triggerSOS();
        volumeUpCount = 0;
        volumeDownCount = 0;
      }
    });
  }

  // 3. إرسال الإنذار اللحظي لكل الأجهزة
  void triggerSOS() async {
    final url = Uri.parse("https://api-$apiCluster.pusher.com/apps/$appId/events?auth_key=$apiKey");
    
    final body = jsonEncode({
      "name": "emergency-trigger",
      "channels": ["sos-channel"],
      "data": jsonEncode({
        "user": "مستخدم مجهول",
        "location": "33.513, 36.291"
      })
    });

    try {
      await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );
    } catch (e) {
      print("فشل إرسال الاستغاثة: $e");
    }
  }

  // 4. عرض شاشة الإنذار الفوري عند الاستقبال
  void showEmergencyAlert(String user, String location) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red,
        title: const Icon(Icons.warning, size: 80, color: Colors.white),
        content: Text(
          "حالة طوارئ قصوى!\n\nاليوزر: $user\nالموقع: $location\n\nالرجاء المساعدة فوراً!",
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("تم الاستجابة", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        title: const Text("SOS Instant System"),
        backgroundColor: Colors.redAccent,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.security, size: 100, color: Colors.redAccent),
            const SizedBox(height: 20),
            Text(
              statusText,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: triggerSOS,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text("اختبار إرسال إنذار تجريبي", style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
