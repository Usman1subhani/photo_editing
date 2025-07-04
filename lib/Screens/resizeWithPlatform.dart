import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'; 
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';

class ResizeWithPlatform extends StatefulWidget {
  final File imageFile;
  final String platform;

  const ResizeWithPlatform(
      {super.key, required this.imageFile, required this.platform});

  @override
  State<ResizeWithPlatform> createState() => _ResizeWithPlatformState();
}

class _ResizeWithPlatformState extends State<ResizeWithPlatform> {
  bool showBorder = true;
  void _showSavingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: SizedBox(
          width: 120,
          height: 120,
          child: Card(
            color: Colors.black87,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.greenAccent),
                  SizedBox(height: 16),
                  Text('Saving...', style: TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  final TransformationController _transformationController =
      TransformationController();
  final GlobalKey _previewKey = GlobalKey();
  int selectedOption = 0;
  bool isSaving = false;

  Future<File> captureRenderedImageAndResize(int width, int height) async {
    try {
      RenderRepaintBoundary boundary = _previewKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      var image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      img.Image? decoded = img.decodeImage(pngBytes);
      if (decoded == null) throw Exception('Failed to decode screenshot');
      img.Image resized = img.copyResize(decoded, width: width, height: height);
      Uint8List resizedBytes = Uint8List.fromList(img.encodePng(resized));

      final Directory tempDir = Directory.systemTemp;
      final String tempPath =
          '${tempDir.path}/final_rendered_image_${DateTime.now().millisecondsSinceEpoch}.png';
      File resizedFile = File(tempPath)..writeAsBytesSync(resizedBytes);
      return resizedFile;
    } catch (e) {
      print("Render error: $e");
      return widget.imageFile;
    }
  }

  // Platform-specific size options
  final Map<String, List<Map<String, dynamic>>> platformOptions = {
    'Facebook': [
      {'label': 'Profile', 'width': 180, 'height': 180, 'aspect': 1.0},
      {'label': 'Post', 'width': 1200, 'height': 630, 'aspect': 1200 / 630},
      {'label': 'Cover', 'width': 851, 'height': 312, 'aspect': 16 / 9},
      {'label': 'Story', 'width': 1080, 'height': 1920, 'aspect': 9 / 16},
      {'label': 'Groups', 'width': 1640, 'height': 956, 'aspect': 1.91 / 1},
      {'label': 'Events', 'width': 1200, 'height': 628, 'aspect': 16 / 9},
      {'label': 'Portrait', 'width': 1080, 'height': 1350, 'aspect': 4 / 5},
    ],
    'Instagram': [
      {'label': 'Profile', 'width': 110, 'height': 110, 'aspect': 1.0},
      {'label': 'Post', 'width': 1080, 'height': 1080, 'aspect': 1.0},
      {'label': 'Portrait', 'width': 1080, 'height': 1350, 'aspect': 4 / 5},
      {'label': 'Landscape', 'width': 1080, 'height': 566, 'aspect': 1.91 / 1},
      {'label': 'Story', 'width': 1080, 'height': 1920, 'aspect': 9 / 16},
      {'label': 'Reel', 'width': 1080, 'height': 1920, 'aspect': 9 / 16},
    ],
    'TikTok': [
      {'label': 'Profile', 'width': 20, 'height': 20, 'aspect': 1.0},
      {
        'label': 'Virtical Image AD',
        'width': 540,
        'height': 960,
        'aspect': 0.56 / 1
      },
      {'label': 'Square Image AD', 'width': 640, 'height': 640, 'aspect': 1.1},
      {
        'label': 'Landscape Image AD',
        'width': 960,
        'height': 540,
        'aspect': 16 / 9
      },
      {'label': 'Video', 'width': 1080, 'height': 1920, 'aspect': 9 / 16},
    ],
    'YouTube': [
      {'label': 'Profile', 'width': 800, 'height': 800, 'aspect': 1.0},
      {
        'label': 'Channel Cover',
        'width': 2560,
        'height': 1440,
        'aspect': 16 / 9
      },
      {
        'label': 'Video Thumbnail',
        'width': 1280,
        'height': 720,
        'aspect': 16 / 9
      },
      {'label': 'Video', 'width': 1080, 'height': 1920, 'aspect': 16 / 9},
    ],
    'Twitter': [
      {'label': 'Profile', 'width': 400, 'height': 400, 'aspect': 1.0},
      {'label': 'Cover', 'width': 1500, 'height': 500, 'aspect': 3 / 1},
      {
        'label': 'Landscape Post',
        'width': 1600,
        'height': 900,
        'aspect': 16 / 9
      },
      {
        'label': 'Landscape Post',
        'width': 1800,
        'height': 1800,
        'aspect': 1 / 1
      },
    ],
    'LinkedIn': [
      {'label': 'Profile', 'width': 400, 'height': 400, 'aspect': 1.0},
      {'label': 'Cover', 'width': 1128, 'height': 191, 'aspect': 5.91 / 1},
      {'label': 'Post', 'width': 1200, 'height': 627, 'aspect': 1.91 / 1},
      {
        'label': 'Sponsored Carousel',
        'width': 1080,
        'height': 1080,
        'aspect': 1 / 1
      },
    ],
    'WhatsApp': [
      {'label': 'Profile', 'width': 192, 'height': 192, 'aspect': 1.0},
      {'label': 'Status', 'width': 1080, 'height': 1920, 'aspect': 9 / 16},
    ],
    'Snapchat': [
      {'label': 'Story', 'width': 1080, 'height': 1920, 'aspect': 9 / 16},
      {'label': 'Profile', 'width': 320, 'height': 320, 'aspect': 1.0},
    ],
    'Pinterest': [
      {'label': 'Profile', 'width': 165, 'height': 165, 'aspect': 1.0},
      {'label': 'Profile Cover', 'width': 800, 'height': 450, 'aspect': 16 / 9},
      {
        'label': 'Standard Pins',
        'width': 1000,
        'height': 1500,
        'aspect': 2 / 3
      },
      {'label': 'Square Pins', 'width': 1000, 'height': 1000, 'aspect': 1 / 1},
      {'label': 'Story Pins', 'width': 1080, 'height': 1920, 'aspect': 9 / 16},
      {'label': 'Board Cover', 'width': 222, 'height': 150, 'aspect': 37 / 25},
    ],
  };

  Future<void> _saveImageToGallery(File imageFile) async {
    try {
      setState(() => isSaving = true);

      PermissionStatus status;
      if (await Permission.photos.request().isGranted) {
        status = PermissionStatus.granted;
      } else {
        status = await Permission.storage.request();
      }

      if (!status.isGranted) {
        if (status.isPermanentlyDenied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  'Storage permission permanently denied. Please enable it in app settings.'),
              action: SnackBarAction(
                  label: 'Settings', onPressed: () => openAppSettings()),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Storage permission not granted')),
          );
        }
        throw Exception('Storage permission not granted');
      }

      final bytes = await imageFile.readAsBytes();
      final result = await ImageGallerySaver.saveImage(
        bytes,
        quality: 100,
        name: "resized_image_${DateTime.now().millisecondsSinceEpoch}",
      );

      if (result['isSuccess'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image saved to gallery!')),
        );
      } else {
        throw Exception('Failed to save image');
      }
    } catch (e) {
      print("Save error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save image: $e')),
      );
    } finally {
      setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = platformOptions[widget.platform] ?? [];
    final double aspect = selectedOption < options.length
        ? options[selectedOption]['aspect'] ?? 1.0
        : 1.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.platform, style: const TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          if (isSaving)
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: CircularProgressIndicator(color: Colors.white),
            )
          else
            IconButton(
              icon: const Icon(FontAwesomeIcons.check, color: Colors.greenAccent),
              onPressed: () async {
                _showSavingDialog();
                setState(() => showBorder = false);
                await Future.delayed(const Duration(milliseconds: 50));
                if (selectedOption < options.length) {
                  final option = options[selectedOption];
                  File imageToSave = await captureRenderedImageAndResize(option['width'], option['height']);
                  await _saveImageToGallery(imageToSave);
                  setState(() => showBorder = true);
                  if (mounted) Navigator.of(context, rootNavigator: true).pop(); // Dismiss loader
                  if (mounted) Navigator.pop(context, imageToSave);
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
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    RepaintBoundary(
                      key: _previewKey,
                      child: InteractiveViewer(
                        transformationController: _transformationController,
                        minScale: 1,
                        maxScale: 4,
                        child: Image.file(
                          widget.imageFile,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    if (showBorder)
                      IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blueAccent, width: 2.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                  ],
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
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 6)
              ],
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: options.length,
              itemBuilder: (context, index) {
                final option = options[index];
                final isSelected = selectedOption == index;
                return GestureDetector(
                  onTap: () => setState(() => selectedOption = index),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withOpacity(0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: CustomPaint(
                            painter: _AspectRatioPainter(
                              aspectRatio: option['aspect'],
                              color: isSelected ? Colors.white : Colors.grey[400]!,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          option['label'],
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[400],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
}

class _AspectRatioPainter extends CustomPainter {
  final double aspectRatio;
  final Color color;

  _AspectRatioPainter({required this.aspectRatio, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    double w, h;
    if (aspectRatio > 1) {
      w = size.width;
      h = size.width / aspectRatio;
    } else {
      h = size.height;
      w = size.height * aspectRatio;
    }

    final left = (size.width - w) / 2;
    final top = (size.height - h) / 2;

    final rect = Rect.fromLTWH(left, top, w, h);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
