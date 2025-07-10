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

// Custom painter for aspect ratio preview
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

    double width, height;
    if (aspectRatio >= 1.0) {
      width = size.width * 0.8;
      height = width / aspectRatio;
      if (height > size.height * 0.8) {
        height = size.height * 0.8;
        width = height * aspectRatio;
      }
    } else {
      height = size.height * 0.8;
      width = height * aspectRatio;
      if (width > size.width * 0.8) {
        width = size.width * 0.8;
        height = width / aspectRatio;
      }
    }

    final dx = (size.width - width) / 2;
    final dy = (size.height - height) / 2;

    final rect = Rect.fromLTWH(dx, dy, width, height);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _AspectRatioPainter oldDelegate) {
    return oldDelegate.aspectRatio != aspectRatio || oldDelegate.color != color;
  }
}

// Custom painter for layout preview
class _LayoutPreviewPainter extends CustomPainter {
  final List<List<double>> layout;
  final Color color;
  _LayoutPreviewPainter({required this.layout, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    for (final coords in layout) {
      final left = coords[0] * size.width;
      final top = coords[1] * size.height;
      final right = coords[2] * size.width;
      final bottom = coords[3] * size.height;
      final rect = Rect.fromLTRB(left, top, right, bottom);
      canvas.drawRect(rect, paint);
    }
  }
  @override
  bool shouldRepaint(_LayoutPreviewPainter oldDelegate) {
    return oldDelegate.layout != layout || oldDelegate.color != color;
  }
}


class _CollageScreenState extends State<CollageScreen> {
  bool _isSavingImage = false;

  // --- Resize helpers (must be above _buildPhotoFrame for Dart) ---
  List<Widget> _buildResizeHandles(int index, List<double> coords, double screenWidth, double screenHeight, double frameWidth, double frameHeight) {
    // Hide resize handles when saving
    if (_isSavingImage == true) return [];
    final handles = <Widget>[];
    // Smaller handle size
    const double handleSize = 20;
    final directions = [
      {'dx': -handleSize / 9, 'dy': frameHeight / 2 - handleSize / 5, 'icon': Icons.arrow_left, 'dir': 0},
      {'dx': frameWidth / 2 - handleSize / 5, 'dy': -handleSize / 15, 'icon': Icons.arrow_drop_up, 'dir': 1},
      {'dx': frameWidth - handleSize / 0.8, 'dy': frameHeight / 2 - handleSize / 5, 'icon': Icons.arrow_right, 'dir': 2},
      {'dx': frameWidth / 2 - handleSize / 5, 'dy': frameHeight - handleSize / 0.8, 'icon': Icons.arrow_drop_down, 'dir': 3},
    ];
    for (final d in directions) {
      handles.add(Positioned(
        left: d['dx'] as double,
        top: d['dy'] as double,
        child: GestureDetector(
          onPanStart: (details) {
            _resizeDirection = d['dir'] as int;
            _dragStart = details.globalPosition;
            final layouts = layoutOptionsByCount[selectedImages.length] ?? [];
            if (selectedLayoutIndex < layouts.length) {
              _customLayout = List<List<double>>.from(
                ( _customLayout ?? layouts[selectedLayoutIndex] ).map((e) => List<double>.from(e))
              );
            }
          },
          onPanUpdate: (details) {
            if (_resizeDirection == null || _customLayout == null) return;
            // Reduce sensitivity by multiplying delta by 0.08 (slower, more precise)
            final delta = (details.globalPosition - (_dragStart ?? Offset.zero)) * 0.08;
            setState(() {
              _resizeFrame(index, _resizeDirection!, delta, screenWidth, screenHeight);
            });
          },
          onPanEnd: (_) {
            _resizeDirection = null;
            _dragStart = null;
          },
          child: Container(
            width: handleSize,
            height: handleSize,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.7),
              shape: BoxShape.rectangle,
              border: Border.all(color: Colors.white, width: 1),
            ),
            child: Icon(d['icon'] as IconData, color: Colors.white, size: 14),
          ),
        ),
      ));
    }
    return handles;
  }

  void _resizeFrame(int index, int direction, Offset delta, double screenWidth, double screenHeight) {
    if (_customLayout == null) return;
    final layout = _customLayout!;
    final coords = layout[index];
    double dx = delta.dx / screenWidth;
    double dy = delta.dy / (screenHeight * (1 / frameRatio));
    switch (direction) {
      case 0: // left
        double newLeft = (coords[0] + dx).clamp(0.0, coords[2] - _minFrameSize);
        for (int i = 0; i < layout.length; i++) {
          if (i != index && (layout[i][2] - coords[0]).abs() < 0.01 && _isVerticallyOverlapping(layout[i], coords)) {
            layout[i][2] = newLeft;
          }
        }
        coords[0] = newLeft;
        break;
      case 1: // top
        double newTop = (coords[1] + dy).clamp(0.0, coords[3] - _minFrameSize);
        for (int i = 0; i < layout.length; i++) {
          if (i != index && (layout[i][3] - coords[1]).abs() < 0.01 && _isHorizontallyOverlapping(layout[i], coords)) {
            layout[i][3] = newTop;
          }
        }
        coords[1] = newTop;
        break;
      case 2: // right
        double newRight = (coords[2] + dx).clamp(coords[0] + _minFrameSize, 1.0);
        for (int i = 0; i < layout.length; i++) {
          if (i != index && (layout[i][0] - coords[2]).abs() < 0.01 && _isVerticallyOverlapping(layout[i], coords)) {
            layout[i][0] = newRight;
          }
        }
        coords[2] = newRight;
        break;
      case 3: // bottom
        double newBottom = (coords[3] + dy).clamp(coords[1] + _minFrameSize, 1.0);
        for (int i = 0; i < layout.length; i++) {
          if (i != index && (layout[i][1] - coords[3]).abs() < 0.01 && _isHorizontallyOverlapping(layout[i], coords)) {
            layout[i][1] = newBottom;
          }
        }
        coords[3] = newBottom;
        break;
    }
  }

  bool _isVerticallyOverlapping(List<double> a, List<double> b) {
    return (a[1] < b[3]) && (a[3] > b[1]);
  }
  bool _isHorizontallyOverlapping(List<double> a, List<double> b) {
    return (a[0] < b[2]) && (a[2] > b[0]);
  }
  // For interactive resizing
  List<List<double>>? _customLayout; // If user resizes, this overrides the default layout
  int? _resizeDirection; // 0=left, 1=top, 2=right, 3=bottom
  Offset? _dragStart;
  double _minFrameSize = 0.15; // Minimum width/height as fraction
  // Undo/redo stacks
  final List<List<File>> _undoStack = [];
  final List<List<File>> _redoStack = [];

  void _pushUndo() {
    _undoStack.add(List<File>.from(selectedImages));
    _redoStack.clear();
  }
  int selectedLayoutIndex = 0;
  int? selectedIndex;
  Color backgroundColor = Colors.black;
  double spacing = 4.0;
  double cornerRadius = 0.0;
  double frameRatio = 1.0;
  final List<Color> _predefinedColors = [
    Colors.black, Colors.white, Colors.red, Colors.green, Colors.blue, Colors.yellow, Colors.purple, Colors.orange,
  ];
  final List<File> selectedImages = [];
  final picker = ImagePicker();
  final GlobalKey _collageKey = GlobalKey();
  bool _isSaving = false;
  int _selectedTab = 0;
  final List<Offset> _imageTranslations = [];
  final List<double> _imageScales = [];
  final List<Offset> _lastFocalPoints = [];
  // Layouts grouped by photo count for easier filtering and extension
  final Map<int, List<List<List<double>>>> layoutOptionsByCount = {
    2: [
      // Side by side
      [
        [0.0, 0.0, 0.5, 1.0],
        [0.5, 0.0, 1.0, 1.0],
      ],
      // Top and bottom
      [
        [0.0, 0.0, 1.0, 0.5],
        [0.0, 0.5, 1.0, 1.0],
      ],
      // Diagonal split
      [
        [0.0, 0.0, 1.0, 0.6],
        [0.0, 0.4, 1.0, 1.0],
      ],
      // Heart shape (approximate, for 2 images)
      [
        [0.05, 0.15, 0.48, 0.85],
        [0.52, 0.15, 0.95, 0.85],
      ],
      // Fancy: one big, one small corner
      [
        [0.0, 0.0, 0.8, 1.0],
        [0.8, 0.7, 1.0, 1.0],
      ],
    ],
    3: [
      // Classic 3-grid
      [
        [0.0, 0.0, 0.5, 0.5],
        [0.5, 0.0, 1.0, 0.5],
        [0.0, 0.5, 1.0, 1.0],
      ],
      // 3 vertical strips
      [
        [0.0, 0.0, 0.33, 1.0],
        [0.33, 0.0, 0.66, 1.0],
        [0.66, 0.0, 1.0, 1.0],
      ],
      // Triangle/heart (approximate)
      [
        [0.15, 0.15, 0.85, 0.5],
        [0.05, 0.5, 0.45, 0.95],
        [0.55, 0.5, 0.95, 0.95],
      ],
      // Fancy: one big, two small
      [
        [0.0, 0.0, 0.7, 1.0],
        [0.7, 0.0, 1.0, 0.5],
        [0.7, 0.5, 1.0, 1.0],
      ],
    ],
    4: [
      // Classic 2x2 grid
      [
        [0.0, 0.0, 0.5, 0.5],
        [0.5, 0.0, 1.0, 0.5],
        [0.0, 0.5, 0.5, 1.0],
        [0.5, 0.5, 1.0, 1.0],
      ],
      // Spiral
      [
        [0.0, 0.0, 0.7, 0.7],
        [0.7, 0.0, 1.0, 0.3],
        [0.7, 0.3, 1.0, 0.7],
        [0.0, 0.7, 1.0, 1.0],
      ],
      // Heart/flower (approximate)
      [
        [0.25, 0.05, 0.75, 0.45],
        [0.05, 0.25, 0.45, 0.75],
        [0.55, 0.25, 0.95, 0.75],
        [0.25, 0.55, 0.75, 0.95],
      ],
      // Fancy: one big, three small
      [
        [0.0, 0.0, 0.7, 1.0],
        [0.7, 0.0, 1.0, 0.3],
        [0.7, 0.3, 1.0, 0.7],
        [0.7, 0.7, 1.0, 1.0],
      ],
    ],
    // Add more for 5, 6, etc. as needed
  };

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
        selectedLayoutIndex = 0;
        _customLayout = null;
      });
    }
  }

  Future<void> _saveCollage() async {
    setState(() {
      selectedIndex = null; // Remove blue border before saving
      _isSaving = true;
      _isSavingImage = true;
    });

    // Wait for the UI to update and hide overlays
    await Future.delayed(const Duration(milliseconds: 50));

    try {
      PermissionStatus status = await Permission.photos.request();
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }
      if (!status.isGranted) {
        setState(() {
          _isSaving = false;
          _isSavingImage = false;
        });
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

      setState(() {
        _isSaving = false;
        _isSavingImage = false;
      });

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
      setState(() {
        _isSaving = false;
        _isSavingImage = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Widget _buildPhotoFrame(int index) {
    final layouts = layoutOptionsByCount[selectedImages.length] ?? [];
    if (selectedLayoutIndex >= layouts.length) return const SizedBox.shrink();
    // Use custom layout if resizing, else default
    final layout = _customLayout ?? layouts[selectedLayoutIndex];
    if (index >= layout.length) return const SizedBox.shrink();
    final coords = layout[index];
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final frameWidth = (coords[2] - coords[0]) * screenWidth;
    final frameHeight = (coords[3] - coords[1]) * screenHeight * (1 / frameRatio);

    return Positioned(
      left: coords[0] * screenWidth,
      top: coords[1] * screenHeight * (1 / frameRatio),
      width: frameWidth,
      height: frameHeight,
      child: Stack(
        children: [
          LongPressDraggable<int>(
            data: index,
            feedback: Opacity(
              opacity: 0.7,
              child: SizedBox(
                width: frameWidth,
                height: frameHeight,
                child: selectedImages.length > index
                    ? Image.file(selectedImages[index], fit: BoxFit.cover)
                    : const SizedBox.shrink(),
              ),
            ),
            childWhenDragging: Opacity(
              opacity: 0.3,
              child: _buildPhotoFrameContent(index, frameWidth, frameHeight),
            ),
            onDragStarted: _pushUndo,
            child: DragTarget<int>(
              onAccept: (fromIndex) {
                setState(() {
                  final temp = selectedImages[fromIndex];
                  selectedImages[fromIndex] = selectedImages[index];
                  selectedImages[index] = temp;
                  _resetTransforms();
                });
              },
              builder: (context, candidateData, rejectedData) {
                return GestureDetector(
                  onTap: () => setState(
                      () => selectedIndex = selectedIndex == index ? null : index),
                  child: _buildPhotoFrameContent(index, frameWidth, frameHeight),
                );
              },
            ),
          ),
          if (!_isSavingImage && selectedIndex == index) ..._buildResizeHandles(index, coords, screenWidth, screenHeight, frameWidth, frameHeight),
        ],
      ),
    );
  }

  Widget _buildPhotoFrameContent(int index, double frameWidth, double frameHeight) {
    final isSelected = selectedIndex == index;
    return Stack(
      children: [
        Container(
          margin: EdgeInsets.all(spacing),
          decoration: BoxDecoration(
            border: (!_isSavingImage && isSelected) ? Border.all(color: Colors.blue, width: 2.0) : null,
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
                if (isSelected) {
                  setState(() {
                    _lastFocalPoints[index] = details.localFocalPoint;
                  });
                }
              },
              onScaleUpdate: (details) {
                if (isSelected) {
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
              // Remove double-tap reset
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
        // Resize handles are handled in _buildPhotoFrame, not here
      ],
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
            const Text('Select photos to create collage', style: TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.photo_library),
              label: const Text('Add Photos'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              onPressed: _pickImages,
            ),
          ],
        ),
      );
    }
    return AspectRatio(
      aspectRatio: frameRatio,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(18),
          border: _isSavingImage ? null : Border.all(color: Colors.white24, width: 2),
        ),
        child: Stack(
          children: [
            ...List.generate(selectedImages.length, (index) => _buildPhotoFrame(index)),
            // Remove button for each image (hide when saving)
            if (!_isSavingImage)
              ...List.generate(selectedImages.length, (index) => Positioned(
                right: 8,
                top: 8 + index * 40.0,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedImages.removeAt(index);
                      _resetTransforms();
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ),
              )),
          ],
        ),
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
        leading: const BackButton(color: Colors.white),
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
              icon: const Icon(Icons.check, color: Colors.greenAccent),
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
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
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
              width: 80,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white24 : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: isSelected ? Border.all(color: Colors.blueAccent, width: 2) : null,
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
                    child: ratio['value'] == null
                        ? const Icon(Icons.crop, color: Colors.white)
                        : CustomPaint(
                            painter: _AspectRatioPainter(
                              aspectRatio: ratio['value'],
                              color: isSelected ? Colors.white : Colors.grey,
                            ),
                          ),
                  ),
                  const SizedBox(height: 2),
                  Flexible(
                    child: Text(
                      ratio['name'],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey,
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
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

  Widget _buildLayoutOptions() {
    final imageCount = selectedImages.length;
    if (imageCount == 0) {
      return const Text('Please select images first', style: TextStyle(color: Colors.white54));
    }
    final layouts = layoutOptionsByCount[imageCount] ?? [];
    if (layouts.isEmpty) {
      return const Text('No layouts available for this photo count', style: TextStyle(color: Colors.white54));
    }
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: layouts.length,
        itemBuilder: (context, index) {
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
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white24 : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: isSelected ? Border.all(color: Colors.blueAccent, width: 2) : null,
              ),
              child: Center(
                child: CustomPaint(
                  size: const Size(50, 50),
                  painter: _LayoutPreviewPainter(
                    layout: layouts[index],
                    color: isSelected ? Colors.white : Colors.grey,
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
