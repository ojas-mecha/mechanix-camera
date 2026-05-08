part of 'camera_bloc.dart';

sealed class CameraState extends Equatable {
  const CameraState();

  @override
  // List<Object> get props => [];
  List<Object?> get props => [];
}

final class CameraInitial extends CameraState {}

final class CameraLoading extends CameraState {}

final class CameraReady extends CameraState {
  final CameraController controller;
  final String? lastCapturedPath;

  const CameraReady(this.controller, {this.lastCapturedPath});

  @override
  List<Object?> get props => [controller, lastCapturedPath];
  // List<Object> get props => [controller, lastCapturedPath];
}

final class CameraError extends CameraState {
  final String message;
  const CameraError(this.message);

  @override
  List<Object> get props => [message];
}

final class CapturedImagePreview extends CameraState {
  final String lastCapturedPath;

  const CapturedImagePreview({required this.lastCapturedPath});

  @override
  List<Object> get props => [lastCapturedPath];
}
