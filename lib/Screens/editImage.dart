import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:pro_image_editor/models/editor_callbacks/pro_image_editor_callbacks.dart';
import 'package:pro_image_editor/modules/main_editor/main_editor.dart';

class EditImage extends StatefulWidget {
  final File imageFile;

  const EditImage({super.key, required this.imageFile});

  @override
  State<EditImage> createState() => _EditImageState();
}

class _EditImageState extends State<EditImage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: BackButton(color: theme.colorScheme.onSurface),
        centerTitle: true,
        title: Text(
          'Edit',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.save_alt_rounded, color: theme.colorScheme.primary),
            onPressed: () async {
              // The editor will call onImageEditingComplete when done is pressed.
              // This button is a fallback or alternative way to trigger the save.
              // We need a way to trigger the editor's internal done button logic.
              // For now, we rely on the user pressing the editor's own done button.
            },
          ),
        ],
      ),
      body: ProImageEditor.file(
        widget.imageFile,
        callbacks: ProImageEditorCallbacks(
          onImageEditingComplete: (Uint8List bytes) async {
            await _saveImage(bytes);
          },
        ),
      ),
    );
  }

  Future<void> _saveImage(Uint8List bytes) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Save to gallery
      final result = await ImageGallerySaver.saveImage(
        bytes,
        quality: 100,
        name: "edited_image_${DateTime.now().millisecondsSinceEpoch}",
      );

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (result['isSuccess']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image saved to gallery')),
        );
        if (mounted) Navigator.of(context).pop();
      } else {
        throw Exception(result['errorMessage'] ?? 'Failed to save image');
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving image: $e')),
      );
    }
  }
}
