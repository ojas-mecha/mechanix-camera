import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_camera/features/camera/bloc/camera_bloc.dart';

class CaptureButton extends StatelessWidget {
  const CaptureButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (context.read<CameraBloc>().state is CameraReady) {
            context.read<CameraBloc>().add(CameraCaptureRequested());
          }
        },
        customBorder: const CircleBorder(),
        child: Container(
          height: 80,
          width: 80,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            // shape: BoxShape.circle,
            color: Colors.white24,
          ),
          child: Container(
            height: 60,
            width: 60,
            decoration: const BoxDecoration(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
