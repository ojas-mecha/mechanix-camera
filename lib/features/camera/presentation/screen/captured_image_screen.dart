import 'package:flutter/material.dart';
import 'package:mechanix_camera/features/camera/presentation/widgets/captured_image/bottom_bar.dart';
import 'package:mechanix_camera/features/camera/presentation/widgets/captured_image/captured_image.dart';

class CapturedImageScreen extends StatelessWidget {
  const CapturedImageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: CapturedImage(),
      backgroundColor: Colors.black,
      bottomNavigationBar: BottomBar(),
    );
  }
}
