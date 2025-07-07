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

  // Removed duplicate build method
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: BackButton(color: theme.colorScheme.onSurface),
        centerTitle: true,
        title: Text(
          'Edit',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.save_alt_rounded, color: theme.colorScheme.primary),
            tooltip: 'Save',
            onPressed: () async {
              _showSavingDialog();
              // Simulate a save animation
              await Future.delayed(const Duration(milliseconds: 900));
              if (mounted) Navigator.of(context, rootNavigator: true).pop();
              _toastInfo('Image saved!');
            },
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: ProImageEditor.file(
          key: ValueKey(widget.imageFile.path),
          widget.imageFile,
          callbacks: ProImageEditorCallbacks(
            onImageEditingComplete: (Uint8List bytes) async {
              editImage = File.fromRawPath(bytes);
              await _saveToGallery(bytes);  // Save the image when editing is complete
              if (mounted) Navigator.pop(context, editImage);
            },
          ),
        ),
      ),
    );
  }

  // Modern loader dialog with animation and Material 3 styling
  Future<void> _showSavingDialog([String message = "Saving..."]) async {
    final theme = Theme.of(context);
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.7, end: 1.0),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeInOut,
                builder: (context, scale, child) => Transform.scale(
                  scale: scale,
                  child: CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                    strokeWidth: 5,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                message,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Requesting necessary permissions
  Future<void> _requestPermission() async {
    if (Platform.isAndroid) {
      final deviceInfoPlugin = DeviceInfoPlugin();
      final deviceInfo = await deviceInfoPlugin.androidInfo;
      final sdkInt = deviceInfo.version.sdkInt;
      if (sdkInt >= 29) {
        await Permission.manageExternalStorage.request();
      } else {
        await Permission.storage.request();
      }
    } else {
      await Permission.photosAddOnly.request();
    }
  }

  // Save the image to the gallery
  Future<void> _saveToGallery(Uint8List bytes) async {
    try {
      final directory = await getExternalStorageDirectory();
      final imagePath = path.join(directory!.path, '${DateTime.now().millisecondsSinceEpoch}.jpg');
      final file = File(imagePath);
      await file.writeAsBytes(bytes);

      // Save the image to the gallery using SaverGallery
      await SaverGallery.saveFile(
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
void _toastInfo(String info) {
  final theme = Theme.of(context);
  Fluttertoast.showToast(
    msg: info,
    toastLength: Toast.LENGTH_LONG,
    backgroundColor: theme.colorScheme.surface.withOpacity(0.95),
    textColor: theme.colorScheme.onSurface,
    fontSize: 16.0,
  );
}
}
