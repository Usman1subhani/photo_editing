import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

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
  final TransformationController _transformationController =
      TransformationController();
  final GlobalKey _previewKey = GlobalKey();
  int selectedOption = 0;
  bool isSaving = false;
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

  Future<File> captureRenderedImage() async {
    try {
      RenderRepaintBoundary boundary =
          _previewKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      final options = platformOptions[widget.platform] ?? [];
      final option = options[selectedOption];
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
    setState(() => isSaving = true);
    try {
      PermissionStatus status = await Permission.photos.request();
      if (!status.isGranted) status = await Permission.storage.request();
      if (!status.isGranted) throw Exception('Permission denied');

      final bytes = await imageFile.readAsBytes();
      final result = await ImageGallerySaver.saveImage(
        bytes,
        quality: 100, // Max quality
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
      // Re-throw to be handled by the caller's catch block
      throw Exception('Failed to save image: $e');
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = platformOptions[widget.platform] ?? [];
    final double aspect = selectedOption < options.length
        ? options[selectedOption]['aspect'] ?? 1.0
        : 1.0;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.platform, style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onSurface)),
        centerTitle: true,
        actions: [
          if (isSaving)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: CircularProgressIndicator(color: theme.colorScheme.primary),
            )
          else
            IconButton(
              icon: Icon(FontAwesomeIcons.check, color: theme.colorScheme.secondary, size: 22),
              tooltip: 'Save',
              onPressed: isSaving ? null : () async {
                setState(() {
                  isSaving = true;
                  showBorder = false;
                });
                
                try {
                  await Future.delayed(const Duration(milliseconds: 50));
                  
                  File finalFile = await captureRenderedImage();
                  
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
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
                                  widget.imageFile,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                          if (showBorder)
                            IgnorePointer(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                decoration: BoxDecoration(
                                  border: Border.all(color: theme.colorScheme.primary, width: 2.5),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildResizeOptions(theme, options),
                _buildColorOptions(theme.brightness == Brightness.dark),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _backgroundColor,
            onColorChanged: (color) => setState(() => _backgroundColor = color),
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Done'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildColorOptions(bool isDark) {
    return Container(
      height: 60,
      color: isDark ? const Color(0xFF232336) : Colors.grey[100],
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
                          ? (isDark ? Colors.white : Colors.black)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
              )),
          IconButton(
            icon:
                Icon(Icons.color_lens, color: isDark ? Colors.white : Colors.black),
            onPressed: _showColorPicker,
          ),
        ],
      ),
    );
  }

  Widget _buildResizeOptions(ThemeData theme, List<Map<String, dynamic>> options) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 80),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(color: theme.shadowColor.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, -2)),
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
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: isSelected
                    ? Border.all(color: theme.colorScheme.primary, width: 1.2)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: isSelected
                          ? [BoxShadow(color: theme.colorScheme.primary.withOpacity(0.08), blurRadius: 4)]
                          : [],
                    ),
                    child: CustomPaint(
                      painter: _AspectRatioPainter(
                        aspectRatio: option['aspect'],
                        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  SizedBox(
                    width: 48,
                    child: Text(
                      option['label'],
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 11,
                      ),
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
