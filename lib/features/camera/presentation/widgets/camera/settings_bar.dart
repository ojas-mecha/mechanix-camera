import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_camera/core/utils/constants.dart';
import 'package:mechanix_camera/core/utils/images.dart';
import 'package:mechanix_camera/features/camera/bloc/camera_bloc.dart';
import 'package:mechanix_camera/features/camera/model/camera_types.dart';
import 'package:mechanix_camera/features/camera/presentation/widgets/camera/settings/aspect_ratio_bar.dart';

class SettingsBar extends StatelessWidget {
  const SettingsBar({super.key});

  static const _buttonStyle = ButtonStyle(
    fixedSize: WidgetStatePropertyAll(Size(48, 48)),
  );

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [_AspectRatioSection(), _BottomSettingsBar()],
    );
  }
}

class _AspectRatioSection extends StatelessWidget {
  const _AspectRatioSection();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CameraBloc, CameraState, CameraSettingsPanel>(
      selector: (state) {
        if (state is CameraReady) {
          return state.settingsPanel;
        }

        return CameraSettingsPanel.none;
      },
      builder: (context, settingsPanel) {
        if (settingsPanel != CameraSettingsPanel.aspectRatio) {
          return const SizedBox.shrink();
        }

        return const AspectRationBar();
      },
    );
  }
}

class _BottomSettingsBar extends StatelessWidget {
  const _BottomSettingsBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [_CloseButton(), _AspectRatioButton()],
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      style: SettingsBar._buttonStyle,
      onPressed: () {
        context.read<CameraBloc>().add(CloseCameraWithSettings());
      },
      icon: const Images(image: AppConstants.close, size: Size(16, 16)),
    );
  }
}

class _AspectRatioButton extends StatelessWidget {
  const _AspectRatioButton();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CameraBloc, CameraState, CameraSettingsPanel>(
      selector: (state) {
        if (state is CameraReady) {
          return state.settingsPanel;
        }

        return CameraSettingsPanel.none;
      },
      builder: (context, settingsPanel) {
        final isOpen = settingsPanel == CameraSettingsPanel.aspectRatio;

        return IconButton(
          style: SettingsBar._buttonStyle,
          onPressed: () {
            context.read<CameraBloc>().add(
              OpenCameraWithSettings(
                isOpen
                    ? CameraSettingsPanel.none
                    : CameraSettingsPanel.aspectRatio,
              ),
            );
          },
          icon: const Images(
            image: AppConstants.aspectRatio,
            size: Size(23, 20),
          ),
        );
      },
    );
  }
}
