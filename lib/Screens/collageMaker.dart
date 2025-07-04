import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class CollageScreen extends StatefulWidget {
  const CollageScreen({super.key});

  @override
  State<CollageScreen> createState() => _CollageScreenState();
}

class _CollageScreenState extends State<CollageScreen> {
  int selectedFrameIndex = 0;
  List<File?> images = List.generate(6, (index) => null); // Up to 6 images
  final List<String> frameNames = [
    "2-H",
    "3-V",
    "2x2",
    "3-H",
    "Big+2",
    "Staggered",
  ];

  final picker = ImagePicker();

  Future<void> _pickImage(int index) async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => images[index] = File(pickedFile.path));
    }
  }

  Widget _buildFrame() {
    switch (selectedFrameIndex) {
      case 0: // 2-grid horizontal
        return Row(
          children: [0, 1].map((i) => _buildImageBox(i)).toList(),
        );

      case 1: // 3-grid vertical
        return Column(
          children: [0, 1, 2].map((i) => _buildImageBox(i)).toList(),
        );

      case 2: // 2x2 grid
        return GridView.count(
          crossAxisCount: 2,
          children: List.generate(4, (i) => _buildImageBox(i)),
          shrinkWrap: true,
        );

      case 3: // 3-horizontal
        return Row(
          children: [0, 1, 2].map((i) => _buildImageBox(i)).toList(),
        );

      case 4: // 1 big left + 2 stacked right
        return Row(
          children: [
            Expanded(flex: 2, child: _buildImageBox(0)),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  Expanded(child: _buildImageBox(1)),
                  Expanded(child: _buildImageBox(2)),
                ],
              ),
            ),
          ],
        );

      case 5: // Staggered layout
        return Padding(
          padding: const EdgeInsets.all(4.0),
          child: MasonryGridView.count(
            crossAxisCount: 2,
            itemCount: 6,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _pickImage(index),
                child: Container(
                  height: (index % 2 == 0) ? 120 : 180,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    border: Border.all(color: Colors.white),
                  ),
                  child: images[index] == null
                      ? const Icon(Icons.add, color: Colors.white)
                      : Image.file(images[index]!, fit: BoxFit.cover),
                ),
              );
            },
          ),
        );

      default:
        return const Center(
            child: Text('Invalid frame index',
                style: TextStyle(color: Colors.white)));
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
