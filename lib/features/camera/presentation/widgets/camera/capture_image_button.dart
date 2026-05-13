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
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(-0.3, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child:
                              FadeTransition(opacity: animation, child: child),
                        );
                      },
                      child: state is CameraReady &&
                              state.lastCapturedPath != null
                          ? Image.file(
                              File(state.lastCapturedPath!),
                              key: ValueKey(state.lastCapturedPath),
                              fit: BoxFit.cover,
                              width: 48,
                              height: 48,
                            )
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
