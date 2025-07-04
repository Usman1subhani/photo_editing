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

  // Modal loader dialog
  Future<void> _showSavingDialog([String message = "Saving..."]) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 24),
              Text(message, style: const TextStyle(color: Colors.white, fontSize: 18)),
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
    final ratio = ratioOptions[selectedRatioIndex]['aspect'];
    final layouts = _getAvailableLayouts();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: const BackButton(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library, color: Colors.white),
            onPressed: _pickImages,
          ),
          IconButton(
            icon: const Icon(Icons.check, color: Colors.greenAccent),
            onPressed: _saveCollage,
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          _buildRatioSelector(),
          const SizedBox(height: 8),
          if (selectedImages.isNotEmpty)
            Expanded(
              child: AspectRatio(
                aspectRatio: ratio,
                child: RepaintBoundary(
                  key: _collageKey,
                  child: Container(
                    decoration: showBorder
                        ? BoxDecoration(
                            border: Border.all(color: Colors.blueAccent, width: 2.5),
                            borderRadius: BorderRadius.circular(12),
                          )
                        : null,
                    child: layouts.isNotEmpty
                        ? layouts[selectedLayoutIndex]
                        : const SizedBox.shrink(),
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
    );
  }

  Widget _buildRatioSelector() {
    return Container(
      height: 50,
      color: Colors.grey[900],
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: ratioOptions.length,
        itemBuilder: (context, index) {
          final isSelected = selectedRatioIndex == index;
          return GestureDetector(
            onTap: () => setState(() => selectedRatioIndex = index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white24 : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  ratioOptions[index]['label'],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey,
                    fontSize: 14,
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
    return Container(
      height: 90,
      color: Colors.grey[900],
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: layoutCount,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => setState(() => selectedLayoutIndex = index),
            child: Container(
              width: 80,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: selectedLayoutIndex == index
                    ? Colors.white24
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.grid_on,
                      color: selectedLayoutIndex == index
                          ? Colors.white
                          : Colors.grey),
                  const SizedBox(height: 6),
                  Text(
                    'Layout ${index + 1}',
                    style: TextStyle(
                      color: selectedLayoutIndex == index
                          ? Colors.white
                          : Colors.grey,
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

  Widget _buildMarginSlider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Margin", style: TextStyle(color: Colors.white)),
          Slider(
            value: marginValue,
            min: 0,
            max: 20,
            divisions: 20,
            label: marginValue.toStringAsFixed(1),
            onChanged: (value) => setState(() => marginValue = value),
          ),
        ],
      ),
    );
  }

  Widget _buildBorderSlider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Border Width", style: TextStyle(color: Colors.white)),
          Slider(
            value: borderWidth,
            min: 0,
            max: 10,
            divisions: 20,
            label: borderWidth.toStringAsFixed(1),
            onChanged: (value) => setState(() => borderWidth = value),
          ),
        ],
      ),
    );
  }

  Widget _buildBorderColorPicker() {
    final colors = [
      Colors.white,
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Border Color", style: TextStyle(color: Colors.white)),
          const SizedBox(height: 8),
          Row(
            children: colors.map((color) {
              return GestureDetector(
                onTap: () => setState(() => borderColor = color),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color,
                    border: Border.all(
                        color: Colors.white,
                        width: borderColor == color ? 2 : 0),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}