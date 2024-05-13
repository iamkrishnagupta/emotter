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
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * .5,
              width: MediaQuery.of(context).size.width,
              child: !cameraController!.value.isInitialized
                  ? Container()
                  : Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: AspectRatio(
                        aspectRatio: cameraController!.value.aspectRatio,
                        child: CameraPreview(cameraController!),
                      ),
                    ),
            ),
          ),
          Text(
            'Your face seems to be $predictionResult',
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
          ),
        ],
      ),
    );
  }

  CameraImage? cameraImage;
  CameraController? cameraController;
  String predictionResult = '';

  //load model function
  _loadModel() async {
    await Tflite.loadModel(
        model: 'assets/model.tflite', labels: 'assets/labels.txt');
  }

  //load camera function
  _loadCamera() {
    // front camera description
    final frontCamera = cameraList!.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
    );

    // initialize the CameraController with the front camera
    cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
    );

    //in case if you wanna choose back camera
    // cameraController = CameraController(cameraList![0], ResolutionPreset.medium); 

    cameraController!.initialize().then((value) {
      if (!mounted) return;
      setState(() {
        cameraController!.startImageStream((image) {
          //whatever image we're getting from camera will be passed to our var
          cameraImage = image;
          //next we gotta run our model
          _runModel();
        });
      });
    });
  }

//run model function
  _runModel() async {
    if (cameraImage != null) {
      var predictions = await Tflite.runModelOnFrame(
        //extracts the byte data from each plane of the camera image
        //images are often represented as a collection of planes (YUV format)
        bytesList: cameraImage!.planes.map((plane) {
          //TensorFlow Lite expect image data to be in the form of byte arrays
          // mapping over each plane and extracting its byte data, we create a list of byte data representing the entire camera image
          return plane.bytes;
        }).toList(),
        imageHeight: cameraImage!.height,
        imageWidth: cameraImage!.width,
        imageMean: 127.5,
        imageStd: 127.5,
        rotation: 190,
        numResults: 2, //we want to get two results
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
}
