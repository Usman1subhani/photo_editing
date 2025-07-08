import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart'; 
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

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

  bool isSaving = false;
  int selectedOption = 1;
  File? resizedImage;
  Color _backgroundColor = Colors.black;

  final List<Color> _predefinedColors = [
    Colors.black,
    Colors.white,
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
  ];

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

  Future<File> captureRenderedImage() async {
    try {
      RenderRepaintBoundary boundary =
          _previewKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      final option = resizeOptions[selectedOption];
      final double targetWidth = (option['width'] ?? 2048).toDouble();

      final RenderBox renderBox =
          _previewKey.currentContext!.findRenderObject() as RenderBox;
      final Size widgetSize = renderBox.size;

      final double pixelRatio = (targetWidth / widgetSize.width).clamp(1.0, 5.0);

      ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);

      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final Directory tempDir = Directory.systemTemp;
      final String tempPath =
          '${tempDir.path}/frame_crop_${DateTime.now().millisecondsSinceEpoch}.png';
      File resizedFile = File(tempPath)..writeAsBytesSync(pngBytes);
      return resizedFile;
    } catch (e) {
      print("Render error: $e");
      throw Exception('Failed to capture image: $e');
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
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image saved successfully!')),
        );
      } else {
        throw Exception('Failed to save image to gallery.');
      }
    } catch (e) {
      print("Save error: $e");
      throw Exception('Failed to save image: $e');
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
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
        leading: const BackButton(color: Colors.white),
        elevation: 0,
        title: const Text(
          'Resize Image',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          if (isSaving)
            const Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            )
          else
            IconButton(
              icon: const Icon(FontAwesomeIcons.check, color: Colors.greenAccent),
              onPressed: isSaving ? null : () async {
                setState(() {
                  isSaving = true;
                  showBorder = false;
                });
                
                try {
                  await Future.delayed(const Duration(milliseconds: 50));
                  
                  File finalFile = imageToShow;
                  if (option['width'] != null && option['height'] != null) {
                    finalFile = await captureRenderedImage();
                  }
                  
                  await _saveImageToGallery(finalFile);
                  
                  if (mounted) Navigator.pop(context, finalFile);

                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() {
                      isSaving = false;
                      showBorder = true;
                    });
                  }
                }
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
                        color: _backgroundColor,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18)),
                        clipBehavior: Clip.antiAlias,
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
                              color: Colors.blueAccent,
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
          _buildResizeOptions(),
          _buildColorOptions(),
        ],
      ),
    );
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.grey[900],
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _backgroundColor,
            onColorChanged: (color) => setState(() => _backgroundColor = color),
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Done', style: TextStyle(color: Colors.white)),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildColorOptions() {
    return Container(
      height: 60,
      color: Colors.grey[900],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ..._predefinedColors.map((color) => GestureDetector(
                onTap: () => setState(() => _backgroundColor = color),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _backgroundColor == color
                          ? Colors.white
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
              )),
          IconButton(
            icon: const Icon(Icons.color_lens, color: Colors.white),
            onPressed: _showColorPicker,
          ),
        ],
      ),
    );
  }

  Widget _buildResizeOptions() {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
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
                color: isSelected ? Colors.white24 : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white24 : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: resizeOptions[index]['aspect'] == null
                        ? const Icon(Icons.crop, color: Colors.white)
                        : CustomPaint(
                            painter: _AspectRatioPainter(
                              aspectRatio: resizeOptions[index]['aspect'],
                              color: isSelected ? Colors.white : Colors.grey,
                            ),
                          ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    resizeOptions[index]['label'],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey,
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