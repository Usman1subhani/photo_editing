import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/rendering.dart';

class CollageScreen extends StatefulWidget {
  const CollageScreen({super.key});

  @override
  State<CollageScreen> createState() => _CollageScreenState();
}

class _CollageScreenState extends State<CollageScreen> {
  int selectedLayoutIndex = 0;
  Color backgroundColor = Colors.black;
  double spacing = 4.0;
  double cornerRadius = 0.0;
  double frameRatio = 1.0; // Default 1:1

  final List<File> selectedImages = [];
  final picker = ImagePicker();
  final GlobalKey _collageKey = GlobalKey();
  bool _isSaving = false;

  // Track transformations for each image
  final List<Offset> _imageTranslations = [];
  final List<double> _imageScales = [];
  final List<Offset> _lastFocalPoints = [];

  // Layout options
  final List<List<List<double>>> layoutOptions = [
    // 2 photos - side by side
    [
      [0.0, 0.0, 0.5, 1.0],
      [0.5, 0.0, 1.0, 1.0]
    ],
    // 2 photos - top and bottom
    [
      [0.0, 0.0, 1.0, 0.5],
      [0.0, 0.5, 1.0, 1.0]
    ],
    // 3 photos - 1 large on left, 2 small on right
    [
      [0.0, 0.0, 0.6, 1.0],
      [0.6, 0.0, 1.0, 0.5],
      [0.6, 0.5, 1.0, 1.0]
    ],
    // 4 photos - grid
    [
      [0.0, 0.0, 0.5, 0.5],
      [0.5, 0.0, 1.0, 0.5],
      [0.0, 0.5, 0.5, 1.0],
      [0.5, 0.5, 1.0, 1.0]
    ],
  ];

  // Frame ratio options
  final List<Map<String, dynamic>> frameRatios = [
    {'name': '1:1', 'value': 1.0},
    {'name': '4:3', 'value': 4 / 3},
    {'name': '16:9', 'value': 16 / 9},
  ];

  @override
  void initState() {
    super.initState();
    _resetTransforms();
  }

  void _resetTransforms() {
    _imageTranslations.clear();
    _imageScales.clear();
    _lastFocalPoints.clear();
    for (int i = 0; i < selectedImages.length; i++) {
      _imageTranslations.add(Offset.zero);
      _imageScales.add(1.0);
      _lastFocalPoints.add(Offset.zero);
    }
  }

  Future<void> _pickImages() async {
    final picked = await picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() {
        selectedImages.clear();
        selectedImages.addAll(picked.map((e) => File(e.path)));
        _resetTransforms();
        selectedLayoutIndex = 0;
        while (selectedLayoutIndex < layoutOptions.length &&
            layoutOptions[selectedLayoutIndex].length < selectedImages.length) {
          selectedLayoutIndex++;
        }
        if (selectedLayoutIndex >= layoutOptions.length) {
          selectedLayoutIndex = 0;
        }
      });
    }
  }

  Future<void> _saveCollage() async {
    try {
      setState(() => _isSaving = true);

      PermissionStatus status = await Permission.photos.request();
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }
      if (!status.isGranted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission not granted')),
        );
        return;
      }

      RenderRepaintBoundary boundary = _collageKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final result = await ImageGallerySaver.saveImage(
        pngBytes,
        name: 'collage_${DateTime.now().millisecondsSinceEpoch}',
      );

      setState(() => _isSaving = false);

      if (result['isSuccess'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Collage saved!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save collage')),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Widget _buildPhotoFrame(int index) {
    final layout = layoutOptions[selectedLayoutIndex];
    if (index >= layout.length) return const SizedBox.shrink();

    final coords = layout[index];
    final frameWidth =
        (coords[2] - coords[0]) * MediaQuery.of(context).size.width;
    final frameHeight =
        (coords[3] - coords[1]) * MediaQuery.of(context).size.width;

    return Positioned(
      left: coords[0] * MediaQuery.of(context).size.width,
      top: coords[1] * MediaQuery.of(context).size.width,
      width: frameWidth,
      height: frameHeight,
      child: Container(
        margin: EdgeInsets.all(spacing),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(cornerRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(cornerRadius),
          child: GestureDetector(
            onScaleStart: (details) {
              setState(() {
                _lastFocalPoints[index] = details.localFocalPoint;
              });
            },
            onScaleUpdate: (details) {
              setState(() {
                // Update scale
                _imageScales[index] =
                    (_imageScales[index] * details.scale).clamp(0.5, 4.0);

                // Update translation
                final delta = details.localFocalPoint - _lastFocalPoints[index];
                _imageTranslations[index] += delta / _imageScales[index];
                _lastFocalPoints[index] = details.localFocalPoint;

                // Clamp translations to keep image within frame
                final maxDx = frameWidth * (_imageScales[index] - 1) / 2;
                final maxDy = frameHeight * (_imageScales[index] - 1) / 2;
                _imageTranslations[index] = Offset(
                  _imageTranslations[index].dx.clamp(-maxDx, maxDx),
                  _imageTranslations[index].dy.clamp(-maxDy, maxDy),
                );
              });
            },
            onDoubleTap: () {
              setState(() {
                _imageScales[index] = 1.0;
                _imageTranslations[index] = Offset.zero;
                _lastFocalPoints[index] = Offset.zero;
              });
            },
            child: Transform(
              transform: Matrix4.identity()
                ..scale(_imageScales[index])
                ..translate(
                    _imageTranslations[index].dx, _imageTranslations[index].dy),
              alignment: Alignment.center,
              child: Container(
                color: backgroundColor,
                child: selectedImages.length > index
                    ? Image.file(
                        selectedImages[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollage() {
    if (selectedImages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library, size: 60, color: Colors.grey[600]),
            const SizedBox(height: 16),
            const Text(
              'Select photos to create collage',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
      );
    }

    return AspectRatio(
      aspectRatio: frameRatio,
      child: Stack(
        children: [
          Container(color: backgroundColor),
          ...List.generate(
              selectedImages.length, (index) => _buildPhotoFrame(index)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: BackButton(color: Colors.white),
        title: const Text(
          'Photo Collage',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(color: Colors.white),
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.photo_library, color: Colors.white),
              onPressed: _pickImages,
            ),
            IconButton(
              icon: const Icon(Icons.save, color: Colors.greenAccent),
              onPressed: selectedImages.isNotEmpty ? _saveCollage : null,
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RepaintBoundary(
              key: _collageKey,
              child: _buildCollage(),
            ),
          ),
          if (selectedImages.isNotEmpty) _buildControls(),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey[900],
      child: Column(
        children: [
          _buildFrameRatioSelector(),
          const SizedBox(height: 12),
          _buildLayoutSelector(),
          const SizedBox(height: 12),
          _buildSpacingSlider(),
          const SizedBox(height: 12),
          _buildCornerRadiusSlider(),
          const SizedBox(height: 12),
          _buildBackgroundColorPicker(),
          const SizedBox(height: 8),
          const Text(
            'Pinch to zoom, drag to move, double tap to reset',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildFrameRatioSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Frame Ratio',
          style: TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 8),
        Row(
          children: frameRatios.map((ratio) {
            final isSelected = frameRatio == ratio['value'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    frameRatio = ratio['value'];
                    _resetTransforms();
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blueAccent : Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    ratio['name'],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLayoutSelector() {
    final imageCount = selectedImages.length;
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: layoutOptions.length,
        itemBuilder: (context, index) {
          if (layoutOptions[index].length < imageCount) {
            return const SizedBox.shrink();
          }

          final isSelected = selectedLayoutIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedLayoutIndex = index;
                _resetTransforms();
              });
            },
            child: Container(
              width: 80,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blueAccent : Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.grid_on,
                    color: isSelected ? Colors.white : Colors.grey[400],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Layout ${index + 1}',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[400],
                      fontSize: 12,
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

  Widget _buildSpacingSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Spacing',
          style: TextStyle(color: Colors.white),
        ),
        Slider(
          value: spacing,
          min: 0,
          max: 20,
          divisions: 20,
          label: spacing.toStringAsFixed(1),
          onChanged: (value) => setState(() => spacing = value),
          activeColor: Colors.blueAccent,
          inactiveColor: Colors.blueAccent.withOpacity(0.2),
        ),
      ],
    );
  }

  Widget _buildCornerRadiusSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Corner Radius',
          style: TextStyle(color: Colors.white),
        ),
        Slider(
          value: cornerRadius,
          min: 0,
          max: 50,
          divisions: 10,
          label: cornerRadius.toStringAsFixed(0),
          onChanged: (value) => setState(() => cornerRadius = value),
          activeColor: Colors.blueAccent,
          inactiveColor: Colors.blueAccent.withOpacity(0.2),
        ),
      ],
    );
  }

  Widget _buildBackgroundColorPicker() {
    final colors = [
      Colors.black,
      Colors.white,
      Colors.grey[800]!,
      Colors.blueGrey[900]!,
      Colors.red[900]!,
      Colors.green[900]!,
      Colors.blue[900]!,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Background Color',
          style: TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ...colors.map((color) {
              final isSelected = backgroundColor == color;
              return GestureDetector(
                onTap: () => setState(() => backgroundColor = color),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 2,
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }
}
