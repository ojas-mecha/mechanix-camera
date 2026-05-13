import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_camera/core/utils/app_routes.dart';
import 'package:mechanix_camera/core/utils/helpers.dart';
import 'package:mechanix_camera/features/camera/bloc/camera_bloc.dart';
import 'package:mechanix_camera/features/camera/bloc/camera_settings/camera_settings_bloc.dart';

class CapturedImageButton extends StatelessWidget {
  const CapturedImageButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CameraSettingsBloc, CameraSettingsState>(
      builder: (context, settingsState) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              context.read<CameraBloc>().add(LastCaptureImageRequested());
              Navigator.pushNamed(context, AppRoutes.capturedImageScreen);
            },
            customBorder: const CircleBorder(),
            child: AnimatedRotation(
              turns: getRotationTurns(settingsState.orientation),
              duration: const Duration(milliseconds: 300),
              child: SizedBox(
                height: 48,
                width: 48,
                child: BlocBuilder<CameraBloc, CameraState>(
                  builder: (context, state) {
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(
                          scale: Tween<double>(begin: 0.0, end: 1.0).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutBack,
                            ),
                          ),
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      child:
                          state is CameraReady && state.lastCapturedPath != null
                          ? _ImageTile(path: state.lastCapturedPath!)
                          : Container(
                              key: const ValueKey('placeholder'),
                              color: Colors.white,
                            ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ImageTile extends StatelessWidget {
  const _ImageTile({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return Image.file(
      File(path),
      key: ValueKey(path),
      fit: BoxFit.cover,
      width: 48,
      height: 48,
    );
  }
}
