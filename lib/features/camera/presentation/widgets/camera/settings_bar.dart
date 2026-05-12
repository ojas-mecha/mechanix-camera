import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_camera/core/utils/constants.dart';
import 'package:mechanix_camera/core/utils/images.dart';
import 'package:mechanix_camera/features/camera/bloc/camera_bloc.dart';
import 'package:mechanix_camera/features/camera/model/camera_types.dart';
import 'package:mechanix_camera/features/camera/presentation/widgets/camera/settings/aspect_ratio_bar.dart';

class SettingsBar extends StatelessWidget {
  const SettingsBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BlocBuilder<CameraBloc, CameraState>(
          builder: (context, state) {
            return switch (state) {
              CameraReady(settingsPanel: CameraSettingsPanel.aspectRatio) =>
                const AspectRationBar(),
              _ => const SizedBox.shrink(),
            };
          },
        ),
        Container(
          height: 60,
          width: double.infinity,
          decoration: const BoxDecoration(borderRadius: BorderRadius.zero),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                style: const ButtonStyle(
                  fixedSize: WidgetStatePropertyAll(Size(48, 48)),
                ),
                onPressed: () {
                  context.read<CameraBloc>().add(CloseCameraWithSettings());
                },

                icon: const Images(
                  image: AppConstants.close,
                  size: Size(16, 16),
                ),
                color: Colors.black,
              ),
              BlocBuilder<CameraBloc, CameraState>(
                builder: (context, state) {
                  return IconButton(
                    style: const ButtonStyle(
                      fixedSize: WidgetStatePropertyAll(Size(48, 48)),
                    ),
                    onPressed: () {
                      context.read<CameraBloc>().add(
                        state is CameraReady &&
                                state.settingsPanel ==
                                    CameraSettingsPanel.aspectRatio
                            ? const OpenCameraWithSettings(
                                CameraSettingsPanel.none,
                              )
                            : const OpenCameraWithSettings(
                                CameraSettingsPanel.aspectRatio,
                              ),
                      );
                    },
                    icon: const Images(
                      image: AppConstants.aspectRatio,
                      size: Size(23, 20),
                    ),
                    color: Colors.black,
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
