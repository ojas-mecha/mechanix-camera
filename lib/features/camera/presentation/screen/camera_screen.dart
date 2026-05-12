import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_camera/features/camera/bloc/camera_bloc.dart';
import 'package:mechanix_camera/features/camera/presentation/widgets/camera/camera_footer.dart';
import 'package:mechanix_camera/features/camera/presentation/widgets/camera/camera_preview.dart';
import 'package:mechanix_camera/features/camera/presentation/widgets/camera/settings_bar.dart';

class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: CameraPreviewWidget()),
          const Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: 20, left: 10, right: 10),
              child: CameraFooter(),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              color: Colors.black,
              child: BlocBuilder<CameraBloc, CameraState>(
                builder: (context, state) {
                  return switch (state) {
                    CameraReady(isSettingsOpen: false) =>
                      const SizedBox.shrink(),
                    CameraReady(isSettingsOpen: true) => const SettingsBar(),
                    _ => const SizedBox.shrink(),
                  };
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
