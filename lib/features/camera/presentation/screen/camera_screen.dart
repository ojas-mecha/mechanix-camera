import 'package:flutter/material.dart';
import 'package:mechanix_camera/features/camera/presentation/widgets/camera/camera_footer.dart';
import 'package:mechanix_camera/features/camera/presentation/widgets/camera/camera_preview.dart';

class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: CameraPreviewWidget()),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: 20, left: 10, right: 10),
              child: CameraFooter(),
            ),
          ),
        ],
      ),
    );
  }
}
