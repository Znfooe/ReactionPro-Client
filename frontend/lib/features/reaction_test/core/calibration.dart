abstract interface class CalibrationOffsetStore {
  Future<double?> loadOffset();

  Future<void> saveOffset(double value);
}

final class CalibrationResult {
  const CalibrationResult({
    required this.validSamples,
    required this.discardedSamples,
    required this.calibrationOffsetMs,
  });

  final List<double> validSamples;
  final List<double> discardedSamples;
  final double calibrationOffsetMs;
}

final class CalibrationService {
  const CalibrationService({
    this.minValidSampleMs = 50,
    this.maxValidSampleMs = 500,
  });

  static const storageKey = 'reactionpro_calibration_offset';
  static const requiredSamples = 5;

  final double minValidSampleMs;
  final double maxValidSampleMs;

  CalibrationResult calculateOffset(Iterable<double> samples) {
    final validSamples = <double>[];
    final discardedSamples = <double>[];

    for (final sample in samples) {
      if (sample < minValidSampleMs || sample > maxValidSampleMs) {
        discardedSamples.add(sample);
      } else {
        validSamples.add(sample);
      }
    }

    if (validSamples.isEmpty) {
      throw StateError('没有可用的校准样本');
    }

    final sum = validSamples.reduce((value, element) => value + element);
    return CalibrationResult(
      validSamples: List.unmodifiable(validSamples),
      discardedSamples: List.unmodifiable(discardedSamples),
      calibrationOffsetMs: sum / validSamples.length,
    );
  }

  Future<double?> loadOffset(CalibrationOffsetStore store) {
    return store.loadOffset();
  }

  Future<void> saveOffset(
    CalibrationOffsetStore store,
    double calibrationOffsetMs,
  ) {
    return store.saveOffset(calibrationOffsetMs);
  }
}
