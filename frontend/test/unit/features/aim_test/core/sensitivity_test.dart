import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:reaction_time_test/features/aim_test/core/sensitivity.dart';

void main() {
  group('Cs2Sensitivity', () {
    test('鼠标移动应按 CS2 灵敏度系数换算为视角弧度变化', () {
      const sensitivity = Cs2Sensitivity(
        sensitivity: 2,
        mYaw: 0.022,
        mPitch: 0.022,
        dpi: 800,
      );

      final angles = sensitivity.applyMouseDelta(
        const ViewAngles(yawRadians: 0, pitchRadians: 0),
        movementX: 100,
        movementY: -50,
      );

      expect(
        angles.yawRadians,
        closeTo(100 * 2 * 0.022 * math.pi / 180, 0.000001),
      );
      expect(
        angles.pitchRadians,
        closeTo(50 * 2 * 0.022 * math.pi / 180, 0.000001),
      );
    });

    test('cm/360 应使用 DPI 与 m_yaw 交叉验证灵敏度', () {
      const sensitivity = Cs2Sensitivity(
        sensitivity: 2,
        mYaw: 0.022,
        mPitch: 0.022,
        dpi: 800,
      );

      final expectedCounts = 360 / (2 * 0.022);
      final expectedCm = expectedCounts / 800 * 2.54;

      expect(sensitivity.cmPer360, closeTo(expectedCm, 0.000001));
    });

    test('normalized factory clamps CS2-style spec ranges', () {
      final sensitivity = Cs2Sensitivity.normalized(
        sensitivity: 140,
        mYaw: 0,
        mPitch: 0.8,
        dpi: 25,
      );

      expect(sensitivity.sensitivity, 100);
      expect(sensitivity.mYaw, 0.001);
      expect(sensitivity.mPitch, 0.5);
      expect(sensitivity.dpi, 100);
    });
  });
}
