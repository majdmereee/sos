import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_accessibility_service/flutter_accessibility_service.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart'; // مكتبة التشفير كبديل للسيرفر

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
  // مفاتيح Pusher الخاصة بك (تم دمجها للعمل بدون سيرفر!)
  final String pusherAppId = "2176890";
  final String pusherKey = "163dad2d478fe38aa1cf";
  final String pusherSecret = "81ae586cffe7bf12c117";
  final String pusherCluster = "eu";

  String username = "";
  bool isAccessibilityGranted = false;
  final TextEditingController _nameController = TextEditingController();

  DateTime? lastVolUpTime;
  bool isAlarmTriggered = false;

  @override
  void initState() {
    super.initState();
    _initUser();
    _checkPermissions();
    _listenToEvents();
    _initPusher();
  }

  Future<void> _initUser() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedName = prefs.getString('username');
    setState(() {
      username = savedName ?? "";
      _nameController.text = username;
    });
  }

  Future<void> _saveUsername(String name) async {
    if (name.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', name.trim());
    setState(() {
      username = name.trim();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حفظ الاسم بنجاح!'), backgroundColor: Colors.green),
    );
  }

  Future<void> _checkPermissions() async {
    bool granted = await FlutterAccessibilityService.isAccessibilityPermissionEnabled();
    setState(() {
      isAccessibilityGranted = granted;
    });
  }

  Future<void> _requestPermission() async {
    await FlutterAccessibilityService.requestAccessibilityPermission();
    _checkPermissions();
  }

  void _listenToEvents() {
    FlutterAccessibilityService.accessStream.listen((event) {
      DateTime now = DateTime.now();
      
      if (event.eventType.toString().contains("TYPE_WINDOW_CONTENT_CHANGED") || 
          event.eventType.toString().contains("TYPE_VIEW_CLICKED")) {
          
          if (lastVolUpTime == null) {
            lastVolUpTime = now;
          } else {
            final difference = now.difference(lastVolUpTime!).inMilliseconds;
            if (difference > 1000 && !isAlarmTriggered) {
              _sendSOS();
              lastVolUpTime = null; 
            }
          }
      } else {
        lastVolUpTime = null; 
      }
    });
  }

  // --- دالة إطلاق الإنذار المباشر (بدون سيرفر) ---
  Future<void> _sendSOS() async {
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال اسمك أولاً!'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    setState(() { isAlarmTriggered = true; });

    try {
      // 1. تجهيز الرسالة
      String eventData = jsonEncode({
        "message": "حالة طوارئ! $username أطلق نداء استغاثة ويحتاج لمساعدة فورية!",
        "sender": username
      });

      String body = jsonEncode({
        "name": "sos-alert",
        "channels": ["sos-channel"],
        "data": eventData
      });

      // 2. تشفير البيانات ليقبلها Pusher
      String bodyMd5 = md5.convert(utf8.encode(body)).toString();
      String timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      String queryParams = "auth_key=$pusherKey&auth_timestamp=$timestamp&auth_version=1.0&body_md5=$bodyMd5";
      String path = "/apps/$pusherAppId/events";
      String stringToSign = "POST\n$path\n$queryParams";
      String signature = Hmac(sha256, utf8.encode(pusherSecret)).convert(utf8.encode(stringToSign)).toString();

      // 3. إرسال الإشارة عبر الهواء
      String url = "https://api-$pusherCluster.pusher.com$path?$queryParams&auth_signature=$signature";

      await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم بث الإنذار اللحظي لجميع المستخدمين!'), backgroundColor: Colors.red),
      );
    } catch (e) {
      print("خطأ في الإرسال: $e");
    }

    Future.delayed(const Duration(seconds: 5), () {
      setState(() { isAlarmTriggered = false; });
    });
  }

  // --- دالة استقبال الإنذار ---
  Future<void> _initPusher() async {
    final pusher = PusherChannelsFlutter.getInstance();
    try {
      await pusher.init(
        apiKey: pusherKey,
        cluster: pusherCluster,
        onEvent: _onPusherEvent,
      );
      await pusher.subscribe(channelName: "sos-channel");
      await pusher.connect();
    } catch (e) {
      print("خطأ في تهيئة Pusher: $e");
    }
  }

  void _onPusherEvent(PusherEvent event) {
    if (event.eventName == "sos-alert") {
      final data = jsonDecode(event.data.toString());
      final senderName = data['sender'];
      
      // إذا لم تكن أنت المرسل، أطلق الإنذار في وجهك!
      if (senderName != username) {
        _showEmergencyScreen(data['message']);
      }
    }
  }

  void _showEmergencyScreen(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.redAccent,
          title: const Text("🚨 حالة طوارئ 🚨", style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          content: Text(message, style: const TextStyle(color: Colors.white, fontSize: 20)),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.red),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('إغلاق الإنذار', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Instant SOS'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("قم بإعداد اسمك لتسهيل التعرف عليك في حالات الطوارئ:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'اسم المستخدم / الهوية',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.save, color: Colors.blueAccent),
                  onPressed: () => _saveUsername(_nameController.text),
                ),
              ),
            ),
            const SizedBox(height: 30),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(15)),
              child: Column(
                children: [
                  Icon(isAccessibilityGranted ? Icons.security : Icons.warning_amber,
                      color: isAccessibilityGranted ? Colors.green : Colors.orange, size: 80),
                  const SizedBox(height: 10),
                  Text(
                    isAccessibilityGranted ? "المراقب النشط يعمل بكفاءة في الخلفية" : "النظام بحاجة إلى صلاحيات",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "اضغط باستمرار على أزرار الصوت معاً لمدة ثانية لإرسال نداء فوري.",
                    style: TextStyle(fontSize: 14, color: Colors.grey[800]), textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            if (!isAccessibilityGranted)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, padding: const EdgeInsets.all(15)),
                icon: const Icon(Icons.settings),
                label: const Text('تفعيل الصلاحية من الإعدادات', style: TextStyle(fontSize: 16)),
                onPressed: _requestPermission,
              ),
              
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.all(20)),
              onPressed: _sendSOS,
              child: const Text('اختبار إرسال استغاثة (يدوي)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
