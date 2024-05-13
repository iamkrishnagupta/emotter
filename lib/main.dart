import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:tflite_v2/tflite_v2.dart';
import 'src/home_screen.dart';

List<CameraDescription>? cameraList;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initPlugins();
  runApp(const MainApp());
}

Future<void> _initPlugins() async {
  cameraList = await availableCameras();
  await Tflite.loadModel(
    model: 'assets/model.tflite',
    labels: 'assets/labels.txt',
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const HomeScreen(),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purple,
          brightness: Brightness.dark,
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
