import 'dart:io';

import 'package:camera/camera.dart';
import 'package:mechanix_camera/core/utils/constants.dart';

import 'camera_repository.dart';

class CameraRepositoryImpl implements CameraRepository {
  CameraController? _controller;

  @override
  CameraController? get controller => _controller;

  @override
  Future<CameraController> initialize() async {
    final cameras = await availableCameras();

    if (cameras.isEmpty) {
      throw Exception('No cameras found on this device.');
    }

    _controller = CameraController(
      cameras[0],
      ResolutionPreset.max,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await _controller!.initialize();
    return _controller!;
  }

  @override
  Future<String> capture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      throw Exception('Camera is not initialized.');
    }
    final savePath =
        '${AppConstants.defaultImagePath}/${DateTime.now().millisecondsSinceEpoch}.jpg';

    if (!await Directory(AppConstants.defaultImagePath).exists()) {
      await Directory(AppConstants.defaultImagePath).create(recursive: true);
    }

    final file = await _controller!.takePicture();

    await file.saveTo(savePath);

    final tempFile = File(file.path);

    if (await tempFile.exists()) {
      await tempFile.delete();
    }

    return savePath;
  }

  @override
  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
  }
}
