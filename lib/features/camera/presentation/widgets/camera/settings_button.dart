import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_camera/core/utils/helpers.dart';
import 'package:mechanix_camera/features/camera/bloc/camera_bloc.dart';
import 'package:mechanix_camera/features/camera/bloc/camera_settings/camera_settings_bloc.dart';
import 'package:mechanix_camera/features/camera/model/camera_types.dart';

class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CameraSettingsBloc, CameraSettingsState>(
      builder: (context, settingsState) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              context.read<CameraBloc>().add(
                    const OpenCameraWithSettings(CameraSettingsPanel.none),
                  );
            },
            customBorder: const CircleBorder(),
            child: AnimatedRotation(
              turns: getRotationTurns(settingsState.orientation),
              duration: const Duration(milliseconds: 300),
              child: Container(
                height: 48,
                width: 48,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: Colors.white24),
                child: BlocBuilder<CameraBloc, CameraState>(
                  builder: (context, state) {
                    return switch (state) {
                      CameraReady() => const Icon(
                          Icons.settings,
                          color: Colors.white,
                          size: 32,
                        ),
                      _ => const SizedBox.shrink(),
                    };
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
