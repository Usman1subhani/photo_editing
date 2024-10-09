import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:path/path.dart' as path;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pro_image_editor/models/editor_callbacks/pro_image_editor_callbacks.dart';
import 'package:pro_image_editor/modules/main_editor/main_editor.dart';
import 'package:saver_gallery/saver_gallery.dart';

class EditImage extends StatefulWidget {
  final File imageFile;

  const EditImage({super.key, required this.imageFile});

  @override
  State<EditImage> createState() => _EditImageState();
}

class _EditImageState extends State<EditImage> {
  final GlobalKey _globalKey = GlobalKey();
  File? editImage;

  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ProImageEditor.file(
        widget.imageFile,
        callbacks: ProImageEditorCallbacks(
          onImageEditingComplete: (Uint8List bytes) async {
            editImage = File.fromRawPath(bytes);
            await _saveToGallery(bytes);  // Save the image when editing is complete
            Navigator.pop(context, editImage);
          },
        ),
      ),
    );
  }

  // Requesting necessary permissions
  Future<void> _requestPermission() async {
    bool status;
    if (Platform.isAndroid) {
      final deviceInfoPlugin = DeviceInfoPlugin();
      final deviceInfo = await deviceInfoPlugin.androidInfo;
      final sdkInt = deviceInfo.version.sdkInt;
      if (sdkInt >= 29) {
        // Request MANAGE_EXTERNAL_STORAGE for Android 10+
        status = await Permission.manageExternalStorage.request().isGranted;
      } else {
        // For Android 9 and below, request WRITE_EXTERNAL_STORAGE
        status = await Permission.storage.request().isGranted;
      }
    } else {
      // iOS-specific permissions
      status = await Permission.photosAddOnly.request().isGranted;
    }

    // _toastInfo('Permission granted: $status');
  }

  // Save the image to the gallery
  Future<void> _saveToGallery(Uint8List bytes) async {
    try {
      final directory = await getExternalStorageDirectory();
      final imagePath = path.join(directory!.path, '${DateTime.now().millisecondsSinceEpoch}.jpg');
      final file = File(imagePath);
      await file.writeAsBytes(bytes);

      // Save the image to the gallery using SaverGallery
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

  // Show toast message
  _toastInfo(String info) {
    Fluttertoast.showToast(msg: info, toastLength: Toast.LENGTH_LONG);
  }
}
