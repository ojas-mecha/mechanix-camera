import 'package:camera/camera.dart';

abstract class CameraRepository {
  Future<CameraController> initialize();

  Future<String> capture();

  Future<void> dispose();

  CameraController? get controller;
}
