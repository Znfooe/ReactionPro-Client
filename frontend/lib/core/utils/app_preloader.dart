import '../theme/app_motion.dart';

abstract final class AppPreloader {
  static Future<void> preload() async {
    await Future<void>.delayed(AppDurations.splashLoop);
  }
}
