import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cropmeapp/Constants/color_constants.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:saver_gallery/saver_gallery.dart';

import 'ImageResize.dart';

class ResizeWithPlatform extends StatefulWidget {
  final File imageFile;
  final String platform;

  const ResizeWithPlatform({super.key, required this.imageFile, required this.platform});

  @override
  State<ResizeWithPlatform> createState() => _ResizeWithPlatformState();
}

class _ResizeWithPlatformState extends State<ResizeWithPlatform> {
  File? croppedImage;

  Map<String, List<List<double>>> platformRatios = {
    'Facebook': [
      [180, 180],   // 1:1 (Profile picture)
      [820, 312],   // 2.63:1 (Cover photo)
      [1200, 630],  // 1.91:1 (Link sharing)
      [1200, 900],  // 4:3 (Post image)
      [1200, 628],  // 1.91:1 (Ad image)
      [1200, 717],  // 1.67:1 (Event cover photo)
      [1920, 1080], // 16:9 (Video post)
      [1640, 856],  // 1.91:1 (Larger link sharing)
      [1080, 1920], // 9:16 (Facebook Stories)
    ],
    'Instagram': [
      [110, 110],   // 1:1 (Profile picture)
      [1080, 1080], // 1:1 (Post image)
      [1080, 608],  // 1.78:1 (Landscape image)
      [1080, 1350], // 4:5 (Portrait image)
      [1080, 1980], // 9:16 (Instagram Stories)
    ],
    'Twitter': [
      [400, 400],   // 1:1 (Profile picture)
      [1500, 500],  // 3:1 (Cover photo)
      [1200, 628],  // 1.91:1 (Link sharing)
      [1200, 675],  // 16:9 (Post image)
      [700, 800],   // 7:8 (Portrait image)
      [1200, 686],  // 16:9 (Post image)
      [1200, 600],  // 2:1 (Post image)
    ],
    'LinkedIn': [
      [400, 400],   // 1:1 (Profile picture)
      [1584, 396],  // 4:1 (Cover photo)
      [300, 300],   // 1:1 (Company logo)
      [1536, 768],  // 2:1 (Link sharing)
      [1128, 376],  // 3:1 (Banner image)
      [900, 600],   // 3:2 (Post image)
      [1200, 1200], // 1:1 (Post image)
      [1200, 627],  // 1.91:1 (Link sharing)
    ],
    'WhatsApp': [
      [192, 192],   // 1:1 (Profile picture)
      [1080, 1920], // 9:16 (WhatsApp Status)
      [500, 500],   // 1:1 (Post image)
    ],
    'Snapchat': [
      [1080, 1920], // 9:16 (Snapchat Stories)
      [1080, 2340], // 9:19.5 (Snapchat Spotlight)
    ],
    'Pinterest': [
      [165, 165],   // 1:1 (Profile picture)
      [1000, 1000], // 1:1 (Pin image)
      [1000, 1500], // 2:3 (Pin image)
      [1000, 2100], // 1:2.1 (Pin image)
      [1000, 3000], // 1:3 (Pin image)
      [800, 800],   // 1:1 (Square Pin image)
    ],
  };

  Future<void> cropImage(double width, double height) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ImageManipulation(image: widget.imageFile, width: width, height: height),
      ),
    );
    // CroppedFile? cropped = await ImageCropper().cropImage(
    //   sourcePath: widget.imageFile.path,
    //   aspectRatio: CropAspectRatio(ratioX: width, ratioY: height),
    //   compressFormat: ImageCompressFormat.jpg,
    //   compressQuality: 100,
    //   uiSettings: [
    //     AndroidUiSettings(
    //       toolbarTitle: 'Resize Image',
    //       toolbarColor: ColorConstants.bottomBar,
    //       toolbarWidgetColor: ColorConstants.primaryColor,
    //       initAspectRatio: CropAspectRatioPreset.original,
    //       lockAspectRatio: false,
    //     ),
    //     IOSUiSettings(
    //       title: 'Resize Image',
    //     ),
    //   ],
    // );
    //
    // if (cropped != null) {
    //   setState(() {
    //     croppedImage = File(cropped.path);
    //   });
    // }
  }

  @override
  Widget build(BuildContext context) {
    List<List<double>> cropRatios = platformRatios[widget.platform] ?? [];

    return Scaffold(
      backgroundColor: ColorConstants.backgroundColor,
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context, croppedImage);
          },
          child: const Icon(Icons.navigate_before, color: ColorConstants.primaryColor),
        ),
        backgroundColor: ColorConstants.bottomBar,
        title: Text(widget.platform, style: const TextStyle(color: ColorConstants.primaryColor)),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () async {
              await _saveToGallery(croppedImage!.readAsBytesSync());
              Navigator.pop(context);
            },
            icon: const Icon(FontAwesomeIcons.check, color: ColorConstants.primaryColor),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: ColorConstants.backgroundColor,
              child: croppedImage == null
                  ? Image.file(widget.imageFile)
                  : Image.file(croppedImage!),
            ),
          ),
          Container(
            height: 100,
            width: double.infinity,
            color: ColorConstants.bottomBar,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  children: cropRatios.map((ratio) {
                    double width = ratio[0];
                    double height = ratio[1];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: GestureDetector(
                        onTap: () async {
                          await cropImage(width, height);
                        },
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: ColorConstants.backgroundColor,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Center(
                            child: Text(
                              '${width.toInt()} x ${height.toInt()}',
                              style: const TextStyle(
                                color: ColorConstants.primaryColor,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _requestPermission() async {
    bool status;
    if (Platform.isAndroid) {
      final deviceInfoPlugin = DeviceInfoPlugin();
      final deviceInfo = await deviceInfoPlugin.androidInfo;
      final sdkInt = deviceInfo.version.sdkInt;
      if (sdkInt >= 29) {
        status = await Permission.manageExternalStorage.request().isGranted;
      } else {
        status = await Permission.storage.request().isGranted;
      }
    } else {
      status = await Permission.photosAddOnly.request().isGranted;
    }
  }

  Future<void> _saveToGallery(Uint8List bytes) async {
    try {
      final directory = await getExternalStorageDirectory();
      final imagePath = path.join(directory!.path, '${DateTime.now().millisecondsSinceEpoch}.jpg');
      final file = File(imagePath);
      await file.writeAsBytes(bytes);

      final result = await SaverGallery.saveFile(
        file: file.path,
        name: path.basename(file.path),
        androidExistNotSave: false,
      );
      _toastInfo('Image saved to gallery');
    } catch (e) {
      _toastInfo('Failed to save image: $e');
    }
  }

  _toastInfo(String info) {
    Fluttertoast.showToast(msg: info, toastLength: Toast.LENGTH_LONG);
  }

}