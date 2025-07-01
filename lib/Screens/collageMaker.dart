import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_collage_widget/utils/collage_type.dart';

// ignore: must_be_immutable
class CollageMaker extends StatefulWidget {
  File? imageFile1;
  File? imageFile2;
  File? imageFile3;

  CollageMaker({super.key, this.imageFile1, this.imageFile2, this.imageFile3});

  @override
  State<CollageMaker> createState() => _CollageMakerState();
}

class _CollageMakerState extends State<CollageMaker> {
  @override
  Widget build(BuildContext context) {

    Widget buildRaisedButton(CollageType collageType, String text) {
      return ElevatedButton(
        onPressed: () {

        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(text, style: const TextStyle(color: Colors.blue)),
        ),
      );
    }

    return Scaffold(
      body: Center(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          shrinkWrap: true,
          children: <Widget>[
            buildRaisedButton(CollageType.vSplit, 'Vsplit'),
            buildRaisedButton(CollageType.hSplit, 'HSplit'),
            buildRaisedButton(CollageType.fourSquare, 'FourSquare'),
            buildRaisedButton(CollageType.nineSquare, 'NineSquare'),
            buildRaisedButton(CollageType.threeVertical, 'ThreeVertical'),
            buildRaisedButton(CollageType.threeHorizontal, 'ThreeHorizontal'),
            buildRaisedButton(CollageType.leftBig, 'LeftBig'),
            buildRaisedButton(CollageType.rightBig, 'RightBig'),
            buildRaisedButton(CollageType.fourLeftBig, 'FourLeftBig'),
            buildRaisedButton(CollageType.vMiddleTwo, 'VMiddleTwo'),
            buildRaisedButton(CollageType.centerBig, 'CenterBig'),
          ],
        ),
      ),
    );
  }
  // pushImageWidget(CollageType type, List<Images> images) async {
  //   await Navigator.of(context).push(
  //     FadeRouteTransition(page: CollageSample(type, images)),
  //   );
  // }
  //
  // RoundedRectangleBorder buttonShape() {
  //   return RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0));
  // }
}
