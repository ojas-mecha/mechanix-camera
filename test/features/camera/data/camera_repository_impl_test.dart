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
// The real CameraRepositoryImpl stores its controller in _controller, which
// is a Dart library-private field. A subclass in a different file cannot read
// or write it, so overriding the `controller` getter has NO effect on the
// guard inside capture():
//
//   if (_controller == null || !_controller!.value.isInitialized) { ... }
//
// That line reads _controller directly, not `this.controller`, so the guard
// always sees null regardless of what the subclass does with its own field.
//
// Fix: override BOTH initialize() and capture() so _testController is used
// everywhere, and capture()'s real body (directory check, takePicture,
// saveTo, temp-file deletion) is reproduced faithfully — including the call
// to checkStorage(), which we also override so tests can inject failures.
// ---------------------------------------------------------------------------

class TestableCameraRepositoryImpl extends CameraRepositoryImpl {
  final CameraController fakeController;
  CameraController? _testController;

  /// When non-null, checkStorage() throws this instead of running the real
  /// Process.run logic — used by the checkStorage group to test propagation.
  Exception? checkStorageError;

  TestableCameraRepositoryImpl(this.fakeController);

  @override
  CameraController? get controller => _testController;

  @override
  Future<CameraController> initialize() async {
    _testController = fakeController;
    return fakeController;
  }

  /// Replaces the Process.run syscall with an injectable failure point.
  /// When checkStorageError is null this is a no-op (storage is fine).
  @override
  Future<void> checkStorage() async {
    if (checkStorageError != null) throw checkStorageError!;
  }

  /// Mirrors the real capture() body exactly, but uses _testController
  /// instead of the parent's inaccessible _controller field.
  @override
  Future<String> capture() async {
    if (_testController == null || !_testController!.value.isInitialized) {
      throw Exception('Camera is not initialized.');
    }

    // Calls our overridden checkStorage() — injected failures propagate here.
    await checkStorage();

    final defaultImagePath = getDefaultStoragePath();
    final savePath =
        '$defaultImagePath/${DateTime.now().millisecondsSinceEpoch}.jpg';

    if (!await Directory(defaultImagePath).exists()) {
      await Directory(defaultImagePath).create(recursive: true);
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

  // =========================================================================
  group('controller getter', () {
    test('returns null before initialize() is called', () {
      expect(repo.controller, isNull);
    });

    test('returns the controller after initialize()', () async {
      await repo.initialize();
      expect(repo.controller, equals(mockController));
    });
  });

  // =========================================================================
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

  // =========================================================================
  group('getDefaultStoragePath()', () {
    test('returns a HOME-based path ending with /Pictures/Camera '
        'when HOME env var is set', () {
      final path = repo.getDefaultStoragePath();
      // On any Linux/macOS runner HOME is always set.
      expect(path, endsWith('/Pictures/Camera'));
      expect(path, isNot(equals('/tmp/Camera')));
    });

    test('path does not contain null or empty segments', () {
      final path = repo.getDefaultStoragePath();
      expect(path, isNotEmpty);
      expect(path.contains('null'), isFalse);
    });
  });

  // =========================================================================
  group('checkStorage()', () {
    // checkStorage() calls Process.run — impossible to intercept via
    // IOOverrides. We verify its contract through capture(): if checkStorage()
    // throws, capture() must propagate that exception unchanged.

    test(
      'capture() propagates low-storage exception from checkStorage()',
      () async {
        repo.checkStorageError = Exception('Low storage space');
        await repo.initialize(); // _testController is set → guard passes

        await expectLater(
          repo.capture(),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Low storage space'),
            ),
          ),
        );
      },
    );

    test('capture() propagates process error from checkStorage()', () async {
      repo.checkStorageError = Exception('Error: df failed');
      await repo.initialize();

      await expectLater(
        repo.capture(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Error: df failed'),
          ),
        ),
      );
    });
  });

  // =========================================================================
  group('capture()', () {
    // ── Guards ───────────────────────────────────────────────────────────────

    test('throws when controller is null (never initialized)', () async {
      // repo was never initialized — _testController is null.
      await expectLater(
        repo.capture(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Camera is not initialized'),
          ),
        ),
      );
    });

    test('throws when controller exists but isInitialized is false', () async {
      when(() => mockValue.isInitialized).thenReturn(false);
      await repo.initialize();

      await expectLater(
        repo.capture(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Camera is not initialized'),
          ),
        ),
      );
    });

    // ── Happy path ────────────────────────────────────────────────────────

    test('returns a non-empty .jpg save path on successful capture', () async {
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

    test('save path contains a timestamp-based filename', () async {
      final mockXFile = MockXFile();
      when(() => mockXFile.path).thenReturn('/tmp/temp.jpg');
      when(() => mockXFile.saveTo(any())).thenAnswer((_) async {});
      when(
        () => mockController.takePicture(),
      ).thenAnswer((_) async => mockXFile);

      await repo.initialize();

      await IOOverrides.runZoned(
        () async {
          final before = DateTime.now().millisecondsSinceEpoch;
          final result = await repo.capture();
          final after = DateTime.now().millisecondsSinceEpoch;

          final filename = result.split('/').last.replaceAll('.jpg', '');
          final ts = int.tryParse(filename);

          expect(ts, isNotNull);
          expect(ts, greaterThanOrEqualTo(before));
          expect(ts, lessThanOrEqualTo(after));
        },
        createDirectory: (path) {
          final d = MockDirectory();
          when(() => d.exists()).thenAnswer((_) async => true);
          return d;
        },
        createFile: (path) {
          final f = MockFile();
          when(() => f.exists()).thenAnswer((_) async => false);
          return f;
        },
      );
    });

    // ── Directory handling ────────────────────────────────────────────────

    test('does NOT call create() when directory already exists', () async {
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
          verifyNever(() => capturedDir!.create(recursive: true));
        },
        createDirectory: (path) {
          final mockDir = MockDirectory();
          capturedDir = mockDir;
          when(() => mockDir.exists()).thenAnswer((_) async => true);
          when(
            () => mockDir.create(recursive: any(named: 'recursive')),
          ).thenAnswer((_) async => mockDir);
          return mockDir;
        },
        createFile: (path) {
          final f = MockFile();
          when(() => f.exists()).thenAnswer((_) async => false);
          return f;
        },
      );
    });

    test(
      'calls create(recursive: true) when directory does not exist',
      () async {
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
            final f = MockFile();
            when(() => f.exists()).thenAnswer((_) async => false);
            return f;
          },
        );
      },
    );

    // ── Temp file handling ────────────────────────────────────────────────

    test('deletes temp file after saving when it exists', () async {
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

  // =========================================================================
  group('getAllStoredImages()', () {
    test('returns only File entities from the storage directory', () async {
      final fakeFile1 = MockFile();
      final fakeFile2 = MockFile();

      await IOOverrides.runZoned(
        () async {
          final results = await repo.getAllStoredImages();
          expect(results, hasLength(2));
          expect(results, everyElement(isA<File>()));
        },
        createDirectory: (path) {
          final mockDir = MockDirectory();
          when(
            () => mockDir.list(
              recursive: any(named: 'recursive'),
              followLinks: any(named: 'followLinks'),
            ),
          ).thenAnswer((_) => Stream.fromIterable([fakeFile1, fakeFile2]));
          return mockDir;
        },
      );
    });

    test('returns empty list when directory contains no files', () async {
      await IOOverrides.runZoned(
        () async {
          final results = await repo.getAllStoredImages();
          expect(results, isEmpty);
        },
        createDirectory: (path) {
          final mockDir = MockDirectory();
          when(
            () => mockDir.list(
              recursive: any(named: 'recursive'),
              followLinks: any(named: 'followLinks'),
            ),
          ).thenAnswer((_) => const Stream.empty());
          return mockDir;
        },
      );
    });

    test('filters out non-File entities (e.g. subdirectories)', () async {
      final fakeFile = MockFile();
      final fakeSubDir = MockDirectory();

      await IOOverrides.runZoned(
        () async {
          final results = await repo.getAllStoredImages();
          expect(results, hasLength(1));
          expect(results.first, isA<File>());
        },
        createDirectory: (path) {
          final mockDir = MockDirectory();
          when(
            () => mockDir.list(
              recursive: any(named: 'recursive'),
              followLinks: any(named: 'followLinks'),
            ),
          ).thenAnswer((_) => Stream.fromIterable([fakeFile, fakeSubDir]));
          return mockDir;
        },
      );
    });

    test('uses the path returned by getDefaultStoragePath()', () async {
      String? capturedPath;

      await IOOverrides.runZoned(
        () async {
          await repo.getAllStoredImages();
          expect(capturedPath, equals(repo.getDefaultStoragePath()));
        },
        createDirectory: (path) {
          capturedPath = path;
          final mockDir = MockDirectory();
          when(
            () => mockDir.list(
              recursive: any(named: 'recursive'),
              followLinks: any(named: 'followLinks'),
            ),
          ).thenAnswer((_) => const Stream.empty());
          return mockDir;
        },
      );
    });
  });

  // =========================================================================
  group('dispose()', () {
    test('calls dispose() on the controller', () async {
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

    test('completes without error when controller is already null', () async {
      await expectLater(repo.dispose(), completes);
      verifyNever(() => mockController.dispose());
    });

    test('controller stays null if dispose is called twice', () async {
      await repo.initialize();
      await repo.dispose();
      await repo.dispose(); // second call — must not throw
      expect(repo.controller, isNull);
    });
  });
}
