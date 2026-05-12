part of 'camera_bloc.dart';

sealed class CameraState extends Equatable {
  const CameraState();

  @override
  List<Object?> get props => [];
}

final class CameraInitial extends CameraState {}

final class CameraLoading extends CameraState {}

final class CameraReady extends CameraState {
  final String? lastCapturedPath;
  final bool isSettingsOpen;
  final CameraSettingsPanel settingsPanel;

  const CameraReady({
    this.lastCapturedPath,
    this.isSettingsOpen = false,
    this.settingsPanel = CameraSettingsPanel.none,
  });

  CameraReady copyWith({
    String? lastCapturedPath,
    bool? isSettingsOpen,
    CameraSettingsPanel? settingsPanel,
  }) {
    return CameraReady(
      lastCapturedPath: lastCapturedPath ?? this.lastCapturedPath,
      isSettingsOpen: isSettingsOpen ?? this.isSettingsOpen,
      settingsPanel: settingsPanel ?? this.settingsPanel,
    );
  }

  @override
  List<Object?> get props => [lastCapturedPath, isSettingsOpen, settingsPanel];
}

final class CameraCaptureInProgress extends CameraState {}

final class CameraError extends CameraState {
  final String message;
  const CameraError(this.message);

  @override
  List<Object> get props => [message];
}

final class CapturedImagePreview extends CameraState {
  final String lastCapturedPath;
  final List<File> files;

  const CapturedImagePreview({
    required this.lastCapturedPath,
    required this.files,
  });

  @override
  List<Object> get props => [lastCapturedPath, files];
}
