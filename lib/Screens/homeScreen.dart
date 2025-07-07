import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cropmeapp/Screens/Compress.dart';
import 'package:cropmeapp/Screens/editImage.dart';
import 'package:cropmeapp/Screens/collageMaker.dart' hide Padding;
import 'package:cropmeapp/Screens/resizeScreen.dart';
import 'package:cropmeapp/Constants/color_constants.dart';
import 'package:cropmeapp/Screens/resizeWithPlatform.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _imageFile;
  final picker = ImagePicker();
  final List<String> platforms = [
    'Facebook',
    'Instagram',
    'TikTok',
    'YouTube',
    'Twitter',
  ];
  final List<String> newPlatforms = [
    'LinkedIn',
    'WhatsApp',
    'Snapchat',
    'Pinterest', // Only in newPlatforms, not in platforms
  ];

  final Map<String, IconData> platformIcons = {
    'Facebook': FontAwesomeIcons.facebook,
    'Instagram': FontAwesomeIcons.instagram,
    'TikTok': FontAwesomeIcons.tiktok,
    'YouTube': FontAwesomeIcons.youtube,
    'WhatsApp': FontAwesomeIcons.whatsapp,
    'Snapchat': FontAwesomeIcons.snapchat,
    'Twitter': FontAwesomeIcons.twitter,
    'LinkedIn': FontAwesomeIcons.linkedin,
    'Pinterest': FontAwesomeIcons.pinterest,
  };

  final Map<String, Color> platformBrandColors = {
    'Facebook': const Color(0xFF1877F3),
    'Instagram': const Color(0xFFE4405F),
    'TikTok': const Color(0xFF69C9D0),
    'YouTube': const Color(0xFFFF0000),
    'Twitter': const Color(0xFF1DA1F2),
    'LinkedIn': const Color(0xFF0A66C2),
    'WhatsApp': const Color(0xFF25D366),
    'Snapchat': const Color(0xFFFFFC00),
    'Pinterest': const Color(0xFFE60023),
  };

  Future<void> selectGalleryImageForSocialMedia(
      BuildContext context, String platform) async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ResizeWithPlatform(imageFile: imageFile, platform: platform),
        ),
      );
    }
  }

  Future<void> selectGalleryImage(BuildContext context) async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResizeScreen(imageFile: imageFile),
        ),
      );
    }
  }

  Future<void> selectGalleryImageforEdit(BuildContext context) async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditImage(imageFile: imageFile),
        ),
      );
    }
  }

  Future<void> selectCameraImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardActions = [
      {
        'label': 'Resize',
        'icon': FontAwesomeIcons.expandArrowsAlt,
        'color': const Color(0xFF6750A4),
        'onTap': () => selectGalleryImage(context),
        'desc': 'Resize images for any platform',
      },
      {
        'label': 'Edit',
        'icon': FontAwesomeIcons.edit,
        'color': const Color(0xFF03DAC6),
        'onTap': () => selectGalleryImageforEdit(context),
        'desc': 'Crop, draw, and enhance',
      },
      {
        'label': 'Collage',
        'icon': FontAwesomeIcons.images,
        'color': const Color(0xFFE4405F),
        'onTap': () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const CollageScreen())),
        'desc': 'Combine multiple images',
      },
      {
        'label': 'Compress',
        'icon': FontAwesomeIcons.compress,
        'color': const Color(0xFF1DA1F2),
        'onTap': () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const CompressScreen())),
        'desc': 'Reduce file size, keep quality',
      },
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Icon(FontAwesomeIcons.crown,
              size: 28, color: Colors.amber.shade400),
        ),
        title: const Text("CropMe"),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome!",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Resize, edit, collage, and compress your images for any social platform.",
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context)
                        .colorScheme
                        .onBackground
                        .withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 24),
                // --- Social Media Grid (2 rows) ---
                Text(
                  "Resize for Social Media",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 10),
                // Custom 2-row grid for social icons: 5 in first row, 4 centered in second row
                // Responsive 2-row grid for social icons: 5 in first row, 4 centered in second row, no overflow
                LayoutBuilder(
                  builder: (context, constraints) {
                    const double iconCardWidth = 55;
                    const double iconCardSpacing = 5;
                    final double totalWidth = constraints.maxWidth;
                    // Calculate left padding to center 5 icons in first row
                    const double row1ContentWidth =
                        5 * iconCardWidth + 4 * iconCardSpacing;
                    final double row1LeftPad =
                        (totalWidth - row1ContentWidth) / 2;
                    // Calculate left padding to center 4 icons in second row
                    const double row2ContentWidth =
                        4 * iconCardWidth + 3 * iconCardSpacing;
                    final double row2LeftPad =
                        (totalWidth - row2ContentWidth) / 2;
                    return // 2-row grid for social icons: 5 in first row (centered, 2px padding), 4 centered in second row
                        Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ...platforms.map((platform) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 2.0, vertical: 2),
                                  child: GestureDetector(
                                    onTap: () =>
                                        selectGalleryImageForSocialMedia(
                                            context, platform),
                                    child: Card( 
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Container(
                                        width: 54,
                                        height: 70,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            FaIcon(
                                              platformIcons[platform],
                                              color:
                                                  platformBrandColors[platform],
                                              size: 24,
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              platform,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: platformBrandColors[
                                                    platform],
                                                fontSize: 11,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ))
                          ],
                        ),
                        const SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ...newPlatforms.map((platform) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 3.0, vertical: 2),
                                  child: GestureDetector(
                                    onTap: () =>
                                        selectGalleryImageForSocialMedia(
                                            context, platform),
                                    child: Card(
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Container(
                                        width: 54,
                                        height: 70,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            FaIcon(
                                              platformIcons[platform],
                                              color:
                                                  platformBrandColors[platform],
                                              size: 24,
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              platform,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: platformBrandColors[
                                                    platform],
                                                fontSize: 11,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ))
                          ],
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 32),
                // --- Main Action Cards ---
                Wrap(
                  spacing: 18,
                  runSpacing: 18,
                  children: cardActions.map((action) {
                    return SizedBox(
                      width: (MediaQuery.of(context).size.width - 18 * 3) / 2,
                      child: GestureDetector(
                        onTap: action['onTap'] as void Function(),
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              gradient: LinearGradient(
                                colors: [
                                  (action['color'] as Color).withOpacity(0.13),
                                  Colors.white,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: (action['color'] as Color)
                                      .withOpacity(0.13),
                                  child: Icon(
                                    action['icon'] as IconData,
                                    color: action['color'] as Color,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  action['label'] as String,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  action['desc'] as String,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onBackground
                                        .withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                // --- Reserved space for ads ---
                SizedBox(height: 60),
              ],
            )),
      ),
    );
  }
}
