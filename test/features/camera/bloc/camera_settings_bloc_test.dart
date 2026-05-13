import 'package:bloc_test/bloc_test.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_camera/features/camera/bloc/camera_settings/camera_settings_bloc.dart';
import 'package:mechanix_camera/features/camera/data/camera_repository.dart';
import 'package:mocktail/mocktail.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockCameraRepository extends Mock implements CameraRepository {}

class MockCameraController extends Mock implements CameraController {}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockCameraRepository mockRepo;
  late MockCameraController mockController;

  setUp(() {
    mockRepo = MockCameraRepository();
    mockController = MockCameraController();
  });

  // =========================================================================
  group('Initial state', () {
    test('initial state is portraitUp', () {
      expect(
        CameraSettingsBloc(mockRepo).state,
        const CameraSettingsState(orientation: DeviceOrientation.portraitUp),
      );
    });
  });

  // =========================================================================
  group('CameraOrientationChanged', () {
    blocTest<CameraSettingsBloc, CameraSettingsState>(
      'emits updated orientation when orientation changes',
      build: () => CameraSettingsBloc(mockRepo),
      act: (bloc) {
        bloc.add(
          const CameraOrientationChanged(
            orientation: DeviceOrientation.landscapeLeft,
          ),
        );
      },
      expect: () => [
        const CameraSettingsState(orientation: DeviceOrientation.landscapeLeft),
      ],
    );

    blocTest<CameraSettingsBloc, CameraSettingsState>(
      'does not emit when orientation is same as current state',
      build: () => CameraSettingsBloc(mockRepo),
      act: (bloc) {
        bloc.add(
          const CameraOrientationChanged(
            orientation: DeviceOrientation.portraitUp,
          ),
        );
      },
      expect: () => [],
    );

    blocTest<CameraSettingsBloc, CameraSettingsState>(
      'emits multiple orientation updates correctly',
      build: () => CameraSettingsBloc(mockRepo),
      act: (bloc) {
        bloc
          ..add(
            const CameraOrientationChanged(
              orientation: DeviceOrientation.landscapeLeft,
            ),
          )
          ..add(
            const CameraOrientationChanged(
              orientation: DeviceOrientation.landscapeRight,
            ),
          )
          ..add(
            const CameraOrientationChanged(
              orientation: DeviceOrientation.portraitDown,
            ),
          );
      },
      expect: () => [
        const CameraSettingsState(orientation: DeviceOrientation.landscapeLeft),
        const CameraSettingsState(
          orientation: DeviceOrientation.landscapeRight,
        ),
        const CameraSettingsState(orientation: DeviceOrientation.portraitDown),
      ],
    );
  });

  // =========================================================================
  group('StartOrientationListener', () {
    test('adds listener to controller when listener starts', () async {
      when(() => mockRepo.controller).thenReturn(mockController);

      when(() => mockController.value).thenReturn(
        const CameraValue(
          isInitialized: true,
          isRecordingVideo: false,
          isTakingPicture: false,
          isStreamingImages: false,
          isRecordingPaused: false,
          flashMode: FlashMode.off,
          exposureMode: ExposureMode.auto,
          focusMode: FocusMode.auto,
          exposurePointSupported: true,
          focusPointSupported: true,
          deviceOrientation: DeviceOrientation.portraitUp,
          description: CameraDescription(
            name: '0',
            lensDirection: CameraLensDirection.back,
            sensorOrientation: 90,
          ),
        ),
      );

      when(() => mockController.addListener(any())).thenAnswer((_) {});

      final bloc = CameraSettingsBloc(mockRepo);

      bloc.add(const StartOrientationListener());

      await Future<void>.delayed(Duration.zero);

      verify(() => mockController.addListener(any())).called(1);

      await bloc.close();
    });

    test('does nothing when controller is null', () async {
      when(() => mockRepo.controller).thenReturn(null);

      final bloc = CameraSettingsBloc(mockRepo);

      bloc.add(const StartOrientationListener());

      await Future<void>.delayed(Duration.zero);

      verifyNever(() => mockController.addListener(any()));

      await bloc.close();
    });

    test('does not register listener multiple times', () async {
      when(() => mockRepo.controller).thenReturn(mockController);

      when(() => mockController.value).thenReturn(
        const CameraValue(
          isInitialized: true,
          isRecordingVideo: false,
          isTakingPicture: false,
          isStreamingImages: false,
          isRecordingPaused: false,
          flashMode: FlashMode.off,
          exposureMode: ExposureMode.auto,
          focusMode: FocusMode.auto,
          exposurePointSupported: true,
          focusPointSupported: true,
          deviceOrientation: DeviceOrientation.portraitUp,
          description: CameraDescription(
            name: '0',
            lensDirection: CameraLensDirection.back,
            sensorOrientation: 90,
          ),
        ),
      );

      when(() => mockController.addListener(any())).thenAnswer((_) {});

      final bloc = CameraSettingsBloc(mockRepo);

      bloc.add(const StartOrientationListener());
      bloc.add(const StartOrientationListener());
      bloc.add(const StartOrientationListener());

      await Future<void>.delayed(Duration.zero);

      verify(() => mockController.addListener(any())).called(1);

      await bloc.close();
    });
  });
}
