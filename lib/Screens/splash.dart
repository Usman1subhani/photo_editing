import 'dart:async';
import 'package:cropmeapp/Constants/color_constants.dart';
import 'package:cropmeapp/Constants/image_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'homeScreen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.backgroundColor,
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.all(50.r),
          child: Column(
            children: [
              Center(
                child: SizedBox(
                  height: 400.h,
                  width: 300.w,
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Image.asset(ImageConstants.splash2, fit: BoxFit.cover)),
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                "Free Social Media Image Resizer",
                style: TextStyle(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.bold,
                  color: ColorConstants.primaryColor
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                "Your go-to Social Media Resizer Tool for Instagram, Facebook, LinkedIn, Twitter and more!",
                style: TextStyle(
                    fontSize: 20.sp,
                    color: ColorConstants.primaryColor
                ),
              ),
              SizedBox(height: 25.h),
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => HomeScreen()));
                },
                child: Container(
                  height: 60.h,
                  width: 170.w,
                  decoration: BoxDecoration(
                    color: ColorConstants.buttonColor,
                    borderRadius: BorderRadius.circular(50)
                  ),
                  child: Center(
                    child: Text(
                      "Get Started",
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w500,
                        color: ColorConstants.primaryColor
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
