import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mechanix_camera/features/camera/data/camera_repository.dart';
import 'package:mechanix_camera/features/camera/presentation/screen/camera_screen.dart';
import 'package:mechanix_camera/features/camera/presentation/widgets/camera/capture_button.dart';
import 'package:mechanix_camera/features/camera/presentation/widgets/camera/capture_image_button.dart';
import 'package:mechanix_camera/features/camera/presentation/widgets/captured_image/captured_image.dart';
import 'package:mocktail/mocktail.dart';

import 'helpers/test_app_wrapper.dart';

class MockCameraRepository extends Mock implements CameraRepository {}

class MockCameraController extends Mock implements CameraController {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Captured Image Switching Integration Test', () {
    late MockCameraRepository mockRepo;
    late MockCameraController mockController;
    late List<File> dummyFiles;

    setUp(() async {
      mockRepo = MockCameraRepository();
      mockController = MockCameraController();

      final tempDir = Directory.systemTemp;
      dummyFiles = List.generate(3, (index) {
        return File('${tempDir.path}/test_image_$index.jpg');
      });

      final byteData = await rootBundle.load('assets/icons/close.png');
      final bytes = byteData.buffer.asUint8List();

      for (final file in dummyFiles) {
        await file.create(recursive: true);
        await file.writeAsBytes(bytes);
      }

      // Stub common methods
      when(() => mockRepo.initialize()).thenAnswer((_) async => mockController);
      when(() => mockRepo.controller).thenReturn(mockController);
      when(() => mockRepo.dispose()).thenAnswer((_) async {});

      // Stub getAllStoredImages to return our dummies
      when(
        () => mockRepo.getAllStoredImages(),
      ).thenAnswer((_) async => dummyFiles);

      const controllerValue = CameraValue(
        isInitialized: true,
        errorDescription: null,
        previewSize: Size(1920, 1080),
        isRecordingVideo: false,
        isTakingPicture: false,
        isStreamingImages: false,
        isRecordingPaused: false,
        flashMode: FlashMode.off,
        exposureMode: ExposureMode.auto,
        focusMode: FocusMode.auto,
        deviceOrientation: DeviceOrientation.portraitUp,
        lockedCaptureOrientation: null,
        exposurePointSupported: true,
        focusPointSupported: true,
        description: CameraDescription(
          name: '0',
          lensDirection: CameraLensDirection.back,
          sensorOrientation: 0,
        ),
      );
      when(() => mockController.value).thenReturn(controllerValue);
      when(() => mockController.buildPreview()).thenReturn(Container());
    });

    tearDown(() async {
      for (final file in dummyFiles) {
        if (await file.exists()) {
          await file.delete();
        }
      }
    });

    testWidgets('Capture multiple images and switch between them in preview', (
      tester,
    ) async {
      // 1. Start the app
      // await tester.pumpWidget(CameraApp(repository: mockRepo));
      await tester.pumpWidget(
        TestAppWrapper(repository: mockRepo, child: const CameraScreen()),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 2. Mock capture results sequentially
      var captureIndex = 0;
      when(() => mockRepo.capture()).thenAnswer((_) async {
        final path = dummyFiles[captureIndex].path;
        captureIndex++;
        return path;
      });

      // 3. Capture 3 images
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.byType(CaptureButton));
        await tester.pumpAndSettle();
      }

      // 4. Open the preview screen (tapping the thumbnail button in footer)
      await tester.tap(find.byType(CapturedImageButton));
      await tester.pumpAndSettle();

      // 5. Verify the large preview shows the last captured image (index 2)
      expect(find.byType(CapturedImage), findsOneWidget);

      final centerImage = find
          .descendant(
            of: find.byType(CapturedImage),
            matching: find.byType(Image),
          )
          .first;

      Image imageWidget = tester.widget<Image>(centerImage);

      String getPath(ImageProvider provider) {
        if (provider is ResizeImage) {
          return (provider.imageProvider as FileImage).file.path;
        } else if (provider is FileImage) {
          return provider.file.path;
        }
        throw Exception('Unknown image provider type: ${provider.runtimeType}');
      }

      expect(getPath(imageWidget.image), dummyFiles[2].path);

      // 6. Find thumbnails and click the first one (index 0)
      final listView = find.byType(ListView);
      expect(listView, findsOneWidget);

      final firstThumbnail = find
          .descendant(of: listView, matching: find.byType(GestureDetector))
          .at(0);

      await tester.tap(firstThumbnail);
      await tester.pumpAndSettle();

      // 7. Verify the large preview now shows the first image (index 0)
      imageWidget = tester.widget<Image>(centerImage);
      expect(getPath(imageWidget.image), dummyFiles[0].path);

      // 8. Tap the second thumbnail (index 1) and verify
      final secondThumbnail = find
          .descendant(of: listView, matching: find.byType(GestureDetector))
          .at(1);

      await tester.tap(secondThumbnail);
      await tester.pumpAndSettle();

      imageWidget = tester.widget<Image>(centerImage);
      expect(getPath(imageWidget.image), dummyFiles[1].path);
    });
  });
}
