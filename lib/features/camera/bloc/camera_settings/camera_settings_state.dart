part of 'camera_settings_bloc.dart';

final class CameraSettingsState extends Equatable {
  final DeviceOrientation orientation;

  const CameraSettingsState({this.orientation = DeviceOrientation.portraitUp});

  CameraSettingsState copyWith({DeviceOrientation? orientation}) {
    return CameraSettingsState(orientation: orientation ?? this.orientation);
  }

  @override
  List<Object> get props => [orientation];
}
