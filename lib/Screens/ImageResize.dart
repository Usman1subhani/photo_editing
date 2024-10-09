import 'dart:io';
import 'dart:ui'; // For using BackdropFilter.
import 'package:flutter/material.dart';
// import 'package:image_gallery_saver/image_gallery_saver.dart';
// import 'package:path_provider/path_provider.dart';
import 'package:flutter/rendering.dart';
import 'dart:typed_data';

class ImageManipulation extends StatefulWidget {

  late File image;
  late double height;
  late double width;
  ImageManipulation({ super.key, required this.image, required this.height, required this.width});

  @override
  _ImageManipulationState createState() => _ImageManipulationState();
}

class _ImageManipulationState extends State<ImageManipulation> {
  GlobalKey _globalKey = GlobalKey();

  Future<void> _captureAndSaveImage() async {
    // try {
    //   // Capture the image
    //   RenderRepaintBoundary boundary =
    //   _globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary;
    //   final image = await boundary.toImage(pixelRatio: 3.0);
    //   final byteData = await image.toByteData(format: ImageByteFormat.png);
    //   final Uint8List pngBytes = byteData!.buffer.asUint8List();
    //
    //   // Save the image to the gallery
    //   final result = await ImageGallerySaver.saveImage(pngBytes, name: 'captured_image');
    //
    //   // Show a message based on the result
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text(result['isSuccess'] ? 'Image saved to gallery!' : 'Failed to save image.')),
    //   );
    // } catch (e) {
    //   print(e);
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text('Error: $e')),
    //   );
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Image Manipulation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _captureAndSaveImage,
          ),
        ],
      ),
      body: Center(
        child: RepaintBoundary(
          key: _globalKey,
          child: AspectRatio(
            aspectRatio: 180/180,
            child: Container(
              child: Stack(
                children: [
                  // Blurred background
                  Positioned.fill(
                    child: Container(

                      child: Image.file(
                        widget.image,
                        height: widget.height,
                        width: widget.width,// Replace with your image URL
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                      child: Container(
                        color: Colors.black.withOpacity(0), // Transparent layer on top
                      ),
                    ),
                  ),
                  // Frame with image interaction
                  Center(
                    child: AspectRatio(
                      aspectRatio: 180/180,
                      child: Container(// Fra


                        child: InteractiveViewer(
                          panEnabled: true,
                          minScale:0.5,
                          maxScale: 4.0,
                          child: Image.file(
                            widget.image, // Replace with the image to manipulate
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

