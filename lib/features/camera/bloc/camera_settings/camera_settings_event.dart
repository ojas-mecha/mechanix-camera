part of 'camera_settings_bloc.dart';

sealed class CameraSettingsEvent extends Equatable {
  const CameraSettingsEvent();

  @override
  List<Object> get props => [];
}

final class CameraOrientationChanged extends CameraSettingsEvent {
  final DeviceOrientation orientation;
  const CameraOrientationChanged({required this.orientation});

  @override
  List<Object> get props => [orientation];
}

final class StartOrientationListener extends CameraSettingsEvent {
  const StartOrientationListener();

  @override
  List<Object> get props => [];
}
