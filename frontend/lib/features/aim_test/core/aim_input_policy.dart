abstract final class AimInputPolicy {
  static bool usesMovableCrosshair({
    required bool simplifiedInput,
    required bool running,
    required bool pointerLocked,
  }) {
    return simplifiedInput;
  }

  static bool usesLocalShotPosition({
    required bool simplifiedInput,
    required bool pointerLocked,
  }) {
    return simplifiedInput;
  }
}
