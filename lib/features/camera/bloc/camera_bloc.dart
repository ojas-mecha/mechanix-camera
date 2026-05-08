import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';
import 'package:mechanix_camera/features/camera/data/camera_repository.dart';

part 'camera_event.dart';
part 'camera_state.dart';

class CameraBloc extends Bloc<CameraEvent, CameraState> {
  final CameraRepository _repository;

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
    on<CameraDisposed>(_onCameraDisposed);
  }

  Future<void> _onCameraInitialized(
    CameraInitialized event,
    Emitter<CameraState> emit,
  ) async {
    emit(CameraLoading());
    try {
      final controller = await _repository.initialize();

      emit(CameraReady(controller));
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
      final imagePath = await _repository.capture();

      emit(CameraReady(_repository.controller!, lastCapturedPath: imagePath));
    } on CameraException catch (e) {
      emit(CameraError(e.description ?? 'Capture failed'));
    } catch (e) {
      emit(CameraError('Unexpected error: $e'));
    }
  }

  void _onLastCaptureImage(
    LastCaptureImageRequested event,
    Emitter<CameraState> emit,
  ) {
    if (state is CameraReady &&
        (state as CameraReady).lastCapturedPath != null) {
      emit(
        CapturedImagePreview(
          lastCapturedPath: (state as CameraReady).lastCapturedPath!,
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
          _repository.controller!,
          lastCapturedPath: (state as CapturedImagePreview).lastCapturedPath,
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
