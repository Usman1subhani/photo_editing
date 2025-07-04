import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CollageScreen extends StatefulWidget {
  const CollageScreen({Key? key}) : super(key: key);

  @override
  State<CollageScreen> createState() => _CollageScreenState();
}

class _CollageScreenState extends State<CollageScreen> {
  int selectedFrameIndex = 0;
  List<File?> images = List.generate(4, (index) => null); // supports up to 4-grid

  final picker = ImagePicker();

  Future<void> _pickImage(int index) async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => images[index] = File(pickedFile.path));
    }
  }

  Widget _buildFrame() {
    switch (selectedFrameIndex) {
      case 0:
        return Row(
          children: [0, 1].map((i) => _buildImageBox(i)).toList(),
        );
      case 1:
        return Column(
          children: [0, 1, 2].map((i) => _buildImageBox(i)).toList(),
        );
      case 2:
        return GridView.count(
          crossAxisCount: 2,
          children: List.generate(4, (i) => _buildImageBox(i)),
          shrinkWrap: true,
        );
      default:
        return Center(child: Text('Custom Frame'));
    }
  }

  Widget _buildImageBox(int index) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _pickImage(index),
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 1),
            color: Colors.grey[800],
          ),
          child: images[index] == null
              ? const Icon(Icons.add, color: Colors.white)
              : Image.file(images[index]!, fit: BoxFit.cover),
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
        leading: const BackButton(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.greenAccent),
            onPressed: () {
              // TODO: Export/save logic
            },
          )
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blueAccent, width: 2.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _buildFrame(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 90,
            color: Colors.grey[900],
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => setState(() => selectedFrameIndex = index),
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: selectedFrameIndex == index
                          ? Colors.white24
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.grid_on,
                            color: selectedFrameIndex == index
                                ? Colors.white
                                : Colors.grey),
                        const SizedBox(height: 6),
                        Text(
                          '${index + 2}-Grid',
                          style: TextStyle(
                            color: selectedFrameIndex == index
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
          )
        ],
      ),
    );
  }
}
