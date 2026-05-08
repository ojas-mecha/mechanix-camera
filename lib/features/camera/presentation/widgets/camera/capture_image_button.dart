import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_camera/core/utils/app_routes.dart';
import 'package:mechanix_camera/features/camera/bloc/camera_bloc.dart';

class CapturedImageButton extends StatelessWidget {
  const CapturedImageButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          context.read<CameraBloc>().add(LastCaptureImageRequested());
          Navigator.pushNamed(context, AppRoutes.capturedImageScreen);
        },
        customBorder: const CircleBorder(),
        child: Container(
          height: 48,
          width: 48,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: BlocBuilder<CameraBloc, CameraState>(
            builder: (context, state) {
              if (state is CameraReady && state.lastCapturedPath != null) {
                return CircleAvatar(
                  backgroundImage: FileImage(File(state.lastCapturedPath!)),
                );
              } else {
                return const SizedBox.shrink();
              }
            },
          ),
        ),
      ),
    );
  }
}
