import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_camera/features/camera/bloc/camera_bloc.dart';
import 'package:mechanix_camera/features/camera/data/camera_repository.dart';
import 'package:mechanix_camera/features/camera/model/camera_types.dart';
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
    // CameraBloc.close() always calls _repository.dispose(), so stub it
    // globally to avoid MissingStubError on every test teardown.
    when(() => mockRepo.dispose()).thenAnswer((_) async {});
  });

  // ── Initial state ────────────────────────────────────────────────────────

  test('initial state is CameraInitial', () {
    expect(CameraBloc(mockRepo).state, isA<CameraInitial>());
  });

  // =========================================================================
  group('CameraInitialized', () {
    // ── Happy path ───────────────────────────────────────────────────────

    blocTest<CameraBloc, CameraState>(
      'emits [CameraLoading, CameraReady] on successful initialization',
      build: () {
        // initialize() returns Future<CameraController> — must return the
        // mock, not async {} (which would return null and fail the type check).
        when(
          () => mockRepo.initialize(),
        ).thenAnswer((_) async => mockController);
        // The bloc also checks controller getter for null after initialize().
        when(() => mockRepo.controller).thenReturn(mockController);
        return CameraBloc(mockRepo);
      },
      act: (bloc) => bloc.add(const CameraInitialized()),
      expect: () => [isA<CameraLoading>(), isA<CameraReady>()],
    );

    // ── controller == null after initialize → CameraError ────────────────
    // initialize() itself succeeds but the getter returns null — this covers
    // the explicit null-check inside _onCameraInitialized.

    blocTest<CameraBloc, CameraState>(
      'emits [CameraLoading, CameraError] when controller is null after init',
      build: () {
        when(
          () => mockRepo.initialize(),
        ).thenAnswer((_) async => mockController);
        when(() => mockRepo.controller).thenReturn(null);
        return CameraBloc(mockRepo);
      },
      act: (bloc) => bloc.add(const CameraInitialized()),
      expect: () => [
        isA<CameraLoading>(),
        isA<CameraError>().having(
          (s) => s.message,
          'message',
          'Something went wrong. Please restart the app.',
        ),
      ],
    );

    // ── CameraAccessDenied ───────────────────────────────────────────────

    blocTest<CameraBloc, CameraState>(
      'emits [CameraLoading, CameraError] with permission message '
      'when CameraAccessDenied is thrown',
      build: () {
        when(
          () => mockRepo.initialize(),
        ).thenThrow(CameraException('CameraAccessDenied', 'Permission denied'));
        return CameraBloc(mockRepo);
      },
      act: (bloc) => bloc.add(const CameraInitialized()),
      expect: () => [
        isA<CameraLoading>(),
        isA<CameraError>().having(
          (s) => s.message,
          'message',
          'Camera access denied. Please grant permission.',
        ),
      ],
    );

    // ── Other CameraException ────────────────────────────────────────────

    blocTest<CameraBloc, CameraState>(
      'emits [CameraLoading, CameraError] with description '
      'for other CameraExceptions',
      build: () {
        when(
          () => mockRepo.initialize(),
        ).thenThrow(CameraException('some_other_code', 'Lens broken'));
        return CameraBloc(mockRepo);
      },
      act: (bloc) => bloc.add(const CameraInitialized()),
      expect: () => [
        isA<CameraLoading>(),
        isA<CameraError>().having(
          (s) => s.message,
          'message',
          contains('Lens broken'),
        ),
      ],
    );

    // ── Generic exception ────────────────────────────────────────────────

    blocTest<CameraBloc, CameraState>(
      'emits [CameraLoading, CameraError] on unexpected exception',
      build: () {
        when(
          () => mockRepo.initialize(),
        ).thenThrow(Exception('Something went wrong'));
        return CameraBloc(mockRepo);
      },
      act: (bloc) => bloc.add(const CameraInitialized()),
      expect: () => [
        isA<CameraLoading>(),
        isA<CameraError>().having(
          (s) => s.message,
          'message',
          contains('Unexpected error'),
        ),
      ],
    );

    // ── droppable: only the first event is processed ─────────────────────

    blocTest<CameraBloc, CameraState>(
      'ignores subsequent CameraInitialized events while first is in '
      'progress (droppable)',
      build: () {
        when(() => mockRepo.controller).thenReturn(mockController);
        when(() => mockRepo.initialize()).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 50));
          return mockController;
        });
        return CameraBloc(mockRepo);
      },
      act: (bloc) async {
        bloc.add(const CameraInitialized());
        bloc.add(const CameraInitialized());
        bloc.add(const CameraInitialized());
      },
      verify: (_) => verify(() => mockRepo.initialize()).called(1),
    );
  });

  // =========================================================================
  group('CameraCaptureRequested', () {
    // Puts the repository into a state where initialization succeeds.
    void arrangeReady() {
      when(() => mockRepo.initialize()).thenAnswer((_) async => mockController);
      when(() => mockRepo.controller).thenReturn(mockController);
    }

    // ── Guard: not CameraReady + null controller → no emission ────────────

    blocTest<CameraBloc, CameraState>(
      'does nothing when state is not CameraReady and controller is null',
      build: () {
        when(() => mockRepo.controller).thenReturn(null);
        return CameraBloc(mockRepo);
      },
      // Bloc starts in CameraInitial — never initialized.
      act: (bloc) => bloc.add(CameraCaptureRequested()),
      expect: () => [],
    );

    // ── Happy path ─────────────────────────────────────────────────────────

    blocTest<CameraBloc, CameraState>(
      'emits CameraReady with lastCapturedPath on successful capture',
      build: () {
        arrangeReady();
        when(
          () => mockRepo.capture(),
        ).thenAnswer((_) async => '/storage/images/photo.jpg');
        return CameraBloc(mockRepo);
      },
      act: (bloc) async {
        bloc.add(const CameraInitialized());
        await Future.delayed(Duration.zero);
        bloc.add(CameraCaptureRequested());
      },
      expect: () => [
        isA<CameraLoading>(),
        isA<CameraReady>(), // after init — no path yet
        isA<CameraCaptureInProgress>(),
        isA<CameraReady>().having(
          (s) => s.lastCapturedPath,
          'lastCapturedPath',
          '/storage/images/photo.jpg',
        ),
      ],
    );

    // ── CameraException during capture ────────────────────────────────────

    blocTest<CameraBloc, CameraState>(
      'emits CameraError with description on CameraException during capture',
      build: () {
        arrangeReady();
        when(
          () => mockRepo.capture(),
        ).thenThrow(CameraException('diskFull', 'Disk full'));
        return CameraBloc(mockRepo);
      },
      act: (bloc) async {
        bloc.add(const CameraInitialized());
        await Future.delayed(Duration.zero);
        bloc.add(CameraCaptureRequested());
      },
      expect: () => [
        isA<CameraLoading>(),
        isA<CameraReady>(),
        isA<CameraCaptureInProgress>(),
        isA<CameraError>().having((s) => s.message, 'message', 'Disk full'),
      ],
    );

    // ── Null description fallback ──────────────────────────────────────────

    blocTest<CameraBloc, CameraState>(
      'emits CameraError with fallback message when '
      'CameraException description is null',
      build: () {
        arrangeReady();
        when(
          () => mockRepo.capture(),
        ).thenThrow(CameraException('unknown', null));
        return CameraBloc(mockRepo);
      },
      act: (bloc) async {
        bloc.add(const CameraInitialized());
        await Future.delayed(Duration.zero);
        bloc.add(CameraCaptureRequested());
      },
      expect: () => [
        isA<CameraLoading>(),
        isA<CameraReady>(),
        isA<CameraCaptureInProgress>(),
        isA<CameraError>().having(
          (s) => s.message,
          'message',
          'Capture failed',
        ),
      ],
    );

    // ── Generic exception ──────────────────────────────────────────────────

    blocTest<CameraBloc, CameraState>(
      'emits CameraError on unexpected exception during capture',
      build: () {
        arrangeReady();
        when(
          () => mockRepo.capture(),
        ).thenThrow(Exception('Storage unavailable'));
        return CameraBloc(mockRepo);
      },
      act: (bloc) async {
        bloc.add(const CameraInitialized());
        await Future.delayed(Duration.zero);
        bloc.add(CameraCaptureRequested());
      },
      expect: () => [
        isA<CameraLoading>(),
        isA<CameraReady>(),
        isA<CameraCaptureInProgress>(),
        isA<CameraError>().having(
          (s) => s.message,
          'message',
          contains('Unexpected error'),
        ),
      ],
    );
  });

  // =========================================================================
  group('LastCaptureImageRequested', () {
    // ── Happy path ────────────────────────────────────────────────────────

    blocTest<CameraBloc, CameraState>(
      'emits CapturedImagePreview with lastCapturedPath '
      'when state is CameraReady with a captured path',
      build: () {
        when(() => mockRepo.getAllStoredImages()).thenAnswer((_) async => []);
        return CameraBloc(mockRepo);
      },
      seed: () => const CameraReady(lastCapturedPath: 'captured_0000.jpg'),
      act: (bloc) => bloc.add(LastCaptureImageRequested()),
      expect: () => [
        isA<CapturedImagePreview>().having(
          (s) => s.lastCapturedPath,
          'lastCapturedPath',
          'captured_0000.jpg',
        ),
      ],
    );

    // ── files forwarded from repository ───────────────────────────────────

    blocTest<CameraBloc, CameraState>(
      'CapturedImagePreview.files matches what repository returns',
      build: () {
        when(
          () => mockRepo.getAllStoredImages(),
        ).thenAnswer((_) async => [File('a.jpg'), File('b.jpg')]);
        return CameraBloc(mockRepo);
      },
      seed: () => const CameraReady(lastCapturedPath: 'captured_0000.jpg'),
      act: (bloc) => bloc.add(LastCaptureImageRequested()),
      expect: () => [
        isA<CapturedImagePreview>().having(
          (s) => s.files.length,
          'files.length',
          2,
        ),
      ],
    );

    // ── Guard: no lastCapturedPath → no emission ───────────────────────────

    blocTest<CameraBloc, CameraState>(
      'does nothing when CameraReady has no lastCapturedPath',
      build: () => CameraBloc(mockRepo),
      seed: () => const CameraReady(), // lastCapturedPath is null
      act: (bloc) => bloc.add(LastCaptureImageRequested()),
      expect: () => [],
    );

    // ── Guard: wrong state → no emission ──────────────────────────────────

    blocTest<CameraBloc, CameraState>(
      'does nothing when state is not CameraReady',
      build: () => CameraBloc(mockRepo),
      seed: () => CameraInitial(),
      act: (bloc) => bloc.add(LastCaptureImageRequested()),
      expect: () => [],
    );
  });

  // =========================================================================
  group('CloseImagePreview', () {
    // ── Happy path ────────────────────────────────────────────────────────

    blocTest<CameraBloc, CameraState>(
      'emits CameraReady preserving lastCapturedPath when preview is closed',
      build: () {
        when(() => mockRepo.controller).thenReturn(mockController);
        return CameraBloc(mockRepo);
      },
      // CapturedImagePreview.files is required — use an empty list.
      seed: () => const CapturedImagePreview(
        lastCapturedPath: 'captured_0000.jpg',
        files: [],
      ),
      act: (bloc) => bloc.add(CloseImagePreview()),
      expect: () => [
        isA<CameraReady>().having(
          (s) => s.lastCapturedPath,
          'lastCapturedPath',
          'captured_0000.jpg',
        ),
      ],
    );

    // ── Guard: wrong state → no emission ──────────────────────────────────

    blocTest<CameraBloc, CameraState>(
      'does nothing when state is not CapturedImagePreview',
      build: () {
        when(() => mockRepo.controller).thenReturn(mockController);
        return CameraBloc(mockRepo);
      },
      seed: () => const CameraReady(),
      act: (bloc) => bloc.add(CloseImagePreview()),
      expect: () => [],
    );

    // ── Guard: null controller → no emission ──────────────────────────────

    blocTest<CameraBloc, CameraState>(
      'does nothing when controller is null even if state is CapturedImagePreview',
      build: () {
        when(() => mockRepo.controller).thenReturn(null);
        return CameraBloc(mockRepo);
      },
      seed: () => const CapturedImagePreview(
        lastCapturedPath: 'captured_0000.jpg',
        files: [],
      ),
      act: (bloc) => bloc.add(CloseImagePreview()),
      expect: () => [],
    );
  });

  // =========================================================================
  group('OpenCameraWithSettings', () {
    // OpenCameraWithSettings takes a positional CameraSettingsPanel argument.
    // The enum only has: aspectRatio, none.

    blocTest<CameraBloc, CameraState>(
      'emits CameraReady with isSettingsOpen=true and correct panel',
      build: () => CameraBloc(mockRepo),
      seed: () => const CameraReady(),
      act: (bloc) => bloc.add(
        const OpenCameraWithSettings(CameraSettingsPanel.aspectRatio),
      ),
      expect: () => [
        isA<CameraReady>()
            .having((s) => s.isSettingsOpen, 'isSettingsOpen', true)
            .having(
              (s) => s.settingsPanel,
              'settingsPanel',
              CameraSettingsPanel.aspectRatio,
            ),
      ],
    );

    // ── Preserves other CameraReady fields via copyWith ───────────────────

    blocTest<CameraBloc, CameraState>(
      'preserves lastCapturedPath when opening settings',
      build: () => CameraBloc(mockRepo),
      seed: () => const CameraReady(lastCapturedPath: 'photo.jpg'),
      act: (bloc) => bloc.add(
        const OpenCameraWithSettings(CameraSettingsPanel.aspectRatio),
      ),
      expect: () => [
        isA<CameraReady>().having(
          (s) => s.lastCapturedPath,
          'lastCapturedPath',
          'photo.jpg',
        ),
      ],
    );

    // ── Guard: wrong state → no emission ──────────────────────────────────

    blocTest<CameraBloc, CameraState>(
      'does nothing when state is not CameraReady',
      build: () => CameraBloc(mockRepo),
      seed: () => CameraInitial(),
      act: (bloc) => bloc.add(
        const OpenCameraWithSettings(CameraSettingsPanel.aspectRatio),
      ),
      expect: () => [],
    );
  });

  // =========================================================================
  group('CloseCameraWithSettings', () {
    blocTest<CameraBloc, CameraState>(
      'emits CameraReady with isSettingsOpen=false and panel reset to none',
      build: () => CameraBloc(mockRepo),
      seed: () => const CameraReady(
        isSettingsOpen: true,
        settingsPanel: CameraSettingsPanel.aspectRatio,
      ),
      act: (bloc) => bloc.add(CloseCameraWithSettings()),
      expect: () => [
        isA<CameraReady>()
            .having((s) => s.isSettingsOpen, 'isSettingsOpen', false)
            .having(
              (s) => s.settingsPanel,
              'settingsPanel',
              CameraSettingsPanel.none,
            ),
      ],
    );

    // ── Preserves other CameraReady fields via copyWith ───────────────────

    blocTest<CameraBloc, CameraState>(
      'preserves lastCapturedPath when closing settings',
      build: () => CameraBloc(mockRepo),
      seed: () => const CameraReady(
        lastCapturedPath: 'photo.jpg',
        isSettingsOpen: true,
        settingsPanel: CameraSettingsPanel.aspectRatio,
      ),
      act: (bloc) => bloc.add(CloseCameraWithSettings()),
      expect: () => [
        isA<CameraReady>().having(
          (s) => s.lastCapturedPath,
          'lastCapturedPath',
          'photo.jpg',
        ),
      ],
    );

    // ── Guard: wrong state → no emission ──────────────────────────────────

    blocTest<CameraBloc, CameraState>(
      'does nothing when state is not CameraReady',
      build: () => CameraBloc(mockRepo),
      seed: () => CameraInitial(),
      act: (bloc) => bloc.add(CloseCameraWithSettings()),
      expect: () => [],
    );
  });

  // =========================================================================
  group('CameraCapturedImageSelected', () {
    // const existingFiles = []; // files preserved from current preview state

    // ── Happy path ────────────────────────────────────────────────────────

    blocTest<CameraBloc, CameraState>(
      'emits CapturedImagePreview with the selected path',
      build: () => CameraBloc(mockRepo),
      seed: () => const CapturedImagePreview(
        lastCapturedPath: 'old_image.jpg',
        files: [],
      ),
      act: (bloc) =>
          bloc.add(const CameraCapturedImageSelected('new_image.jpg')),
      expect: () => [
        isA<CapturedImagePreview>().having(
          (s) => s.lastCapturedPath,
          'lastCapturedPath',
          'new_image.jpg',
        ),
      ],
    );

    // ── files are preserved from the existing state ───────────────────────

    blocTest<CameraBloc, CameraState>(
      'preserves files from the current CapturedImagePreview state',
      build: () => CameraBloc(mockRepo),
      seed: () => CapturedImagePreview(
        lastCapturedPath: 'old_image.jpg',
        files: [File('a.jpg'), File('b.jpg')],
      ),
      act: (bloc) =>
          bloc.add(const CameraCapturedImageSelected('new_image.jpg')),
      expect: () => [
        isA<CapturedImagePreview>().having(
          (s) => s.files.length,
          'files.length',
          2,
        ),
      ],
    );

    // ── path is updated, files are unchanged ─────────────────────────────

    blocTest<CameraBloc, CameraState>(
      'updates path and keeps files in the same emission',
      build: () => CameraBloc(mockRepo),
      seed: () => CapturedImagePreview(
        lastCapturedPath: 'old_image.jpg',
        files: [File('a.jpg')],
      ),
      act: (bloc) =>
          bloc.add(const CameraCapturedImageSelected('selected_image.jpg')),
      expect: () => [
        isA<CapturedImagePreview>()
            .having(
              (s) => s.lastCapturedPath,
              'lastCapturedPath',
              'selected_image.jpg',
            )
            .having((s) => s.files.length, 'files.length', 1),
      ],
    );

    // ── Guard: wrong state → no emission ──────────────────────────────────

    blocTest<CameraBloc, CameraState>(
      'does nothing when state is CameraInitial',
      build: () => CameraBloc(mockRepo),
      seed: () => CameraInitial(),
      act: (bloc) =>
          bloc.add(const CameraCapturedImageSelected('new_image.jpg')),
      expect: () => [],
    );

    blocTest<CameraBloc, CameraState>(
      'does nothing when state is CameraReady',
      build: () => CameraBloc(mockRepo),
      seed: () => const CameraReady(lastCapturedPath: 'old_image.jpg'),
      act: (bloc) =>
          bloc.add(const CameraCapturedImageSelected('new_image.jpg')),
      expect: () => [],
    );

    blocTest<CameraBloc, CameraState>(
      'does nothing when state is CameraLoading',
      build: () => CameraBloc(mockRepo),
      seed: () => CameraLoading(),
      act: (bloc) =>
          bloc.add(const CameraCapturedImageSelected('new_image.jpg')),
      expect: () => [],
    );

    blocTest<CameraBloc, CameraState>(
      'does nothing when state is CameraError',
      build: () => CameraBloc(mockRepo),
      seed: () => const CameraError('some error'),
      act: (bloc) =>
          bloc.add(const CameraCapturedImageSelected('new_image.jpg')),
      expect: () => [],
    );
  });

  // =========================================================================
  group('CameraDisposed', () {
    blocTest<CameraBloc, CameraState>(
      'calls repository.dispose() and emits CameraInitial',
      build: () => CameraBloc(mockRepo),
      seed: () => const CameraReady(),
      act: (bloc) => bloc.add(CameraDisposed()),
      expect: () => [isA<CameraInitial>()],
      // dispose() fires once for the event and once when bloc_test closes
      // the bloc — accept any count >= 1.
      verify: (_) =>
          verify(() => mockRepo.dispose()).called(greaterThanOrEqualTo(1)),
    );

    blocTest<CameraBloc, CameraState>(
      'emits CameraInitial regardless of current state',
      build: () => CameraBloc(mockRepo),
      seed: () => const CameraError('some error'),
      act: (bloc) => bloc.add(CameraDisposed()),
      expect: () => [isA<CameraInitial>()],
    );
  });

  // =========================================================================
  group('close()', () {
    test(
      'calls repository.dispose() exactly once when bloc is closed',
      () async {
        final bloc = CameraBloc(mockRepo);
        await bloc.close();

        verify(() => mockRepo.dispose()).called(1);
      },
    );
  });
}
