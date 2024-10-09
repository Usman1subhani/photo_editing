import 'dart:io';
import 'dart:typed_data';
import 'package:cropmeapp/Constants/color_constants.dart';
import 'package:cropmeapp/Constants/image_constants.dart';
import 'package:cropmeapp/Screens/editImage.dart';
import 'package:cropmeapp/Screens/resizeScreen.dart';
import 'package:cropmeapp/Screens/resizeWithPlatform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_editor_plus/image_editor_plus.dart';
import 'package:image_picker/image_picker.dart';

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
    'Twitter',
    'LinkedIn',
    'WhatsApp',
    'Snapchat',
    'Pinterest'
  ];
  final List<String> newPlatforms = ['Snapchat', 'Pinterest'];

  final Map<String, IconData> platformIcons = {
    'Facebook': FontAwesomeIcons.facebook,
    'Instagram': FontAwesomeIcons.instagram,
    'WhatsApp': FontAwesomeIcons.whatsapp,
    'Snapchat': FontAwesomeIcons.snapchat,
    'Twitter': FontAwesomeIcons.twitter,
    'LinkedIn': FontAwesomeIcons.linkedin,
    'Pinterest': FontAwesomeIcons.pinterest,
  };

  Future<void> selectGalleryImageForSocialMedia(BuildContext context, String platform) async {
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
          builder: (context) =>
              ResizeScreen(imageFile: imageFile),
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
    return Scaffold(
      backgroundColor: ColorConstants.backgroundColor,
      appBar: AppBar(
        leading: GestureDetector(
            onTap: () {},
            child: const Icon(FontAwesomeIcons.crown,
                size: 25, color: Colors.yellowAccent)),
        title: const Text("CropMe",
            style: TextStyle(
                color: ColorConstants.primaryColor,
                fontWeight: FontWeight.w700)),
        centerTitle: true,
        backgroundColor: ColorConstants.bottomBar,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                selectGalleryImage(context);
              },
              child: Container(
                height: 150,
                width: 400,
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: ColorConstants.bottomBar,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(Icons.add_a_photo,
                          size: 40, color: ColorConstants.primaryColor),
                      Text('Resize Image',
                          style: TextStyle(
                              color: ColorConstants.primaryColor,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),
            // Container(
            //   height: 120,
            //   width: double.infinity,
            //   margin: const EdgeInsets.only(left: 15, right: 15),
            //   child: ListView.builder(
            //       scrollDirection: Axis.horizontal,
            //       itemCount: platforms.length,
            //       itemBuilder: (context, index) {
            //         String platform = platforms[index];
            //         IconData icon = platformIcons[platform]!;
            //         return GestureDetector(
            //           onTap: () {
            //             selectGalleryImage(context, platform);
            //           },
            //           child: Container(
            //             height: 100,
            //             width: 100,
            //             margin: const EdgeInsets.all(5),
            //             decoration: BoxDecoration(
            //               color: ColorConstants.bottomBar,
            //               borderRadius: BorderRadius.circular(20),
            //             ),
            //             child: Center(child: FaIcon(icon, size: 40, color: ColorConstants.primaryColor)),
            //           ),
            //         );
            //       }
            //   ),
            // ),
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Resize Image for',
                      style: TextStyle(
                          color: ColorConstants.primaryColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 20)),
                  SizedBox(height: 15.h),
                  SizedBox(
                    height: 60,
                    width: double.infinity,
                    child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: platforms.sublist(0, 5).length,
                        itemBuilder: (context, index) {
                          String platform = platforms[index];
                          IconData icon = platformIcons[platform]!;

                          Color platformColor;
                          switch (platform) {
                            case 'Facebook':
                              platformColor = ColorConstants.facebookColor;
                              break;
                            case 'Instagram':
                              platformColor = ColorConstants.instagramColor;
                              break;
                            case 'Twitter':
                              platformColor = ColorConstants.twitterColor;
                              break;
                            case 'WhatsApp':
                              platformColor = ColorConstants.whatsAppColor;
                              break;
                            case 'LinkedIn':
                              platformColor = ColorConstants.linkedInColor;
                              break;
                            case 'Pinterest':
                              platformColor = ColorConstants.pinterestColor;
                              break;
                            case 'Snapchat':
                              platformColor = ColorConstants.snapchatColor;
                              break;
                            default:
                              platformColor = ColorConstants.bottomBar;
                          }

                          return GestureDetector(
                            onTap: () {
                              selectGalleryImageForSocialMedia(context, platform);
                            },
                            child: Container(
                              height: 50,
                              width: 50,
                              margin: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: platformColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                  child: FaIcon(icon,
                                      size: 30,
                                      color: ColorConstants.primaryColor)),
                            ),
                          );
                        }),
                  ),
                  SizedBox(
                    height: 60,
                    width: double.infinity,
                    child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: newPlatforms.length,
                        itemBuilder: (context, index) {
                          String platform = newPlatforms[index];
                          IconData icon = platformIcons[platform]!;

                          Color platformColor;
                          Color? iconColor;
                          switch (platform) {
                            case 'Facebook':
                              platformColor = ColorConstants.facebookColor;
                              break;
                            case 'Instagram':
                              platformColor = ColorConstants.instagramColor;
                              break;
                            case 'Twitter':
                              platformColor = ColorConstants.twitterColor;
                              break;
                            case 'WhatsApp':
                              platformColor = ColorConstants.whatsAppColor;
                              break;
                            case 'LinkedIn':
                              platformColor = ColorConstants.linkedInColor;
                              break;
                            case 'Pinterest':
                              platformColor = ColorConstants.pinterestColor;
                              iconColor = ColorConstants.primaryColor;
                              break;
                            case 'Snapchat':
                              platformColor = ColorConstants.snapchatColor;
                              iconColor = ColorConstants.secondaryColor;
                              break;
                            default:
                              platformColor = ColorConstants.bottomBar;
                          }

                          return GestureDetector(
                            onTap: () {
                              selectGalleryImageForSocialMedia(context, platform);
                            },
                            child: Container(
                              height: 50,
                              width: 50,
                              margin: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: platformColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                  child:
                                      FaIcon(icon, size: 30, color: iconColor)),
                            ),
                          );
                        }),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Text('', style: TextStyle(color: ColorConstants.primaryColor, fontWeight: FontWeight.w500, fontSize: 20)),
                  Container(
                    height: 140,
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 10, bottom: 10),
                    decoration: BoxDecoration(
                      color: ColorConstants.bottomBar,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  selectGalleryImageforEdit(context);
                                },
                                child: Container(
                                  height: 80,
                                  width: 80,
                                  margin: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: ColorConstants.backgroundColor,
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: const Center(
                                      child: FaIcon(FontAwesomeIcons.image,
                                          size: 30,
                                          color: ColorConstants.primaryColor)),
                                ),
                              ),
                              const Text('Edit',
                                  style: TextStyle(
                                      color: ColorConstants.primaryColor,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 15)),
                            ],
                          ),
                          Column(
                            children: [
                              GestureDetector(
                                onTap: () {

                                },
                                child: Container(
                                  height: 80,
                                  width: 80,
                                  margin: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: ColorConstants.backgroundColor,
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: const Center(
                                      child: Image(image: AssetImage("assets/collage.png"), width: 30, height: 30),
                                  ),
                                ),
                              ),
                              const Text('Collage',
                                  style: TextStyle(
                                      color: ColorConstants.primaryColor,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 15)),
                            ],
                          ),
                          Column(
                            children: [
                              GestureDetector(
                                onTap: () {},
                                child: Container(
                                  height: 80,
                                  width: 80,
                                  margin: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: ColorConstants.backgroundColor,
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: const Center(
                                      child: Image(image: AssetImage("assets/image_compress.png"), width: 30, height: 30),
                                      // FaIcon(FontAwesomeIcons.compress,
                                      //     size: 30,
                                      //     color: ColorConstants.primaryColor)
                                  ),
                                ),
                              ),
                              const Text('Compress',
                                  style: TextStyle(
                                      color: ColorConstants.primaryColor,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 15)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Padding(
            //   padding: const EdgeInsets.only(left: 20, right: 20, top: 5),
            //   child: Column(
            //     crossAxisAlignment: CrossAxisAlignment.start,
            //     children: [
            //       Row(
            //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //         children: [
            //           const Text('Trending', style: TextStyle(color: ColorConstants.primaryColor, fontWeight: FontWeight.w500, fontSize: 20)),
            //           IconButton(
            //               onPressed: () {},
            //               icon: const Icon(
            //                 Icons.navigate_next,
            //                 color: ColorConstants.primaryColor,
            //                 size: 30,
            //               ),
            //           ),
            //         ],
            //       ),
            //       Container(
            //         height: 140,
            //         width: double.infinity,
            //         margin: const EdgeInsets.only(top: 10, bottom: 10),
            //         decoration: BoxDecoration(
            //           color: ColorConstants.bottomBar,
            //           borderRadius: BorderRadius.circular(20),
            //         ),
            //         child: const Padding(
            //           padding: const EdgeInsets.only(top: 10),
            //           child: Row(
            //             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            //             children: [
            //
            //             ],
            //           ),
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
