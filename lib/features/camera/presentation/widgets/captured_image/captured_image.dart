import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_camera/features/camera/bloc/camera_bloc.dart';

class CapturedImage extends StatelessWidget {
  const CapturedImage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CameraBloc, CameraState>(
      builder: (context, state) {
        return switch (state) {
          CapturedImagePreview() => Center(
            child: Image.file(File(state.lastCapturedPath), fit: BoxFit.cover),
          ),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }
}
