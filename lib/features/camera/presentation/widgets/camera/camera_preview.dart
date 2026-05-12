import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_camera/features/camera/bloc/camera_bloc.dart';
import 'package:mechanix_camera/features/camera/bloc/camera_settings/camera_settings_bloc.dart';
import 'package:mechanix_camera/features/camera/presentation/widgets/camera/capture_flash_overlay.dart';
import 'package:mechanix_camera/l10n/app_localizations.dart';

class CameraPreviewWidget extends StatelessWidget {
  const CameraPreviewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CameraBloc>();

    return SizedBox(
      height: double.infinity,
      width: double.infinity,
      child: BlocListener<CameraBloc, CameraState>(
        listener: (context, state) {
          if (state is CameraReady) {
            context.read<CameraSettingsBloc>().add(
              const StartOrientationListener(),
            );
          }
        },
        listenWhen: (previous, current) =>
            current is CameraReady && previous is! CameraReady,
        child: BlocBuilder<CameraBloc, CameraState>(
          builder: (context, state) {
            return Stack(
              fit: StackFit.expand,
              children: [
                switch (state) {
                  CameraLoading() => const Center(
                    child: CircularProgressIndicator(),
                  ),

                  CameraReady() ||
                  CameraCaptureInProgress() => CameraPreview(bloc.controller),

                  CameraError() => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(state.message, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context.read<CameraBloc>().add(
                            const CameraInitialized(),
                          ),
                          child: Text(AppLocalizations.of(context)!.retry),
                        ),
                      ],
                    ),
                  ),

                  _ => const SizedBox.shrink(),
                },

                const CaptureFlashOverlay(),
              ],
            );
          },
        ),
      ),
    );
  }
}
