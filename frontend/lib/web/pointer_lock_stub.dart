typedef PointerMoveHandler = void Function(double movementX, double movementY);

final class PointerLockSubscription {
  const PointerLockSubscription();

  void dispose() {}
}

bool isPointerLocked() => false;

void requestPointerLock() {}

void exitPointerLock() {}

PointerLockSubscription listenPointerLockChange(
  void Function(bool locked) onChange,
) {
  return const PointerLockSubscription();
}

PointerLockSubscription listenPointerMove(PointerMoveHandler onMove) {
  return const PointerLockSubscription();
}
