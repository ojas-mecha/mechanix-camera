import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_camera/features/camera/bloc/camera_bloc.dart';
import 'package:mechanix_camera/features/camera/presentation/widgets/camera/capture_button.dart';
import 'package:mechanix_camera/features/camera/presentation/widgets/camera/capture_image_button.dart';
import 'package:mechanix_camera/features/camera/presentation/widgets/camera/settings_button.dart';

class CameraFooter extends StatelessWidget {
  const CameraFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CameraBloc, CameraState>(
      builder: (context, state) {
        return switch (state) {
          CameraReady() => const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CapturedImageButton(),
              CaptureButton(),
              SettingsButton(),
            ],
          ),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }
}
