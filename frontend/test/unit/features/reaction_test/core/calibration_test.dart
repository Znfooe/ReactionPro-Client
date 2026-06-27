import 'package:flutter_test/flutter_test.dart';
import 'package:reaction_time_test/features/reaction_test/core/calibration.dart';

void main() {
  group('CalibrationService', () {
    test('延迟补偿值应剔除异常样本后取平均值', () {
      const service = CalibrationService();

      final result = service.calculateOffset([120, 40, 140, 520, 160, 180]);

      expect(result.validSamples, [120, 140, 160, 180]);
      expect(result.discardedSamples, [40, 520]);
      expect(result.calibrationOffsetMs, 150);
    });

    test('没有可用校准样本时应抛出状态错误', () {
      const service = CalibrationService();

      expect(
        () => service.calculateOffset([20, 40, 520]),
        throwsA(isA<StateError>()),
      );
    });
  });
}
