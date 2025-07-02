import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_image_compress/flutter_image_compress.dart';

class CompressScreen extends StatefulWidget {
  const CompressScreen({Key? key}) : super(key: key);

  @override
  State<CompressScreen> createState() => _CompressScreenState();
}

class _CompressScreenState extends State<CompressScreen> {
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
    // Resize to 50% of original dimensions
    final resized = img.copyResize(image, width: (image.width * 0.5).round());
    final resizedBytes = img.encodeJpg(resized, quality: 90);
    setState(() {
      _compressedBytes = Uint8List.fromList(resizedBytes);
      _compressedSize = resizedBytes.length;
      _isCompressing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compress Image'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo_library),
                label: const Text('Select Image'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              if (_imageFile != null)
                Column(
                  children: [
                    if (_originalSize != null)
                      Text(
                        'Original Size: ${(_originalSize! / 1024).toStringAsFixed(2)} KB',
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    const SizedBox(height: 10),
                    Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blueAccent, width: 2),
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.memory(
                          _compressedBytes ?? _imageFile!.readAsBytesSync(),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_compressedSize != null)
                      Text(
                        'Compressed Size: ${(_compressedSize! / 1024).toStringAsFixed(2)} KB',
                        style: const TextStyle(color: Colors.greenAccent, fontSize: 16),
                      ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: _isCompressing ? null : _compressImage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: _isCompressing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Compress'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _isCompressing ? null : _resizeImage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                          child: _isCompressing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Resize 50%'),
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
