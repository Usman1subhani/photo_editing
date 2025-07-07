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
  bool showBorder = true;
  int selectedRatioIndex = 0;
  int selectedLayoutIndex = 0;
  double marginValue = 4.0;
  double borderWidth = 1.0;
  Color borderColor = Colors.white;

  final List<File> selectedImages = [];
  final picker = ImagePicker();
  final GlobalKey _collageKey = GlobalKey();

  // Loader state
  bool _isSaving = false;

  // Track transformations for each image
  final Map<int, Matrix4> _imageTransforms = {};
  final Map<int, Offset> _imagePositions = {};
  final Map<int, double> _imageScales = {};

  final List<Map<String, dynamic>> ratioOptions = [
    {'label': '1:1', 'aspect': 1.0},
    {'label': '4:3', 'aspect': 4 / 3},
    {'label': '3:4', 'aspect': 3 / 4},
    {'label': '16:9', 'aspect': 16 / 9},
    {'label': '9:16', 'aspect': 9 / 16},
  ];

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

  Future<void> _pickImages() async {
    final picked = await picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() {
        selectedImages.clear();
        selectedImages.addAll(picked.map((e) => File(e.path)));
        selectedLayoutIndex = 0;
        // Reset transformations when new images are selected
        _imageTransforms.clear();
        _imagePositions.clear();
        _imageScales.clear();
      });
    }
  }

  Future<void> _saveCollage() async {
    try {
      setState(() => showBorder = false);
      await Future.delayed(const Duration(milliseconds: 50));
      setState(() => _isSaving = true);
      _showSavingDialog();
      // Request correct permissions for Android/iOS
      PermissionStatus status = await Permission.photos.request();
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }
      if (!status.isGranted) {
        setState(() {
          showBorder = true;
          _isSaving = false;
        });
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gallery/storage permission not granted. Please enable it in app settings.')),
        );
        return;
      }
      RenderRepaintBoundary boundary = _collageKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Save to gallery using image_gallery_saver
      final result = await ImageGallerySaver.saveImage(
        pngBytes,
        name: 'collage_${DateTime.now().millisecondsSinceEpoch}',
      );
      setState(() {
        showBorder = true;
        _isSaving = false;
      });
      Navigator.of(context, rootNavigator: true).pop();
      if (result['isSuccess'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Collage saved to gallery!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save collage.')),
        );
      }
    } catch (e) {
      setState(() {
        showBorder = true;
        _isSaving = false;
      });
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving collage: $e')),
      );
    }
  }

  Widget _buildImageBox(int index) {
    // Initialize transform if not exists
    _imageTransforms.putIfAbsent(index, () => Matrix4.identity());
    _imagePositions.putIfAbsent(index, () => Offset.zero);
    _imageScales.putIfAbsent(index, () => 1.0);

    return GestureDetector(
      onScaleStart: (details) {
        // Store initial values when gesture starts
        setState(() {
          _imagePositions[index] = details.localFocalPoint;
        });
      },
      onScaleUpdate: (details) {
        setState(() {
          // Calculate new scale
          _imageScales[index] = (_imageScales[index] ?? 1.0) * details.scale;
          _imageScales[index] = _imageScales[index]!.clamp(0.5, 4.0); // Limit scale range

          // Calculate new position
          final Offset delta = details.localFocalPoint - _imagePositions[index]!;
          _imagePositions[index] = details.localFocalPoint;
          
          // Update transform matrix
          _imageTransforms[index] = Matrix4.identity()
            ..translate(delta.dx, delta.dy)
            ..scale(_imageScales[index]!);
        });
      },
      onDoubleTap: () {
        // Reset on double tap
        setState(() {
          _imageTransforms[index] = Matrix4.identity();
          _imageScales[index] = 1.0;
          _imagePositions[index] = Offset.zero;
        });
      },
      child: Container(
        margin: EdgeInsets.all(marginValue),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: selectedImages.length > index
            ? Transform(
                transform: _imageTransforms[index]!,
                alignment: FractionalOffset.center,
                child: Image.file(
                  selectedImages[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  List<Widget> _getAvailableLayouts() {
    final count = selectedImages.length;
    List<Widget> layouts = [];

    if (count == 2) {
      layouts = [
        Row(children: [
          Expanded(child: _buildImageBox(0)),
          Expanded(child: _buildImageBox(1))
        ]),
        Column(children: [
          Expanded(child: _buildImageBox(0)),
          Expanded(child: _buildImageBox(1))
        ]),
        Row(
          children: [
            Expanded(child: _buildImageBox(0)),
            Expanded(
                child: Column(children: [Expanded(child: _buildImageBox(1))]))
          ],
        ),
      ];
    } else if (count == 3) {
      layouts = [
        Column(children: [
          Expanded(child: _buildImageBox(0)),
          Expanded(child: _buildImageBox(1)),
          Expanded(child: _buildImageBox(2))
        ]),
        Row(children: [
          Expanded(child: _buildImageBox(0)),
          Expanded(child: _buildImageBox(1)),
          Expanded(child: _buildImageBox(2))
        ]),
        Row(
          children: [
            Expanded(flex: 2, child: _buildImageBox(0)),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  Expanded(child: _buildImageBox(1)),
                  Expanded(child: _buildImageBox(2))
                ],
              ),
            ),
          ],
        ),
      ];
    } else if (count == 4) {
      layouts = [
        GridView.count(
          crossAxisCount: 2,
          children: List.generate(4, (i) => _buildImageBox(i)),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
        ),
        Column(
          children: [
            Expanded(
                child: Row(children: [
              Expanded(child: _buildImageBox(0)),
              Expanded(child: _buildImageBox(1))
            ])),
            Expanded(
                child: Row(children: [
              Expanded(child: _buildImageBox(2)),
              Expanded(child: _buildImageBox(3))
            ])),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Column(children: [
                Expanded(child: _buildImageBox(0)),
                Expanded(child: _buildImageBox(2))
              ]),
            ),
            Expanded(
              child: Column(children: [
                Expanded(child: _buildImageBox(1)),
                Expanded(child: _buildImageBox(3))
              ]),
            ),
          ],
        ),
      ];
    }

    return layouts;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = ratioOptions[selectedRatioIndex]['aspect'];
    final layouts = _getAvailableLayouts();

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: BackButton(color: theme.colorScheme.onSurface),
        centerTitle: true,
        title: Text(
          'Collage',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.photo_library, color: theme.colorScheme.primary),
            onPressed: _pickImages,
            tooltip: 'Pick Images',
          ),
          IconButton(
            icon: Icon(Icons.check, color: theme.colorScheme.secondary),
            onPressed: _saveCollage,
            tooltip: 'Save Collage',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            _buildRatioSelector(),
            const SizedBox(height: 8),
            if (selectedImages.isNotEmpty)
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  switchInCurve: Curves.easeInOut,
                  switchOutCurve: Curves.easeInOut,
                  child: AspectRatio(
                    key: ValueKey(selectedLayoutIndex.toString() + selectedRatioIndex.toString()),
                    aspectRatio: ratio,
                    child: RepaintBoundary(
                      key: _collageKey,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOut,
                        decoration: showBorder
                            ? BoxDecoration(
                                border: Border.all(color: theme.colorScheme.primary, width: 2.5),
                                borderRadius: BorderRadius.circular(16),
                              )
                            : null,
                        child: layouts.isNotEmpty
                            ? layouts[selectedLayoutIndex]
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            if (selectedImages.isNotEmpty) _buildLayoutSelector(layouts.length),
            const SizedBox(height: 8),
            _buildMarginSlider(),
            _buildBorderSlider(),
            _buildBorderColorPicker(),
          ],
        ),
      ),
    );
  }

  Widget _buildRatioSelector() {
    final theme = Theme.of(context);
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: ratioOptions.length,
        itemBuilder: (context, index) {
          final isSelected = selectedRatioIndex == index;
          return GestureDetector(
            onTap: () => setState(() => selectedRatioIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? theme.colorScheme.primary.withOpacity(0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: isSelected
                    ? Border.all(color: theme.colorScheme.primary, width: 1.5)
                    : null,
              ),
              child: Center(
                child: Text(
                  ratioOptions[index]['label'],
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLayoutSelector(int layoutCount) {
    final theme = Theme.of(context);
    return Container(
      height: 90,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: layoutCount,
        itemBuilder: (context, index) {
          final isSelected = selectedLayoutIndex == index;
          return GestureDetector(
            onTap: () => setState(() => selectedLayoutIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 80,
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? theme.colorScheme.primary.withOpacity(0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: isSelected
                    ? Border.all(color: theme.colorScheme.primary, width: 1.5)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    scale: isSelected ? 1.15 : 1.0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(Icons.grid_on,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Layout ${index + 1}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
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

  Widget _buildMarginSlider() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Margin", style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurface)),
          Slider(
            value: marginValue,
            min: 0,
            max: 20,
            divisions: 20,
            label: marginValue.toStringAsFixed(1),
            onChanged: (value) => setState(() => marginValue = value),
            activeColor: theme.colorScheme.primary,
            inactiveColor: theme.colorScheme.primary.withOpacity(0.2),
          ),
        ],
      ),
    );
  }

  Widget _buildBorderSlider() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Border Width", style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurface)),
          Slider(
            value: borderWidth,
            min: 0,
            max: 10,
            divisions: 20,
            label: borderWidth.toStringAsFixed(1),
            onChanged: (value) => setState(() => borderWidth = value),
            activeColor: theme.colorScheme.primary,
            inactiveColor: theme.colorScheme.primary.withOpacity(0.2),
          ),
        ],
      ),
    );
  }

  Widget _buildBorderColorPicker() {
    final theme = Theme.of(context);
    final colors = [
      Colors.white,
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Border Color", style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurface)),
          const SizedBox(height: 8),
          Row(
            children: colors.map((color) {
              final isSelected = borderColor == color;
              return GestureDetector(
                onTap: () => setState(() => borderColor = color),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    border: Border.all(
                        color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                        width: isSelected ? 3 : 1),
                    shape: BoxShape.circle,
                    boxShadow: isSelected
                        ? [BoxShadow(color: theme.colorScheme.primary.withOpacity(0.2), blurRadius: 6)]
                        : [],
                  ),
                  child: isSelected
                      ? Icon(Icons.check, color: Colors.white, size: 18)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
