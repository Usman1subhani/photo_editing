import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class CollageScreen extends StatefulWidget {
  const CollageScreen({super.key});

  @override
  State<CollageScreen> createState() => _CollageScreenState();
}

class _CollageScreenState extends State<CollageScreen> {
  int selectedLayoutIndex = 0;
  int? selectedIndex; // Track selected photo index (not saved)
  Color backgroundColor = Colors.black;
  double spacing = 4.0;
  double cornerRadius = 0.0;
  double frameRatio = 1.0; // Default 1:1

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

  final List<File> selectedImages = [];
  final picker = ImagePicker();
  final GlobalKey _collageKey = GlobalKey();
  bool _isSaving = false;
  int _selectedTab = 0; // 0: Ratio, 1: Layout, 2: Margin, 3: Border

  // Track transformations for each image
  final List<Offset> _imageTranslations = [];
  final List<double> _imageScales = [];
  final List<Offset> _lastFocalPoints = [];

  // Layout options (normalized coordinates)
  final List<List<List<double>>> layoutOptions = [
    // 2 photos layouts
    [
      [0.0, 0.0, 0.5, 1.0], // Side by side
      [0.5, 0.0, 1.0, 1.0]
    ],
    [
      [0.0, 0.0, 1.0, 0.5], // Top and bottom
      [0.0, 0.5, 1.0, 1.0]
    ],
    [
      [0.0, 0.0, 0.6, 1.0], // Big left, small right
      [0.6, 0.0, 1.0, 0.5],
      [0.6, 0.5, 1.0, 1.0]
    ],
    [
      [0.0, 0.0, 0.7, 1.0], // Big left with small right strip
      [0.7, 0.0, 1.0, 1.0]
    ],
    [
      [0.0, 0.0, 1.0, 0.7], // Big top with small bottom strip
      [0.0, 0.7, 1.0, 1.0]
    ],

    // 3 photos layouts
    [
      [0.0, 0.0, 0.5, 0.5], // Classic 3-grid
      [0.5, 0.0, 1.0, 0.5],
      [0.0, 0.5, 1.0, 1.0]
    ],
    [
      [0.0, 0.0, 0.33, 1.0], // 3 vertical strips
      [0.33, 0.0, 0.66, 1.0],
      [0.66, 0.0, 1.0, 1.0]
    ],
    [
      [0.0, 0.0, 0.4, 0.4], // Diagonal emphasis
      [0.4, 0.4, 0.8, 0.8],
      [0.8, 0.8, 1.0, 1.0]
    ],
    [
      [0.0, 0.0, 0.6, 0.6], // Big top-left with two small
      [0.6, 0.0, 1.0, 0.3],
      [0.6, 0.3, 1.0, 0.6],
      [0.0, 0.6, 1.0, 1.0]
    ],
    [
      [0.0, 0.0, 0.5, 0.33], // Top row + big bottom
      [0.5, 0.0, 1.0, 0.33],
      [0.0, 0.33, 1.0, 1.0]
    ],

    // 4 photos layouts
    [
      [0.0, 0.0, 0.5, 0.5], // Classic 2x2 grid
      [0.5, 0.0, 1.0, 0.5],
      [0.0, 0.5, 0.5, 1.0],
      [0.5, 0.5, 1.0, 1.0]
    ],
    [
      [0.0, 0.0, 0.33, 0.33], // 4 small + center space
      [0.33, 0.0, 0.66, 0.33],
      [0.66, 0.0, 1.0, 0.33],
      [0.0, 0.33, 1.0, 1.0]
    ],
    [
      [0.0, 0.0, 0.4, 0.4], // Spiral layout
      [0.4, 0.0, 1.0, 0.4],
      [0.4, 0.4, 1.0, 1.0],
      [0.0, 0.4, 0.4, 1.0]
    ],
    [
      [0.0, 0.0, 0.6, 0.6], // Big center with surrounding
      [0.6, 0.0, 1.0, 0.3],
      [0.6, 0.6, 1.0, 1.0],
      [0.0, 0.6, 0.3, 1.0]
    ],
    [
      [0.0, 0.0, 0.25, 1.0], // 4 vertical strips
      [0.25, 0.0, 0.5, 1.0],
      [0.5, 0.0, 0.75, 1.0],
      [0.75, 0.0, 1.0, 1.0]
    ],

    // 5 photos layouts
    [
      [0.0, 0.0, 0.4, 0.4], // Top-left cluster + right column
      [0.4, 0.0, 0.8, 0.4],
      [0.0, 0.4, 0.4, 0.8],
      [0.4, 0.4, 0.8, 0.8],
      [0.8, 0.0, 1.0, 1.0]
    ],
    [
      [0.0, 0.0, 0.5, 0.33], // 3 top + 2 bottom
      [0.5, 0.0, 1.0, 0.33],
      [0.0, 0.33, 0.33, 0.66],
      [0.33, 0.33, 0.66, 0.66],
      [0.66, 0.33, 1.0, 0.66],
      [0.0, 0.66, 1.0, 1.0]
    ],
    [
      [0.0, 0.0, 0.33, 0.33], // Grid with one big
      [0.33, 0.0, 0.66, 0.33],
      [0.66, 0.0, 1.0, 0.33],
      [0.0, 0.33, 0.5, 1.0],
      [0.5, 0.33, 1.0, 1.0]
    ],

    // 6 photos layouts
    [
      [0.0, 0.0, 0.33, 0.5], // 3x2 grid
      [0.33, 0.0, 0.66, 0.5],
      [0.66, 0.0, 1.0, 0.5],
      [0.0, 0.5, 0.33, 1.0],
      [0.33, 0.5, 0.66, 1.0],
      [0.66, 0.5, 1.0, 1.0]
    ],
    [
      [0.0, 0.0, 0.25, 0.33], // 4 top + 2 bottom
      [0.25, 0.0, 0.5, 0.33],
      [0.5, 0.0, 0.75, 0.33],
      [0.75, 0.0, 1.0, 0.33],
      [0.0, 0.33, 0.5, 1.0],
      [0.5, 0.33, 1.0, 1.0]
    ],
    [
      [0.0, 0.0, 0.4, 0.4], // Hexagonal layout
      [0.4, 0.0, 0.8, 0.4],
      [0.0, 0.4, 0.4, 0.8],
      [0.4, 0.4, 0.8, 0.8],
      [0.2, 0.2, 0.6, 0.6],
      [0.6, 0.6, 1.0, 1.0]
    ],
  ];

  // Expanded frame ratio options (including those from resizeScreen.dart assumption)
  final List<Map<String, dynamic>> frameRatios = [
    {'name': '1:1', 'value': 1.0},
    {'name': '4:3', 'value': 4 / 3},
    {'name': '16:9', 'value': 16 / 9},
    {'name': '3:2', 'value': 3 / 2},
    {'name': '5:4', 'value': 5 / 4},
    {'name': '7:5', 'value': 7 / 5},
    {'name': '21:9', 'value': 21 / 9},
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
        selectedIndex = null; // Reset selection
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
    setState(() {
      selectedIndex = null; // Remove blue border before saving
      _isSaving = true;
    });

    try {
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final frameWidth = (coords[2] - coords[0]) * screenWidth;
    final frameHeight =
        (coords[3] - coords[1]) * screenHeight * (1 / frameRatio);

    return Positioned(
      left: coords[0] * screenWidth,
      top: coords[1] * screenHeight * (1 / frameRatio),
      width: frameWidth,
      height: frameHeight,
      child: GestureDetector(
        onTap: () => setState(
            () => selectedIndex = selectedIndex == index ? null : index),
        child: Container(
          margin: EdgeInsets.all(spacing),
          decoration: BoxDecoration(
            border: selectedIndex == index
                ? Border.all(color: Colors.blue, width: 2.0)
                : null,
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
                if (selectedIndex == index) {
                  setState(() {
                    _lastFocalPoints[index] = details.localFocalPoint;
                  });
                }
              },
              onScaleUpdate: (details) {
                if (selectedIndex == index) {
                  setState(() {
                    final zoomDelta = (details.scale - 1) * 0.1;
                    _imageScales[index] =
                        (_imageScales[index] + zoomDelta).clamp(0.5, 4.0);
                    final delta =
                        details.localFocalPoint - _lastFocalPoints[index];
                    _imageTranslations[index] += delta / _imageScales[index];
                    _lastFocalPoints[index] = details.localFocalPoint;
                    final maxDx = frameWidth * (_imageScales[index] - 1) / 2;
                    final maxDy = frameHeight * (_imageScales[index] - 1) / 2;
                    _imageTranslations[index] = Offset(
                      _imageTranslations[index].dx.clamp(-maxDx, maxDx),
                      _imageTranslations[index].dy.clamp(-maxDy, maxDy),
                    );
                  });
                }
              },
              onDoubleTap: () {
                if (selectedIndex == index) {
                  setState(() {
                    _imageScales[index] = 1.0;
                    _imageTranslations[index] = Offset.zero;
                    _lastFocalPoints[index] = Offset.zero;
                  });
                }
              },
              child: Transform(
                transform: Matrix4.identity()
                  ..scale(_imageScales[index])
                  ..translate(_imageTranslations[index].dx,
                      _imageTranslations[index].dy),
                alignment: Alignment.center,
                child: Container(
                  color: backgroundColor,
                  child: selectedImages.length > index
                      ? Image.file(selectedImages[index],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity)
                      : const SizedBox.shrink(),
                ),
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
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      color: Colors.grey[900],
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToolbar(),
          const SizedBox(height: 16),
          _buildOptionDetails(),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildToolbarButton('Ratio', 0),
        _buildToolbarButton('Layout', 1),
        _buildToolbarButton('Margin', 2),
        _buildToolbarButton('Border', 3),
      ],
    );
  }

  Widget _buildToolbarButton(String title, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.blueAccent : Colors.white,
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 4),
          if (isSelected)
            Container(
              height: 2,
              width: 40,
              color: Colors.blueAccent,
            ),
        ],
      ),
    );
  }

  Widget _buildOptionDetails() {
    switch (_selectedTab) {
      case 0:
        return _buildRatioOptions();
      case 1:
        return _buildLayoutOptions();
      case 2:
        return _buildMarginOptions();
      case 3:
        return _buildBorderOptions();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildRatioOptions() {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: frameRatios.length,
        itemBuilder: (context, index) {
          final ratio = frameRatios[index];
          final isSelected = frameRatio == ratio['value'];
          return GestureDetector(
            onTap: () {
              setState(() {
                frameRatio = ratio['value'];
                _resetTransforms();
                selectedIndex = null;
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? Colors.blueAccent : Colors.grey[700]!,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  ratio['name'],
                  style: TextStyle(
                    color: isSelected ? Colors.blueAccent : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLayoutOptions() {
    final imageCount = selectedImages.length;
    if (imageCount == 0) {
      return const Text('Please select images first',
          style: TextStyle(color: Colors.white54));
    }

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: layoutOptions.length,
        itemBuilder: (context, index) {
          if (layoutOptions[index].length < imageCount)
            return const SizedBox.shrink();
          final isSelected = selectedLayoutIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedLayoutIndex = index;
                _resetTransforms();
                selectedIndex = null;
              });
            },
            child: Container(
              width: 80,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? Colors.blueAccent : Colors.grey[700]!,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'Layout ${index + 1}',
                  style: TextStyle(
                    color: isSelected ? Colors.blueAccent : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMarginOptions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Spacing', style: TextStyle(color: Colors.white)),
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
        const Text('Corner Radius', style: TextStyle(color: Colors.white)),
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

  Widget _buildBorderOptions() {
    return SizedBox(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ..._predefinedColors.map((color) => GestureDetector(
                onTap: () => setState(() => backgroundColor = color),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: backgroundColor == color
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

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: backgroundColor,
            onColorChanged: (color) => setState(() => backgroundColor = color),
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
}
