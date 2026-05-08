import 'package:flutter/material.dart';
import 'package:mechanix_camera/features/camera/presentation/screen/camera_screen.dart';
import 'package:mechanix_camera/features/camera/presentation/screen/captured_image_screen.dart';

class AppRoutes {
  static const String cameraScreen = '/camera_screen';
  static const String capturedImageScreen = '/captured_image_screen';

  static Map<String, Widget Function(BuildContext)> routes = {
    cameraScreen: (context) => const CameraScreen(),
    capturedImageScreen: (context) => const CapturedImageScreen(),
  };
}
