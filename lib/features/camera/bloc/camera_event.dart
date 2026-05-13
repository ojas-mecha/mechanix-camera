part of 'camera_bloc.dart';

sealed class CameraEvent extends Equatable {
  const CameraEvent();

  @override
  List<Object> get props => [];
}

class CameraInitialized extends CameraEvent {
  const CameraInitialized();
}

class CameraDisposed extends CameraEvent {}

class CameraCaptureRequested extends CameraEvent {}

class LastCaptureImageRequested extends CameraEvent {}

class CloseImagePreview extends CameraEvent {}

class OpenCameraWithSettings extends CameraEvent {
  final CameraSettingsPanel settingsPanel;

  const OpenCameraWithSettings(this.settingsPanel);

  @override
  List<Object> get props => [settingsPanel];
}

class CloseCameraWithSettings extends CameraEvent {}

class GetAllStoredImages extends CameraEvent {
  final List<File> files;

  const GetAllStoredImages(this.files);

  @override
  List<Object> get props => [files];
}

class CameraCapturedImageSelected extends CameraEvent {
  final String path;

  const CameraCapturedImageSelected(this.path);

  @override
  List<Object> get props => [path];
}
