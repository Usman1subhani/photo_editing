import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CollageScreen extends StatefulWidget {
  const CollageScreen({Key? key}) : super(key: key);

  @override
  State<CollageScreen> createState() => _CollageScreenState();
}

class _CollageScreenState extends State<CollageScreen> {
  int selectedFrameIndex = 0;

  // Placeholder for frame templates
  final List<String> frameTypes = ['2-grid', '3-grid', '4-grid', 'Custom']; // You can later use custom widgets

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: const BackButton(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(FontAwesomeIcons.check, color: Colors.greenAccent),
            onPressed: () {
              // TODO: Save/Export Collage Logic
            },
          )
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),

          // 🖼 Collage Frame Area
          Expanded(
            child: Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.width * 0.9,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blueAccent, width: 2.5),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: Center(
                  child: Text(
                    'Frame: ${frameTypes[selectedFrameIndex]}',
                    style: const TextStyle(color: Colors.black87, fontSize: 18),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 🔳 Bottom Frame Options
          Container(
            height: 90,
            color: Colors.grey[900],
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: frameTypes.length,
              itemBuilder: (context, index) {
                final isSelected = selectedFrameIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => selectedFrameIndex = index),
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white24 : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.grid_on, color: isSelected ? Colors.white : Colors.grey),
                        const SizedBox(height: 6),
                        Text(
                          frameTypes[index],
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey,
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
