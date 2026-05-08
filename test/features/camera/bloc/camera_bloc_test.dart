import 'package:bloc_test/bloc_test.dart';
import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_camera/features/camera/bloc/camera_bloc.dart';
import 'package:mechanix_camera/features/camera/data/camera_repository.dart';
import 'package:mocktail/mocktail.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockCameraRepository extends Mock implements CameraRepository {}

class MockCameraController extends Mock implements CameraController {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

// CameraController _fakeController() => MockCameraController();

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockCameraRepository mockRepo;
  late MockCameraController mockController;

  setUp(() {
    mockRepo = MockCameraRepository();
    mockController = MockCameraController();
    // bloc_test closes the bloc after every test, which calls
    // _repository.dispose() via CameraBloc.close(). Stub it globally
    // so mocktail never returns null for a Future<void> method.
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
        when(
          () => mockRepo.initialize(),
        ).thenAnswer((_) async => mockController);
        return CameraBloc(mockRepo);
      },
      act: (bloc) => bloc.add(CameraInitialized()),
      expect: () => [isA<CameraLoading>(), isA<CameraReady>()],
    );

    blocTest<CameraBloc, CameraState>(
      'CameraReady holds the controller returned by repository',
      build: () {
        when(
          () => mockRepo.initialize(),
        ).thenAnswer((_) async => mockController);
        return CameraBloc(mockRepo);
      },
      act: (bloc) => bloc.add(CameraInitialized()),
      expect: () => [
        isA<CameraLoading>(),
        isA<CameraReady>().having(
          (s) => s.controller,
          'controller',
          mockController,
        ),
      ],
    );

    // ── CameraException paths ────────────────────────────────────────────

    blocTest<CameraBloc, CameraState>(
      'emits [CameraLoading, CameraError] with permission message '
      'when CameraAccessDenied is thrown',
      build: () {
        when(
          () => mockRepo.initialize(),
        ).thenThrow(CameraException('CameraAccessDenied', 'Permission denied'));
        return CameraBloc(mockRepo);
      },
      act: (bloc) => bloc.add(CameraInitialized()),
      expect: () => [
        isA<CameraLoading>(),
        isA<CameraError>().having(
          (s) => s.message,
          'message',
          'Camera access denied. Please grant permission.',
        ),
      ],
    );

    blocTest<CameraBloc, CameraState>(
      'emits [CameraLoading, CameraError] with description '
      'for other CameraExceptions',
      build: () {
        when(
          () => mockRepo.initialize(),
        ).thenThrow(CameraException('some_other_code', 'Lens broken'));
        return CameraBloc(mockRepo);
      },
      act: (bloc) => bloc.add(CameraInitialized()),
      expect: () => [
        isA<CameraLoading>(),
        isA<CameraError>().having(
          (s) => s.message,
          'message',
          contains('Lens broken'),
        ),
      ],
    );

    // ── Generic exception path ────────────────────────────────────────────

    blocTest<CameraBloc, CameraState>(
      'emits [CameraLoading, CameraError] on unexpected exception',
      build: () {
        when(
          () => mockRepo.initialize(),
        ).thenThrow(Exception('Something went wrong'));
        return CameraBloc(mockRepo);
      },
      act: (bloc) => bloc.add(CameraInitialized()),
      expect: () => [
        isA<CameraLoading>(),
        isA<CameraError>().having(
          (s) => s.message,
          'message',
          contains('Unexpected error'),
        ),
      ],
    );

    // ── droppable transformer: duplicate events ignored ───────────────────

    blocTest<CameraBloc, CameraState>(
      'ignores second CameraInitialized while first is in progress (droppable)',
      build: () {
        when(() => mockRepo.initialize()).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 50));
          return mockController;
        });
        return CameraBloc(mockRepo);
      },
      act: (bloc) async {
        bloc.add(CameraInitialized());
        bloc.add(CameraInitialized()); // should be dropped
        bloc.add(CameraInitialized()); // should be dropped
        bloc.add(CameraInitialized()); // should be dropped
        bloc.add(CameraInitialized()); // should be dropped
        bloc.add(CameraInitialized()); // should be dropped
        bloc.add(CameraInitialized()); // should be dropped
      },
      // repository should only be called once
      verify: (_) => verify(() => mockRepo.initialize()).called(1),
    );
  });

  group('CameraCaptureRequested', () {
    // Helper: puts the bloc into CameraReady state
    // before we test capture behavior
    void arrangeReady() {
      when(() => mockRepo.initialize()).thenAnswer((_) async => mockController);
      when(() => mockRepo.controller).thenReturn(mockController);
    }

    // ── Guard: does nothing when state is not CameraReady ─────────────────

    blocTest<CameraBloc, CameraState>(
      'does nothing when state is not CameraReady and controller is null',
      build: () {
        // controller is null → repo.controller returns null
        when(() => mockRepo.controller).thenReturn(null);
        return CameraBloc(mockRepo);
      },
      // State is CameraInitial (never initialized), fire capture
      act: (bloc) => bloc.add(CameraCaptureRequested()),
      expect: () => [], // nothing should be emitted
    );

    // ── Happy path ─────────────────────────────────────────────────────────

    blocTest<CameraBloc, CameraState>(
      'emits CameraReady with imagePath on successful capture',
      build: () {
        arrangeReady();
        // stub capture() to return a fake path
        when(
          () => mockRepo.capture(),
        ).thenAnswer((_) async => '/storage/images/photo.jpg');
        return CameraBloc(mockRepo);
      },
      // First get into CameraReady, then capture
      act: (bloc) async {
        bloc.add(CameraInitialized());
        await Future.delayed(Duration.zero); // let init complete
        bloc.add(CameraCaptureRequested());
      },
      expect: () => [
        isA<CameraLoading>(),
        isA<CameraReady>(), // after init
        isA<CameraReady>().having(
          // after capture
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
        bloc.add(CameraInitialized());
        await Future.delayed(Duration.zero);
        bloc.add(CameraCaptureRequested());
      },
      expect: () => [
        isA<CameraLoading>(),
        isA<CameraReady>(),
        isA<CameraError>().having((s) => s.message, 'message', 'Disk full'),
      ],
    );

    // ── Null description fallback ──────────────────────────────────────────

    blocTest<CameraBloc, CameraState>(
      'emits CameraError with fallback message when CameraException description is null',
      build: () {
        arrangeReady();
        // description is null → should fall back to 'Capture failed'
        when(
          () => mockRepo.capture(),
        ).thenThrow(CameraException('unknown', null));
        return CameraBloc(mockRepo);
      },
      act: (bloc) async {
        bloc.add(CameraInitialized());
        await Future.delayed(Duration.zero);
        bloc.add(CameraCaptureRequested());
      },
      expect: () => [
        isA<CameraLoading>(),
        isA<CameraReady>(),
        isA<CameraError>().having(
          (s) => s.message,
          'message',
          'Capture failed', // the ?? fallback in your bloc
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
        bloc.add(CameraInitialized());
        await Future.delayed(Duration.zero);
        bloc.add(CameraCaptureRequested());
      },
      expect: () => [
        isA<CameraLoading>(),
        isA<CameraReady>(),
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
    blocTest<CameraBloc, CameraState>(
      'emits CapturedImagePreview when state is CameraReady with a captured path',
      build: () => CameraBloc(mockRepo),
      seed: () =>
          CameraReady(mockController, lastCapturedPath: 'captured_0000.jpg'),
      act: (bloc) => bloc.add(LastCaptureImageRequested()),
      expect: () => [
        isA<CapturedImagePreview>().having(
          (s) => s.lastCapturedPath,
          'lastCapturedPath',
          'captured_0000.jpg',
        ),
      ],
    );

    blocTest<CameraBloc, CameraState>(
      'does nothing when CameraReady has no lastCapturedPath',
      build: () => CameraBloc(mockRepo),
      seed: () => CameraReady(mockController), // no path
      act: (bloc) => bloc.add(LastCaptureImageRequested()),
      expect: () => [], // no state change
    );

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
    blocTest<CameraBloc, CameraState>(
      'emits CameraReady with preserved lastCapturedPath when preview is closed',
      build: () {
        when(() => mockRepo.controller).thenReturn(mockController);
        return CameraBloc(mockRepo);
      },
      seed: () =>
          const CapturedImagePreview(lastCapturedPath: 'captured_0000.jpg'),
      act: (bloc) => bloc.add(CloseImagePreview()),
      expect: () => [
        isA<CameraReady>()
            .having((s) => s.controller, 'controller', mockController)
            .having(
              (s) => s.lastCapturedPath,
              'lastCapturedPath',
              'captured_0000.jpg',
            ),
      ],
    );

    blocTest<CameraBloc, CameraState>(
      'does nothing when state is not CapturedImagePreview',
      build: () {
        when(() => mockRepo.controller).thenReturn(mockController);
        return CameraBloc(mockRepo);
      },
      seed: () => CameraReady(mockController),
      act: (bloc) => bloc.add(CloseImagePreview()),
      expect: () => [],
    );

    blocTest<CameraBloc, CameraState>(
      'does nothing when controller is null even if in preview state',
      build: () {
        when(() => mockRepo.controller).thenReturn(null); // controller gone
        return CameraBloc(mockRepo);
      },
      seed: () =>
          const CapturedImagePreview(lastCapturedPath: 'captured_0000.jpg'),
      act: (bloc) => bloc.add(CloseImagePreview()),
      expect: () => [],
    );
  });

  // =========================================================================
  group('CameraDisposed', () {
    blocTest<CameraBloc, CameraState>(
      'calls repository.dispose() and emits CameraInitial',
      build: () => CameraBloc(mockRepo),
      seed: () => CameraReady(mockController),
      act: (bloc) => bloc.add(CameraDisposed()),
      expect: () => [isA<CameraInitial>()],
      // dispose() is called for the event AND when bloc_test closes the bloc
      verify: (_) =>
          verify(() => mockRepo.dispose()).called(greaterThanOrEqualTo(1)),
    );
  });

  // =========================================================================
  group('close()', () {
    test('calls repository.dispose() when bloc is closed', () async {
      final bloc = CameraBloc(mockRepo);
      await bloc.close();

      verify(() => mockRepo.dispose()).called(1);
    });
  });
}
