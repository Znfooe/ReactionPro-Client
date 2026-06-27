import '../core/calibration.dart';
import 'calibration_offset_persistence_stub.dart'
    if (dart.library.html) 'calibration_offset_persistence_web.dart'
    if (dart.library.io) 'calibration_offset_persistence_native.dart'
    as persistence;

final class BrowserCalibrationOffsetStore implements CalibrationOffsetStore {
  const BrowserCalibrationOffsetStore();

  @override
  Future<double?> loadOffset() async {
    final value = await persistence.readCalibrationOffset(
      CalibrationService.storageKey,
    );
    if (value == null || value.isEmpty) {
      return null;
    }
    return double.tryParse(value);
  }

  @override
  Future<void> saveOffset(double value) async {
    await persistence.writeCalibrationOffset(
      CalibrationService.storageKey,
      value.toStringAsFixed(2),
    );
  }
}
