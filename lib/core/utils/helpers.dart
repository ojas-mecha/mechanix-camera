import 'package:flutter/services.dart';

double orientationToRadians(DeviceOrientation orientation) {
  switch (orientation) {
    case DeviceOrientation.landscapeLeft:
      return -0.25;
    case DeviceOrientation.landscapeRight:
      return 0.25;
    default:
      return 0.0;
  }
}
