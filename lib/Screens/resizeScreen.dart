import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cropmeapp/Constants/color_constants.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pro_image_editor/models/editor_callbacks/pro_image_editor_callbacks.dart';
import 'package:pro_image_editor/modules/main_editor/main_editor.dart';
import 'package:flutter_resizer_image/flutter_resizer_image.dart';

class ResizeScreen extends StatefulWidget {
  final File imageFile;

  const ResizeScreen({super.key, required this.imageFile});

  @override
  State<ResizeScreen> createState() => _ResizeScreenState();
}

class _ResizeScreenState extends State<ResizeScreen> {
  File? croppedImage;
  final resizerImage = FlutterResizerImage.instance();

  final List<Map<String, dynamic>> resizeOptions = [
    {'label': 'Free Crop', 'width': null, 'height': null},
    {'label': 'Original', 'width': null, 'height': null},
    {'label': '1:1', 'width': 100, 'height': 100},
    {'label': '4:3', 'width': 400, 'height': 300},
    {'label': '3:4', 'width': 300, 'height': 400},
    {'label': '16:9', 'width': 1600, 'height': 900},
    {'label': '9:16', 'width': 900, 'height': 1600},
  ];

  Future<void> resizeImage(int width, int height) async {
    try {
      Uint8List imageData = await widget.imageFile.readAsBytes();
      String base64Image = base64Encode(imageData);

      Uint8List resizedImageBase64 = await resizerImage.resizer(
        image: base64Image,
        width: width,
        height: height,
      );

      Uint8List resizedImageBytes = base64Decode(resizedImageBase64 as String);
      final Directory tempDir = Directory.systemTemp;
      final String tempPath = '${tempDir.path}/resized_image.png';
      File resizedImageFile = File(tempPath)
        ..writeAsBytesSync(resizedImageBytes);

      setState(() {
        croppedImage = resizedImageFile;
      });
    } catch (e) {
      print("Error resizing image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.backgroundColor,
      appBar: AppBar(
          leading: GestureDetector(
              onTap: () {
                Navigator.pop(context, croppedImage);
              },
              child: const Icon(Icons.navigate_before,
                  color: ColorConstants.primaryColor)),
          backgroundColor: ColorConstants.bottomBar,
          actions: [
            IconButton(
                onPressed: () {},
                icon: const Icon(FontAwesomeIcons.check,
                    color: ColorConstants.primaryColor)),
          ]),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: ColorConstants.backgroundColor,
              child: Center(
                  child: croppedImage == null
                      ? Image.file(widget.imageFile)
                      : Image.file(croppedImage!),
              ),
            ),
          ),
          Container(
            height: 100,
            width: double.infinity,
            color: ColorConstants.bottomBar,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: resizeOptions.map((option) {
                  return GestureDetector(
                    onTap: () {
                      resizeImage(option['width'], option['height']);
                    },
                    child: Container(
                      margin: const EdgeInsets.all(8.0),
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      decoration: BoxDecoration(
                        color: ColorConstants.primaryColor,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        option['label'],
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
