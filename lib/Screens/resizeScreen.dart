// ✅ This is your updated and fixed ResizeScreen.dart file

// [NO CHANGES NEEDED HERE]
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_resizer_image/flutter_resizer_image.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;

class ResizeScreen extends StatefulWidget {
  final File imageFile;
  const ResizeScreen({super.key, required this.imageFile});

  @override
  State<ResizeScreen> createState() => _ResizeScreenState();
}

class _ResizeScreenState extends State<ResizeScreen> {
  Future<void> _showSavingDialog([String message = "Saving..."]) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: isDark ? const Color(0xFF232336) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: isDark ? const Color(0xFFB69DF8) : Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                message,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  final GlobalKey _previewKey = GlobalKey();
  final TransformationController _transformationController =
      TransformationController();
  final resizerImage = FlutterResizerImage.instance();

  bool isSaving = false;
  int selectedOption = 1;
  File? resizedImage;

  final List<Map<String, dynamic>> resizeOptions = [
    // Basic ratios
    {'label': 'Custom', 'width': null, 'height': null, 'aspect': null},
    {'label': 'Original', 'width': null, 'height': null, 'aspect': null},

    // Standard ratios
    {'label': '1:1', 'width': 1080, 'height': 1080, 'aspect': 1.0},
    {'label': '4:3', 'width': 1200, 'height': 900, 'aspect': 4 / 3},
    {'label': '3:4', 'width': 900, 'height': 1200, 'aspect': 3 / 4},
    {'label': '16:9', 'width': 1920, 'height': 1080, 'aspect': 16 / 9},
    {'label': '9:16', 'width': 1080, 'height': 1920, 'aspect': 9 / 16},

    // Instagram
    {'label': 'Profile', 'width': 110, 'height': 110, 'aspect': 1.0},
    {'label': 'IG Post', 'width': 1080, 'height': 1080, 'aspect': 1.0},
    {'label': 'IG Portrait', 'width': 1080, 'height': 1350, 'aspect': 4 / 5},
    {'label': 'IG Landscape', 'width': 1080, 'height': 566, 'aspect': 1.91 / 1},
    {'label': 'IG Story', 'width': 1080, 'height': 1920, 'aspect': 9 / 16},
    {'label': 'IG Reel', 'width': 1080, 'height': 1920, 'aspect': 9 / 16},

    // Facebook
    {'label': 'FB Post', 'width': 1200, 'height': 630, 'aspect': 1.91 / 1},
    {'label': 'FB Story', 'width': 1080, 'height': 1920, 'aspect': 9 / 16},
    {'label': 'FB Cover', 'width': 820, 'height': 312, 'aspect': 2.63 / 1},

    // Twitter
    {'label': 'Twitter Post', 'width': 1200, 'height': 675, 'aspect': 16 / 9},
    {'label': 'Twitter Card', 'width': 1200, 'height': 628, 'aspect': 1.91 / 1},
    {'label': 'Twitter Header', 'width': 1500, 'height': 500, 'aspect': 3 / 1},

    // Pinterest
    {'label': 'Pinterest Pin', 'width': 1000, 'height': 1500, 'aspect': 2 / 3},
    {
      'label': 'Pinterest Story',
      'width': 1080,
      'height': 1920,
      'aspect': 9 / 16
    },

    // LinkedIn
    {
      'label': 'LinkedIn Post',
      'width': 1200,
      'height': 627,
      'aspect': 1.91 / 1
    },
    {'label': 'LinkedIn Cover', 'width': 1584, 'height': 396, 'aspect': 4 / 1},
    {
      'label': 'LinkedIn Story',
      'width': 1080,
      'height': 1920,
      'aspect': 9 / 16
    },

    // YouTube
    {
      'label': 'YouTube Thumbnail',
      'width': 1280,
      'height': 720,
      'aspect': 16 / 9
    },
    {
      'label': 'YouTube Channel',
      'width': 2560,
      'height': 1440,
      'aspect': 16 / 9
    },

    // TikTok
    {'label': 'TikTok Video', 'width': 1080, 'height': 1920, 'aspect': 9 / 16},
    {'label': 'TikTok Cover', 'width': 1080, 'height': 1920, 'aspect': 9 / 16},

    // Snapchat
    {
      'label': 'Snapchat Story',
      'width': 1080,
      'height': 1920,
      'aspect': 9 / 16
    },

    // WhatsApp
    {
      'label': 'WhatsApp Status',
      'width': 1080,
      'height': 1920,
      'aspect': 9 / 16
    },

    // Telegram
    {'label': 'Telegram Post', 'width': 1080, 'height': 1080, 'aspect': 1.0},
  ];

  bool showBorder = true;

  Future<File> captureRenderedImageAndResize(int width, int height) async {
    try {
      RenderRepaintBoundary boundary = _previewKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      var image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      img.Image? decoded = img.decodeImage(pngBytes);
      if (decoded == null) throw Exception('Failed to decode screenshot');
      img.Image resized = img.copyResize(decoded, width: width, height: height);
      Uint8List resizedBytes = Uint8List.fromList(img.encodePng(resized));

      final Directory tempDir = Directory.systemTemp;
      final String tempPath = '${tempDir.path}/frame_crop_${DateTime.now().millisecondsSinceEpoch}.png';
      File resizedFile = File(tempPath)..writeAsBytesSync(resizedBytes);
      return resizedFile;
    } catch (e) {
      print("Render error: $e");
      return widget.imageFile;
    }
  }

  Future<void> _saveImageToGallery(File imageFile) async {
    setState(() => isSaving = true);
    try {
      PermissionStatus status = await Permission.photos.request();
      if (!status.isGranted) status = await Permission.storage.request();
      if (!status.isGranted) throw Exception('Permission denied');

      final bytes = await imageFile.readAsBytes();
      final result = await ImageGallerySaver.saveImage(
        bytes,
        quality: 100,
        name: "frame_cropped_${DateTime.now().millisecondsSinceEpoch}",
      );

      if (result['isSuccess'] == true) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image saved!')),
        );
      }
    } catch (e) {
      print("Save error: $e");
    } finally {
      setState(() => isSaving = false);
    }
  }

  double _getAspectRatio() {
    final option = resizeOptions[selectedOption];
    if (option['width'] != null && option['height'] != null) {
      return option['width'] / option['height'];
    }
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final option = resizeOptions[selectedOption];
    final double aspect = _getAspectRatio();
    final File imageToShow = widget.imageFile;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF181824) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF232336) : Colors.white,
        leading: BackButton(color: isDark ? Colors.white : Colors.black),
        elevation: 0,
        title: Text(
          'Resize Image',
          style: TextStyle(
            color: isDark ? const Color(0xFFB69DF8) : Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          if (isSaving)
            Padding(
              padding: const EdgeInsets.all(12),
              child: CircularProgressIndicator(
                color: isDark ? const Color(0xFFB69DF8) : Theme.of(context).colorScheme.primary,
              ),
            )
          else
            IconButton(
              icon: Icon(FontAwesomeIcons.check, color: isDark ? const Color(0xFFB69DF8) : Colors.greenAccent),
              onPressed: () async {
                await _showSavingDialog();
                setState(() => showBorder = false);
                await Future.delayed(const Duration(milliseconds: 50));
                File finalFile = imageToShow;
                if (option['width'] != null && option['height'] != null) {
                  finalFile = await captureRenderedImageAndResize(option['width'], option['height']);
                }
                setState(() => showBorder = true);
                await _saveImageToGallery(finalFile);
                if (mounted) Navigator.of(context, rootNavigator: true).pop(); // Dismiss loader
                if (mounted) Navigator.pop(context, finalFile);
              },
            ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: aspect,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    RepaintBoundary(
                      key: _previewKey,
                      child: Card(
                        color: isDark ? const Color(0xFF232336) : Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        child: InteractiveViewer(
                          transformationController: _transformationController,
                          minScale: 1,
                          maxScale: 4,
                          child: Image.file(
                            imageToShow,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    if (showBorder)
                      IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isDark ? const Color(0xFFB69DF8) : Colors.blueAccent,
                              width: 2.5,
                            ),
                            borderRadius: BorderRadius.circular(14),
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
            height: 90,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF232336) : Colors.grey[100],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black.withOpacity(0.2) : Colors.grey.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: resizeOptions.length,
              itemBuilder: (context, index) {
                final isSelected = selectedOption == index;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedOption = index;
                    });
                  },
                  child: Container(
                    width: 70,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark ? const Color(0xFFB69DF8).withOpacity(0.18) : Colors.white24)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark ? const Color(0xFFB69DF8).withOpacity(0.22) : Colors.white38)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: resizeOptions[index]['aspect'] == null
                              ? Icon(Icons.crop, color: isDark ? Colors.white : Colors.black)
                              : CustomPaint(
                                  painter: _AspectRatioPainter(
                                    aspectRatio: resizeOptions[index]['aspect'],
                                    color: isSelected
                                        ? (isDark ? const Color(0xFFB69DF8) : Colors.white)
                                        : (isDark ? Colors.white54 : Colors.grey),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          resizeOptions[index]['label'],
                          style: TextStyle(
                            color: isSelected
                                ? (isDark ? const Color(0xFFB69DF8) : Colors.white)
                                : (isDark ? Colors.white54 : Colors.grey),
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
  bool shouldRepaint(_) => false;
}
