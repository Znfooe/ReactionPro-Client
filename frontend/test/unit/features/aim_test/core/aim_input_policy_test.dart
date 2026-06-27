import 'package:flutter_test/flutter_test.dart';
import 'package:reaction_time_test/features/aim_test/core/aim_input_policy.dart';

void main() {
  group('AimInputPolicy', () {
    test('桌面精确模式未锁定时准星仍保持在视口中心', () {
      final movable = AimInputPolicy.usesMovableCrosshair(
        simplifiedInput: false,
        running: true,
        pointerLocked: false,
      );

      expect(movable, isFalse);
    });

    test('桌面精确模式始终使用视口中心射击', () {
      final usesLocalPosition = AimInputPolicy.usesLocalShotPosition(
        simplifiedInput: false,
        pointerLocked: false,
      );

      expect(usesLocalPosition, isFalse);
    });

    test('移动端简化模式保留触摸准星和点击位置', () {
      expect(
        AimInputPolicy.usesMovableCrosshair(
          simplifiedInput: true,
          running: true,
          pointerLocked: false,
        ),
        isTrue,
      );
      expect(
        AimInputPolicy.usesLocalShotPosition(
          simplifiedInput: true,
          pointerLocked: false,
        ),
        isTrue,
      );
    });
  });
}
