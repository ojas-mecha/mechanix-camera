import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';
import 'package:mechanix_camera/features/camera/data/camera_repository.dart';
import 'package:mechanix_camera/features/camera/model/camera_types.dart';

part 'camera_event.dart';
part 'camera_state.dart';

class CameraBloc extends Bloc<CameraEvent, CameraState> {
  final CameraRepository _repository;

  CameraController get controller {
    final ctrl = _repository.controller;
    if (ctrl == null) {
      throw StateError('CameraController accessed before initialization.');
    }
    return ctrl;
  }

  CameraBloc(this._repository) : super(CameraInitial()) {
    on<CameraInitialized>(_onCameraInitialized, transformer: droppable());
    on<CameraCaptureRequested>(
      _onCameraCaptureRequested,
      transformer: droppable(),
    );
    on<LastCaptureImageRequested>(
      _onLastCaptureImage,
      transformer: droppable(),
    );
    on<CloseImagePreview>(_onCloseImagePreview, transformer: droppable());
    on<OpenCameraWithSettings>(
      _onOpenCameraWithSettings,
      transformer: droppable(),
    );
    on<CloseCameraWithSettings>(
      _onCloseCameraWithSettings,
      transformer: droppable(),
    );
    on<CameraCapturedImageSelected>(_onCapturedImageSelected);
    on<CameraDisposed>(_onCameraDisposed);
  }

  Future<void> _onCameraInitialized(
    CameraInitialized event,
    Emitter<CameraState> emit,
  ) async {
    emit(CameraLoading());

    try {
      await _repository.initialize();

      if (_repository.controller == null) {
        emit(
          const CameraError('Something went wrong. Please restart the app.'),
        );
        return;
      }

      emit(const CameraReady());
    } on CameraException catch (e) {
      switch (e.code) {
        case 'CameraAccessDenied':
          emit(
            const CameraError('Camera access denied. Please grant permission.'),
          );
          break;
        default:
          emit(CameraError('Camera error: ${e.description}'));
      }
    } catch (e) {
      emit(CameraError('Unexpected error: $e'));
    }
  }

  Future<void> _onCameraCaptureRequested(
    CameraCaptureRequested event,
    Emitter<CameraState> emit,
  ) async {
    if (state is! CameraReady && _repository.controller == null) return;

    try {
      emit(CameraCaptureInProgress());

      final imagePath = await _repository.capture();

      emit(CameraReady(lastCapturedPath: imagePath));
    } on CameraException catch (e) {
      emit(CameraError(e.description ?? 'Capture failed'));
    } catch (e) {
      emit(CameraError('Unexpected error: $e'));
    }
  }

  Future<void> _onLastCaptureImage(
    LastCaptureImageRequested event,
    Emitter<CameraState> emit,
  ) async {
    if (state is CameraReady &&
        (state as CameraReady).lastCapturedPath != null) {
      final files = await _repository.getAllStoredImages();

      emit(
        CapturedImagePreview(
          lastCapturedPath: (state as CameraReady).lastCapturedPath!,
          files: files,
        ),
      );
    }
  }

  void _onCapturedImageSelected(
    CameraCapturedImageSelected event,
    Emitter<CameraState> emit,
  ) {
    if (state is CapturedImagePreview) {
      emit(
        CapturedImagePreview(
          lastCapturedPath: event.path,
          files: (state as CapturedImagePreview).files,
        ),
      );
    }
  }

  void _onCloseImagePreview(
    CloseImagePreview event,
    Emitter<CameraState> emit,
  ) {
    if (state is CapturedImagePreview && _repository.controller != null) {
      emit(
        CameraReady(
          lastCapturedPath: (state as CapturedImagePreview).lastCapturedPath,
        ),
      );
    }
  }

  void _onOpenCameraWithSettings(
    OpenCameraWithSettings event,
    Emitter<CameraState> emit,
  ) {
    if (state is CameraReady) {
      emit(
        (state as CameraReady).copyWith(
          isSettingsOpen: true,
          settingsPanel: event.settingsPanel,
        ),
      );
    }
  }

  void _onCloseCameraWithSettings(
    CloseCameraWithSettings event,
    Emitter<CameraState> emit,
  ) {
    if (state is CameraReady) {
      emit(
        (state as CameraReady).copyWith(
          isSettingsOpen: false,
          settingsPanel: CameraSettingsPanel.none,
        ),
      );
    }
  }

  Future<void> _onCameraDisposed(
    CameraDisposed event,
    Emitter<CameraState> emit,
  ) async {
    await _repository.dispose();
    emit(CameraInitial());
  }

  @override
  Future<void> close() async {
    await _repository.dispose();
    return super.close();
  }
}
