import 'package:flutter/services.dart';

double getRotationTurns(DeviceOrientation orientation) {
  switch (orientation) {
    case DeviceOrientation.portraitUp:
      return 0.25;
    case DeviceOrientation.portraitDown:
      return -0.25;
    case DeviceOrientation.landscapeLeft:
      return 0.5;
    default:
      return 0.0;
  }
}
