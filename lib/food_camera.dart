import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:math' as math;
import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as image;
import 'dart:io';

class TakePicture extends StatefulWidget {
  const TakePicture({super.key, required this.camera});
  final CameraDescription camera;

  @override
  createState() => _TakePictureScreenState();
}
class _TakePictureScreenState extends State<TakePicture> {
  late final CameraController _controller;
  late final Future<void> _initializeControllerFuture;
  late final Future<List<String>> _loadLabelsFuture;

  Future<List<String>> loadLabels() async {
    final data = await rootBundle.loadString("assets/labels.csv");
    return const CsvToListConverter().convert(data).map((e) => e[1] as String).toList().sublist(1);
  }

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.medium, enableAudio: false);
    _initializeControllerFuture = _controller.initialize();
    _loadLabelsFuture = loadLabels();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Food Camera")),
        body: FutureBuilder<void>(
          future: _initializeControllerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              final size = MediaQuery.of(context).size.width;
              return Container(
                alignment: Alignment.center,
                child: SizedBox(
                  height: size,
                  width: size,
                  child: ClipRect(
                    child: OverflowBox(
                      alignment: Alignment.center,
                      child: FittedBox(
                        fit: BoxFit.fitWidth,
                        child: SizedBox(
                          width: size,
                          height: size * _controller.value.aspectRatio,
                          child: CameraPreview(_controller),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            predictFood().then((result) => Navigator.pop(context, result));
          },
          child: const Icon(Icons.camera_alt),
        )
    );
  }

  image.Image preprocessImage(Uint8List bytes, int width, int height) {
    image.Image img = image.decodeImage(bytes)!;
    final smallest = [img.width, img.height].reduce(math.min);
    final x = (img.width / 2) - smallest / 2;
    final y = (img.height / 2) - smallest / 2;
    img = image.copyCrop(img, x: x.toInt(), y: y.toInt(), width: smallest, height: smallest);
    img = image.copyResize(img, width: width, height: height);
    return img;
  }

  Future<List<String>> predictFood() async {
    await _initializeControllerFuture;
    final classes = await _loadLabelsFuture;
    final model = Model(await Interpreter.fromAsset("assets/model.tflite"));
    final file = await _controller.takePicture();
    image.Image img = preprocessImage(await File(file.path).readAsBytes(), model.width, model.height);
    await File(file.path).writeAsBytes(image.encodeJpg(img));
    final imageMatrix = List.generate(model.height, (y) => List.generate(model.width, (x) {
      final pixel = img.getPixel(x, y);
      return [pixel.r, pixel.g, pixel.b];
    }));
    final input = [imageMatrix];
    final output = [List<int>.filled(model.outputShape[1], 0)];
    model.run(input, output);
    model.close();
    final result = output.first.asMap();
    List<String> names = [];
    result.forEach((index, curValue) {
      double value = curValue / 255;
      if (value > 0.25) {
        names.add(classes[index]);
      }
    });
    return names;
  }
}

class Model {
  Model(this.interpreter) :
        inputShape = interpreter.getInputTensor(0).shape,
        outputShape = interpreter.getOutputTensor(0).shape,
        inputType = interpreter.getInputTensor(0).type,
        outputType = interpreter.getOutputTensor(0).type;

  final Interpreter interpreter;
  final List<int> inputShape, outputShape;
  final TensorType inputType, outputType;
  int get width => inputShape[1];
  int get height => inputShape[2];
  void run(inputs, outputs) => interpreter.run(inputs, outputs);
  void close() => interpreter.close();
}