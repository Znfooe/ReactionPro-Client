import '../../../web/local_storage.dart';

Future<String?> readCalibrationOffset(String key) async {
  return readLocalStorage(key);
}

Future<void> writeCalibrationOffset(String key, String value) async {
  writeLocalStorage(key, value);
}
