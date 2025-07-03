import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';

class CompressScreen extends StatefulWidget {
  final File? initialImageFile;
  const CompressScreen({Key? key, this.initialImageFile}) : super(key: key);

  @override
  State<CompressScreen> createState() => _CompressScreenState();
}

class _CompressScreenState extends State<CompressScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.initialImageFile != null) {
      _imageFile = widget.initialImageFile;
      widget.initialImageFile!.readAsBytes().then((bytes) {
        setState(() {
          _originalSize = bytes.lengthInBytes;
        });
      });
    } else {
      // If no image provided, open gallery immediately
      Future.delayed(Duration.zero, _pickImage);
    }
  }

  bool _showBorder = true;
  File? _imageFile;
  Uint8List? _compressedBytes;
  int? _originalSize;
  int? _compressedSize;
  bool _isCompressing = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final bytes = await file.readAsBytes();
      setState(() {
        _imageFile = file;
        _originalSize = bytes.lengthInBytes;
        _compressedBytes = null;
        _compressedSize = null;
      });
    }
  }

  Future<void> _compressImage() async {
    if (_imageFile == null) return;
    setState(() => _isCompressing = true);
    try {
      final result = await FlutterImageCompress.compressWithFile(
        _imageFile!.absolute.path,
        quality: 60,
        format: CompressFormat.jpeg,
      );
      if (result == null) throw Exception('Compression failed');
      setState(() {
        _compressedBytes = result;
        _compressedSize = result.length;
        _isCompressing = false;
      });
    } catch (e) {
      setState(() => _isCompressing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Compression failed: $e')),
      );
    }
  }

  Future<void> _resizeImage() async {
    if (_imageFile == null) return;
    setState(() => _isCompressing = true);
    final bytes = await _imageFile!.readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) {
      setState(() => _isCompressing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to decode image.')),
      );
      return;
    }
    final resized = img.copyResize(image, width: (image.width * 0.5).round());
    final resizedBytes = img.encodeJpg(resized, quality: 90);
    setState(() {
      _compressedBytes = Uint8List.fromList(resizedBytes);
      _compressedSize = resizedBytes.length;
      _isCompressing = false;
    });
  }

  Future<void> _saveCompressedToGallery() async {
    if (_compressedBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please compress the image before saving.')),
      );
      return;
    }
    FocusScope.of(context).unfocus(); // Dismiss keyboard if open

    // Request correct permissions for Android/iOS
    PermissionStatus status = await Permission.photos.request();
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }
    if (!status.isGranted) {
      setState(() => _showBorder = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Gallery/storage permission not granted. Please enable it in app settings.')),
      );
      return;
    }
    try {
      final result = await ImageGallerySaver.saveImage(_compressedBytes!,
          name: 'compressed_${DateTime.now().millisecondsSinceEpoch}');
      setState(() => _showBorder = true);
      if (result['isSuccess'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image saved to gallery')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save image.')),
        );
      }
    } catch (e) {
      setState(() => _showBorder = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving image: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: BackButton(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(FontAwesomeIcons.check, color: Colors.greenAccent),
            onPressed:
                _compressedBytes == null ? null : _saveCompressedToGallery,
            tooltip: _compressedBytes == null ? 'Compress image first' : 'Save',
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          if (_imageFile != null)
            Expanded(
              child: Center(
                child: _compressedBytes != null || _imageFile != null
                    ? Container(
                        decoration: _showBorder
                            ? BoxDecoration(
                                border: Border.all(
                                    color: Colors.blueAccent, width: 2.5),
                                borderRadius: BorderRadius.circular(10),
                              )
                            : null,
                        clipBehavior: Clip.hardEdge,
                        child: InteractiveViewer(
                          minScale: 1,
                          maxScale: 4,
                          child: Builder(
                            builder: (_) {
                              try {
                                if (_compressedBytes != null) {
                                  return Image.memory(
                                    _compressedBytes!,
                                    key: const ValueKey('compressedImage'),
                                    fit: BoxFit.contain,
                                  );
                                } else {
                                  return Image.file(_imageFile!,
                                      fit: BoxFit.contain);
                                }
                              } catch (e) {
                                return const Center(
                                  child: Text(
                                    'Error displaying image',
                                    style: TextStyle(color: Colors.redAccent),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            )
          else
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: Colors.blueAccent),
              ),
            ),
          if (_originalSize != null || _compressedSize != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: [
                  if (_originalSize != null)
                    Text(
                      'Original Size: ${(_originalSize! / 1024).toStringAsFixed(2)} KB',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  if (_compressedSize != null)
                    Text(
                      'Compressed Size: ${(_compressedSize! / 1024).toStringAsFixed(2)} KB',
                      style: const TextStyle(
                          color: Colors.greenAccent, fontSize: 14),
                    ),
                ],
              ),
            ),
          Container(
            height: 90,
            color: Colors.grey[900],
            child: Center(
              child: ElevatedButton.icon(
                onPressed: _isCompressing || _imageFile == null
                    ? null
                    : _compressImage,
                icon:
                    const Icon(FontAwesomeIcons.compress, color: Colors.white),
                label: _isCompressing
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Compress',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(180, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 6,
                  shadowColor: Colors.greenAccent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
