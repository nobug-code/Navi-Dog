import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

class DetectionScreen extends StatefulWidget {
  const DetectionScreen({super.key});

  @override
  State<DetectionScreen> createState() => _DetectionScreenState();
}

class _DetectionScreenState extends State<DetectionScreen> {
  CameraController? controller;
  bool isLoaded = false;
  List<CameraDescription> cameras = [];
  List<Offset> points = [
    Offset(50, 50),
    Offset(150, 50),
    Offset(150, 150),
    Offset(50, 150),
  ];
  Timer? _timer;
  bool isStreaming = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        controller = CameraController(cameras[0], ResolutionPreset.max);
        await controller?.initialize();
        startTimedImageStream();
      }
      isLoaded = true;
      setState(() {});
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void startTimedImageStream() {
    _timer = Timer.periodic(Duration(seconds: 1), (Timer timer) async {
      if (controller != null && !isStreaming) {
        isStreaming = true;
        controller?.startImageStream((CameraImage image) {
          controller?.stopImageStream();
          processImage(image);
          isStreaming = false;
        });
      }
    });
  }

  void processImage(CameraImage image) async {
    var imageData = _convertYUV420toBytes(image);
    try {
      // Convert the image to a smaller, manageable size
      // final response = await http.post(
      //   Uri.parse('https://your-api-url.com/process'),
      //   headers: {'Content-Type': 'application/octet-stream'},
      //   body: imageData,
      // );
      //
      // if (response.statusCode == 200) {
      //   final responseData = json.decode(response.body);
      //   final newPoints = extractPointsFromResponse(responseData);
      //   setState(() {
      //     points = newPoints;
      //   });
      // }
    } catch (e) {
      // Handle errors
    }
  }

  Uint8List _convertYUV420toBytes(CameraImage image) {
    final int width = image.width;
    final int height = image.height;

    // Y plane
    final int yRowStride = image.planes[0].bytesPerRow;
    final int uvRowStride = image.planes.length > 1 ? image.planes[1].bytesPerRow : 0;
    final int uvPixelStride = image.planes.length > 1 ? image.planes[1].bytesPerPixel ?? 1 : 0;

    var img = Uint8List(3 * width * height);

    // Y plane
    int yIndex = 0;
    for (int i = 0; i < height; i++) {
      int yRowIndex = i * yRowStride;
      for (int j = 0; j < width; j++) {
        img[yIndex++] = image.planes[0].bytes[yRowIndex + j];
      }
    }

    // U and V planes
    if (image.planes.length > 1) {
      int uvIndex = width * height;
      for (int i = 0; i < height / 2; i++) {
        int uvRowIndex = i * uvRowStride;
        for (int j = 0; j < width / 2; j++) {
          int uvPixelIndex = uvRowIndex + j * uvPixelStride;
          img[uvIndex++] = image.planes[1].bytes[uvPixelIndex];
          img[uvIndex++] = image.planes[2].bytes[uvPixelIndex];
        }
      }
    }

    return img;
  }

  List<Offset> extractPointsFromResponse(Map<String, dynamic> response) {
    // Assuming response contains 'points' with the coordinates
    final List<dynamic> pointData = response['points'];
    return pointData
        .map((p) => Offset(p[0].toDouble(), p[1].toDouble()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null && !isLoaded) {
      return Center(
        child: CupertinoActivityIndicator(),
      );
    }
    if (isLoaded && cameras.isEmpty) {
      return Center(
        child: Text('카메라가 없습니다.'),
      );
    }
    if (!controller!.value.isInitialized) return Container();
    return Stack(children: [
      Center(child: CameraPreview(controller!)),
      Center(
        child: CustomPaint(
          painter: BoxPainter(points),
        ),
      ),
    ]);
  }
}

class BoxPainter extends CustomPainter {
  final List<Offset> points;

  BoxPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    if (points.length == 4) {
      final rect = Rect.fromPoints(points[0], points[2]);
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

