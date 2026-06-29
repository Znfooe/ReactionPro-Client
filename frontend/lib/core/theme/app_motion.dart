import 'package:flutter/animation.dart';

abstract final class AppDurations {
  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 250);
  static const slow = Duration(milliseconds: 400);
  static const splashLoop = Duration(milliseconds: 2400);
  static const splashCollapse = Duration(milliseconds: 600);
  static const splashExpand = Duration(milliseconds: 800);
  static const routeCurtain = Duration(milliseconds: 1400);
  static const authorSignal = Duration(milliseconds: 6400);
}

abstract final class AppCurves {
  static const defaultEase = Cubic(0.4, 0, 0.2, 1);
  static const easeIn = Cubic(0.4, 0, 1, 1);
  static const easeOut = Cubic(0, 0, 0.2, 1);
  static const easeOutQuint = Cubic(0.22, 1, 0.36, 1);
  static const spring = Cubic(0.34, 1.56, 0.64, 1);
}
