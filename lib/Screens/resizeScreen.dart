// ResizeScreen.dart

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_resizer_image/flutter_resizer_image.dart';

class ResizeScreen extends StatefulWidget {
  final File imageFile;

  const ResizeScreen({super.key, required this.imageFile});

  @override
  State<ResizeScreen> createState() => _ResizeScreenState();
}

class _ResizeScreenState extends State<ResizeScreen> {
  File? resizedImage;
  int selectedOption = 1;
  final resizerImage = FlutterResizerImage.instance();

  final List<Map<String, dynamic>> resizeOptions = [
    {'label': 'Free Crop', 'width': null, 'height': null},
    {'label': 'Original', 'width': null, 'height': null},
    {'label': '1:1', 'width': 1000, 'height': 1000},
    {'label': '4:3', 'width': 1200, 'height': 900},
    {'label': '3:4', 'width': 900, 'height': 1200},
    {'label': '16:9', 'width': 1600, 'height': 900},
    {'label': '9:16', 'width': 900, 'height': 1600},
    {'label': '5:4', 'width': 1250, 'height': 1000},
    {'label': '4:5', 'width': 1000, 'height': 1250},
  ];

  Future<File> resizeImage(int width, int height) async {
    try {
      Uint8List imageData = await widget.imageFile.readAsBytes();
      String base64Image = base64Encode(imageData);
      String path = widget.imageFile.path.toLowerCase();
      String ext = 'png';
      if (path.endsWith('.jpg') || path.endsWith('.jpeg')) {
        ext = 'jpg';
      } else if (path.endsWith('.webp')) {
        ext = 'webp';
      } else if (path.endsWith('.bmp')) {
        ext = 'bmp';
      } else if (path.endsWith('.gif')) {
        ext = 'gif';
      }

      // Some resizer plugins only support png/jpg, so fallback to png if not supported
      if (!(ext == 'png' || ext == 'jpg')) {
        ext = 'png';
      }

      Uint8List resizedBytes = await resizerImage.resizer(
        image: base64Image,
        width: width,
        height: height,
      );

      final Directory tempDir = Directory.systemTemp;
      final String tempPath = '${tempDir.path}/resized_image_${DateTime.now().millisecondsSinceEpoch}.$ext';
      File resizedFile = File(tempPath)..writeAsBytesSync(resizedBytes);
      return resizedFile;
    } catch (e) {
      print("Resize error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image resize failed: $e')),
        );
      }
      return widget.imageFile;
    }
  }

  @override
  Widget build(BuildContext context) {
    final File imageToShow = widget.imageFile;
    final double aspect = _getAspectRatio();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, imageToShow),
        ),
        actions: [
          IconButton(
            icon: Icon(FontAwesomeIcons.check, color: Colors.greenAccent),
            onPressed: () async {
              final option = resizeOptions[selectedOption];
              if (option['width'] != null && option['height'] != null) {
                File resized = await resizeImage(option['width'], option['height']);
                Navigator.pop(context, resized);
              } else {
                Navigator.pop(context, imageToShow);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: aspect,
                child: Container(
                  color: Colors.white,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      InteractiveViewer(
                        minScale: 1,
                        maxScale: 4,
                        child: Image.file(
                          imageToShow,
                          fit: BoxFit.contain,
                        ),
                      ),
                      IgnorePointer(
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: aspect,
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.blueAccent,
                                  width: 2.5,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 100,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: resizeOptions.length,
              itemBuilder: (context, index) {
                final option = resizeOptions[index];
                final isSelected = selectedOption == index;
                final sizeText = option['width'] != null ? "${option['width']}x${option['height']}" : "Auto";

                return GestureDetector(
                  onTap: () {
                    setState(() => selectedOption = index);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.blueAccent : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(option['label'],
                            style: TextStyle(
                                color: isSelected ? Colors.black : Colors.white,
                                fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text(sizeText,
                            style: TextStyle(
                                color: isSelected ? Colors.black87 : Colors.grey[400],
                                fontSize: 11)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  double _getAspectRatio() {
    final option = resizeOptions[selectedOption];
    if (option['width'] != null && option['height'] != null && option['height'] != 0) {
      return option['width'] / option['height'];
    }
    return 1.0;
  }
}
