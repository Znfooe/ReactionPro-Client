import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _storage = FlutterSecureStorage();

Future<String?> readCalibrationOffset(String key) {
  return _storage.read(key: key);
}

Future<void> writeCalibrationOffset(String key, String value) {
  return _storage.write(key: key, value: value);
}
