import 'package:flutter/material.dart';

void main() {
  runApp(const InstantSOSApp());
}

class InstantSOSApp extends StatelessWidget {
  const InstantSOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Instant SOS',
      theme: ThemeData(
        primarySwatch: Colors.red,
        useMaterial3: true,
      ),
      home: const SOSHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SOSHomePage extends StatelessWidget {
  const SOSHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Instant SOS'),
        centerTitle: true,
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 50),
            shape: const CircleBorder(),
          ),
          onPressed: () {
            // أضف كود إرسال الاستغاثة هنا لاحقاً
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم إرسال إشارة الاستغاثة!')),
            );
          },
          child: const Text(
            'SOS',
            style: TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
