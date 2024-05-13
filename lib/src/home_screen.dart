import 'package:camera/camera.dart';
import 'package:emotterr/main.dart';
import 'package:flutter/material.dart';
import 'package:tflite_v2/tflite_v2.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CameraImage? cameraImage;
  CameraController? cameraController;
  String predictionResult = '';
  bool isFrontCamera = true;

  @override
  void initState() {
    super.initState();
    _loadCamera();
    _loadModel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emotter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.switch_camera),
            onPressed: _toggleCamera,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: !cameraController!.value.isInitialized
                ? const Center(child: CircularProgressIndicator())
                : AspectRatio(
                    aspectRatio: cameraController!.value.aspectRatio,
                    child: CameraPreview(cameraController!),
                  ),
          ),
          const SizedBox(height: 20),
          Text(
            'Your face seems to be $predictionResult',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  _loadModel() async {
    await Tflite.loadModel(
      model: 'assets/model.tflite',
      labels: 'assets/labels.txt',
    );
  }

  _loadCamera() {
    final frontCamera = cameraList!.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
    );

    cameraController = CameraController(
      isFrontCamera ? frontCamera : cameraList![0],
      ResolutionPreset.medium,
    );

    cameraController!.initialize().then((value) {
      if (!mounted) return;
      setState(() {
        cameraController!.startImageStream((image) {
          cameraImage = image;
          _runModel();
        });
      });
    });
  }

  _runModel() async {
    if (cameraImage != null) {
      var predictions = await Tflite.runModelOnFrame(
        bytesList: cameraImage!.planes.map((plane) => plane.bytes).toList(),
        imageHeight: cameraImage!.height,
        imageWidth: cameraImage!.width,
        imageMean: 127.5,
        imageStd: 127.5,
        rotation: 190,
        numResults: 2,
        threshold: 0.1,
        asynch: true,
      );

      for (var prediction in predictions!) {
        setState(() {
          predictionResult = prediction['label'];
        });
      }
    }
  }

  void _toggleCamera() {
    setState(() {
      isFrontCamera = !isFrontCamera;
      _loadCamera();
    });
  }
}