// ✅ This is your updated and fixed ResizeScreen.dart file

// [NO CHANGES NEEDED HERE]
import 'dart:io';
import 'dart:typed_data';
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

  Future<File> cropAndResizeVisibleArea(int width, int height) async {
    try {
      Uint8List imageData = await widget.imageFile.readAsBytes();
      img.Image? decoded = img.decodeImage(imageData);
      if (decoded == null) throw Exception('Failed to decode image');

      final RenderBox? renderBox =
          _previewKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox == null) throw Exception('Preview not ready');

      final Size previewSize = renderBox.size;
      double imgW = decoded.width.toDouble();
      double imgH = decoded.height.toDouble();
      double frameW = previewSize.width;
      double frameH = previewSize.height;

      double scaleX = frameW / imgW;
      double scaleY = frameH / imgH;
      double scale = scaleX < scaleY ? scaleX : scaleY;

      double displayW = imgW * scale;
      double displayH = imgH * scale;
      double offsetX = (frameW - displayW) / 2;
      double offsetY = (frameH - displayH) / 2;

      Matrix4 matrix = _transformationController.value;
      double userScale = matrix.getMaxScaleOnAxis();
      double userTransX = matrix.row0[3];
      double userTransY = matrix.row1[3];

      double totalScale = scale * userScale;
      double transX = offsetX + userTransX;
      double transY = offsetY + userTransY;

      double cropLeft = (-transX) / totalScale;
      double cropTop = (-transY) / totalScale;
      double cropWidth = frameW / totalScale;
      double cropHeight = frameH / totalScale;

      cropLeft = cropLeft.clamp(0.0, imgW - 1);
      cropTop = cropTop.clamp(0.0, imgH - 1);
      if (cropLeft + cropWidth > imgW) cropWidth = imgW - cropLeft;
      if (cropTop + cropHeight > imgH) cropHeight = imgH - cropTop;

      img.Image cropped = img.copyCrop(
        decoded,
        x: cropLeft.round(),
        y: cropTop.round(),
        width: cropWidth.round(),
        height: cropHeight.round(),
      );

      img.Image resized = img.copyResize(
        cropped,
        width: width,
        height: height,
        interpolation: img.Interpolation.linear,
      );

      Uint8List pngBytes = Uint8List.fromList(img.encodePng(resized));
      final String path =
          '${Directory.systemTemp.path}/frame_crop_${DateTime.now().millisecondsSinceEpoch}.png';
      File output = File(path)..writeAsBytesSync(pngBytes);
      return output;
    } catch (e) {
      print("Error: $e");
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

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: BackButton(color: Colors.white),
        actions: [
          if (isSaving)
            const Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(color: Colors.white),
            )
          else
            IconButton(
              icon:
                  const Icon(FontAwesomeIcons.check, color: Colors.greenAccent),
              onPressed: () async {
                File finalFile = imageToShow;
                if (option['width'] != null && option['height'] != null) {
                  finalFile = await cropAndResizeVisibleArea(
                      option['width'], option['height']);
                }
                await _saveImageToGallery(finalFile);
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
                    IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          border:
                              Border.all(color: Colors.blueAccent, width: 2.5),
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
            height: 90,
            color: Colors.grey[900],
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: resizeOptions.length,
              itemBuilder: (context, index) {
                final isSelected = selectedOption == index;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedOption = index;
                      // 👇 DO NOT reset the transformation controller
                      // _transformationController.value = Matrix4.identity(); ❌ REMOVE THIS
                    });
                  },
                  child: Container(
                    width: 70,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white24
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: resizeOptions[index]['aspect'] == null
                              ? const Icon(Icons.crop, color: Colors.white)
                              : CustomPaint(
                                  painter: _AspectRatioPainter(
                                    aspectRatio: resizeOptions[index]['aspect'],
                                    color:
                                        isSelected ? Colors.white : Colors.grey,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          resizeOptions[index]['label'],
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey,
                            fontSize: 11,
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
