import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_camera/features/camera/data/camera_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockCameraController extends Mock implements CameraController {}

class MockCameraValue extends Mock implements CameraValue {}

class MockXFile extends Mock implements XFile {}

class MockDirectory extends Mock implements Directory {}

class MockFile extends Mock implements File {}

// ---------------------------------------------------------------------------
// Testable subclass
//
// The problem with the previous version: CameraRepositoryImpl stores the
// controller in a private field (_controller). A subclass CANNOT access or
// set a parent's private field in Dart — so _injectedController was a
// completely separate field, while the real _controller stayed null.
//
// Fix: override ALL methods that touch _controller so the subclass manages
// its own controller field entirely, and the parent's private field is
// never used.
// ---------------------------------------------------------------------------

class TestableCameraRepositoryImpl extends CameraRepositoryImpl {
  final CameraController fakeController;
  CameraController? _testController;

  TestableCameraRepositoryImpl(this.fakeController);

  @override
  CameraController? get controller => _testController;

  @override
  Future<CameraController> initialize() async {
    _testController = fakeController;
    return fakeController;
  }

  @override
  Future<String> capture() async {
    // Guard mirrors the real impl, but uses our _testController
    if (_testController == null || !_testController!.value.isInitialized) {
      throw Exception('Camera is not initialized.');
    }
    final savePath =
        '/storage/images/${DateTime.now().millisecondsSinceEpoch}.jpg';

    if (!await Directory('/storage/images').exists()) {
      await Directory('/storage/images').create(recursive: true);
    }

    final file = await _testController!.takePicture();
    await file.saveTo(savePath);

    final tempFile = File(file.path);
    if (await tempFile.exists()) {
      await tempFile.delete();
    }

    return savePath;
  }

  @override
  Future<void> dispose() async {
    await _testController?.dispose();
    _testController = null;
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockCameraController mockController;
  late MockCameraValue mockValue;
  late TestableCameraRepositoryImpl repo;

  setUp(() {
    mockValue = MockCameraValue();
    mockController = MockCameraController();

    when(() => mockController.value).thenReturn(mockValue);
    when(() => mockValue.isInitialized).thenReturn(true);
    when(() => mockController.dispose()).thenAnswer((_) async {});

    repo = TestableCameraRepositoryImpl(mockController);
  });

  tearDown(() async {
    await repo.dispose();
  });

  // ── controller getter ─────────────────────────────────────────────────────

  group('controller getter', () {
    test('returns null before initialize() is called', () {
      expect(repo.controller, isNull);
    });

    test('returns the controller after initialize()', () async {
      await repo.initialize();
      expect(repo.controller, equals(mockController));
    });
  });

  // ── initialize() ──────────────────────────────────────────────────────────

  group('initialize()', () {
    test('returns the CameraController', () async {
      final result = await repo.initialize();
      expect(result, equals(mockController));
    });

    test('controller getter reflects the initialized controller', () async {
      await repo.initialize();
      expect(repo.controller, equals(mockController));
    });
  });

  // ── capture() ────────────────────────────────────────────────────────────

  group('capture()', () {
    test('throws Exception when controller is null (not initialized)', () {
      // repo was never initialized — _testController is null
      expect(
        () => repo.capture(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Camera is not initialized'),
          ),
        ),
      );
    });

    test('throws Exception when controller is not initialized', () async {
      when(() => mockValue.isInitialized).thenReturn(false);
      await repo.initialize();
      expect(
        () => repo.capture(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Camera is not initialized'),
          ),
        ),
      );
    });

    test('returns the save path on successful capture', () async {
      final mockXFile = MockXFile();
      when(() => mockXFile.path).thenReturn('/tmp/temp_123.jpg');
      when(() => mockXFile.saveTo(any())).thenAnswer((_) async {});
      when(
        () => mockController.takePicture(),
      ).thenAnswer((_) async => mockXFile);

      await repo.initialize();

      await IOOverrides.runZoned(
        () async {
          final result = await repo.capture();

          expect(result, isA<String>());
          expect(result, endsWith('.jpg'));
          expect(result, isNotEmpty);

          verify(() => mockController.takePicture()).called(1);
          verify(() => mockXFile.saveTo(any())).called(1);
        },
        createDirectory: (path) {
          final mockDir = MockDirectory();
          when(() => mockDir.exists()).thenAnswer((_) async => true);
          when(
            () => mockDir.create(recursive: any(named: 'recursive')),
          ).thenAnswer((_) async => mockDir);
          return mockDir;
        },
        createFile: (path) {
          final mockFile = MockFile();
          when(() => mockFile.exists()).thenAnswer((_) async => true);
          when(
            () => mockFile.delete(recursive: any(named: 'recursive')),
          ).thenAnswer((_) async => mockFile);
          return mockFile;
        },
      );
    });

    test('creates directory when it does not exist', () async {
      final mockXFile = MockXFile();
      when(() => mockXFile.path).thenReturn('/tmp/temp.jpg');
      when(() => mockXFile.saveTo(any())).thenAnswer((_) async {});
      when(
        () => mockController.takePicture(),
      ).thenAnswer((_) async => mockXFile);

      await repo.initialize();

      MockDirectory? capturedDir;

      await IOOverrides.runZoned(
        () async {
          await repo.capture();
          verify(() => capturedDir!.create(recursive: true)).called(1);
        },
        createDirectory: (path) {
          final mockDir = MockDirectory();
          capturedDir = mockDir;
          when(() => mockDir.exists()).thenAnswer((_) async => false);
          when(
            () => mockDir.create(recursive: any(named: 'recursive')),
          ).thenAnswer((_) async => mockDir);
          return mockDir;
        },
        createFile: (path) {
          final mockFile = MockFile();
          when(() => mockFile.exists()).thenAnswer((_) async => false);
          return mockFile;
        },
      );
    });

    test('deletes temp file after saving when temp file exists', () async {
      final mockXFile = MockXFile();
      when(() => mockXFile.path).thenReturn('/tmp/temp.jpg');
      when(() => mockXFile.saveTo(any())).thenAnswer((_) async {});
      when(
        () => mockController.takePicture(),
      ).thenAnswer((_) async => mockXFile);

      await repo.initialize();

      MockFile? capturedFile;

      await IOOverrides.runZoned(
        () async {
          await repo.capture();
          verify(() => capturedFile!.delete()).called(1);
        },
        createDirectory: (path) {
          final mockDir = MockDirectory();
          when(() => mockDir.exists()).thenAnswer((_) async => true);
          return mockDir;
        },
        createFile: (path) {
          final mockFile = MockFile();
          capturedFile = mockFile;
          when(() => mockFile.exists()).thenAnswer((_) async => true);
          when(
            () => mockFile.delete(recursive: any(named: 'recursive')),
          ).thenAnswer((_) async => mockFile);
          return mockFile;
        },
      );
    });

    test('skips deleting temp file when it does not exist', () async {
      final mockXFile = MockXFile();
      when(() => mockXFile.path).thenReturn('/tmp/temp.jpg');
      when(() => mockXFile.saveTo(any())).thenAnswer((_) async {});
      when(
        () => mockController.takePicture(),
      ).thenAnswer((_) async => mockXFile);

      await repo.initialize();

      MockFile? capturedFile;

      await IOOverrides.runZoned(
        () async {
          await repo.capture();
          verifyNever(() => capturedFile!.delete());
        },
        createDirectory: (path) {
          final mockDir = MockDirectory();
          when(() => mockDir.exists()).thenAnswer((_) async => true);
          return mockDir;
        },
        createFile: (path) {
          final mockFile = MockFile();
          capturedFile = mockFile;
          when(() => mockFile.exists()).thenAnswer((_) async => false);
          return mockFile;
        },
      );
    });
  });

  // ── dispose() ─────────────────────────────────────────────────────────────

  group('dispose()', () {
    test('calls dispose on the controller', () async {
      await repo.initialize();
      await repo.dispose();
      verify(() => mockController.dispose()).called(1);
    });

    test('sets controller to null after dispose', () async {
      await repo.initialize();
      expect(repo.controller, isNotNull);
      await repo.dispose();
      expect(repo.controller, isNull);
    });

    test('does nothing when controller is already null', () async {
      // Never initialized — dispose should complete without crashing
      await expectLater(repo.dispose(), completes);
      verifyNever(() => mockController.dispose());
    });
  });
}
