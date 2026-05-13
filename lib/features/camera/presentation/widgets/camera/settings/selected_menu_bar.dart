import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_camera/features/camera/bloc/camera_bloc.dart';
import 'package:mechanix_camera/features/camera/model/camera_types.dart';
import 'package:mechanix_camera/features/camera/presentation/widgets/camera/settings/aspect_ratio_bar.dart';

class SelectedMenuBar extends StatelessWidget {
  const SelectedMenuBar({super.key});

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
        if (settingsPanel == CameraSettingsPanel.aspectRatio) {
          return const AspectRatioBar();
        }

        return const SizedBox.shrink();
      },
    );
  }
}
