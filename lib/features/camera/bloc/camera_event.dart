part of 'camera_bloc.dart';

sealed class CameraEvent extends Equatable {
  const CameraEvent();

  @override
  List<Object> get props => [];
}

class CameraInitialized extends CameraEvent {}

class CameraDisposed extends CameraEvent {}

class CameraCaptureRequested extends CameraEvent {}

class LastCaptureImageRequested extends CameraEvent {}

class CloseImagePreview extends CameraEvent {}
