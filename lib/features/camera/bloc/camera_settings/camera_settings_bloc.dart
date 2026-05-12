import 'package:bloc/bloc.dart';
import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:mechanix_camera/features/camera/data/camera_repository.dart';

part 'camera_settings_event.dart';
part 'camera_settings_state.dart';

class CameraSettingsBloc
    extends Bloc<CameraSettingsEvent, CameraSettingsState> {
  final CameraRepository _repository;

  bool _isOrientationListening = false;

  CameraController get controller {
    final ctrl = _repository.controller;
    if (ctrl == null) {
      throw StateError('CameraController accessed before initialization.');
    }
    return ctrl;
  }

  CameraSettingsBloc(this._repository) : super(const CameraSettingsState()) {
    on<CameraOrientationChanged>(_onOrientationChanged);
    on<StartOrientationListener>(_onStartOrientationListener);
  }

  void _onStartOrientationListener(
    StartOrientationListener event,
    Emitter<CameraSettingsState> emit,
  ) {
    if (_isOrientationListening) return;

    final controller = _repository.controller;

    if (controller == null) return;

    _isOrientationListening = true;

    var lastOrientation = controller.value.deviceOrientation;

    controller.addListener(() {
      final orientation = controller.value.deviceOrientation;

      if (lastOrientation != orientation) {
        lastOrientation = orientation;

        add(CameraOrientationChanged(orientation: orientation));
      }
    });
  }

  void _onOrientationChanged(
    CameraOrientationChanged event,
    Emitter<CameraSettingsState> emit,
  ) {
    final current = state;
    if (current.orientation != event.orientation) {
      emit(current.copyWith(orientation: event.orientation));
    }
  }
}
