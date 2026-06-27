import 'dart:math' as math;

final class ViewAngles {
  const ViewAngles({required this.yawRadians, required this.pitchRadians});

  static const zero = ViewAngles(yawRadians: 0, pitchRadians: 0);

  final double yawRadians;
  final double pitchRadians;

  ViewAngles copyWith({double? yawRadians, double? pitchRadians}) {
    return ViewAngles(
      yawRadians: yawRadians ?? this.yawRadians,
      pitchRadians: pitchRadians ?? this.pitchRadians,
    );
  }
}

final class Cs2Sensitivity {
  const Cs2Sensitivity({
    this.sensitivity = 2,
    this.mYaw = 0.022,
    this.mPitch = 0.022,
    this.dpi = 800,
  });

  factory Cs2Sensitivity.normalized({
    double sensitivity = 2,
    double mYaw = 0.022,
    double mPitch = 0.022,
    int dpi = 800,
  }) {
    return Cs2Sensitivity(
      sensitivity: sensitivity.clamp(minSensitivity, maxSensitivity).toDouble(),
      mYaw: mYaw.clamp(minMouseCoefficient, maxMouseCoefficient).toDouble(),
      mPitch: mPitch.clamp(minMouseCoefficient, maxMouseCoefficient).toDouble(),
      dpi: dpi.clamp(minDpi, maxDpi).toInt(),
    );
  }

  static const minSensitivity = 0.01;
  static const maxSensitivity = 100.0;
  static const minMouseCoefficient = 0.001;
  static const maxMouseCoefficient = 0.5;
  static const minDpi = 100;
  static const maxDpi = 32000;

  final double sensitivity;
  final double mYaw;
  final double mPitch;
  final int dpi;

  double get yawRadiansPerCount => sensitivity * mYaw * math.pi / 180;

  double get pitchRadiansPerCount => sensitivity * mPitch * math.pi / 180;

  double get cmPer360 {
    final countsPer360 = 360 / (sensitivity * mYaw);
    return countsPer360 / dpi * 2.54;
  }

  ViewAngles applyMouseDelta(
    ViewAngles current, {
    required double movementX,
    required double movementY,
  }) {
    return ViewAngles(
      yawRadians: current.yawRadians + movementX * yawRadiansPerCount,
      pitchRadians: _clampPitch(
        current.pitchRadians - movementY * pitchRadiansPerCount,
      ),
    );
  }

  double _clampPitch(double value) {
    const limit = math.pi * 0.49;
    return value.clamp(-limit, limit);
  }
}
