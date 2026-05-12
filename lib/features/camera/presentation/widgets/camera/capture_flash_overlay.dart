import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_camera/features/camera/bloc/camera_bloc.dart';

class CaptureFlashOverlay extends StatefulWidget {
  const CaptureFlashOverlay({super.key});

  @override
  State<CaptureFlashOverlay> createState() => _CaptureFlashOverlayState();
}

class _CaptureFlashOverlayState extends State<CaptureFlashOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 80,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CameraBloc, CameraState>(
      listenWhen: (previous, current) {
        return current is CameraCaptureInProgress;
      },
      listener: (previous, current) {
        _controller.forward(from: 0);
      },
      child: AnimatedBuilder(
        animation: _opacity,
        builder: (context, child) {
          if (_opacity.value == 0) {
            return const SizedBox.shrink();
          }

          return IgnorePointer(
            child: ColoredBox(
              color: Colors.black.withValues(alpha: _opacity.value),
            ),
          );
        },
      ),
    );
  }
}
