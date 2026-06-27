import '../../../web/pointer_lock_stub.dart'
    if (dart.library.html) '../../../web/pointer_lock.dart'
    if (dart.library.io) '../../../desktop/pointer_lock.dart'
    as browser;

typedef PointerMoveCallback = void Function(double movementX, double movementY);

final class PointerLockController {
  browser.PointerLockSubscription? _lockChangeSubscription;
  browser.PointerLockSubscription? _moveSubscription;
  PointerMoveCallback? _onMove;
  void Function(bool locked)? _onLockChanged;

  bool get isLocked => browser.isPointerLocked();

  void startListening({
    required PointerMoveCallback onMove,
    required void Function(bool locked) onLockChanged,
  }) {
    _onMove = onMove;
    _onLockChanged = onLockChanged;
    _lockChangeSubscription ??= browser.listenPointerLockChange((locked) {
      _onLockChanged?.call(locked);
    });
    _moveSubscription ??= browser.listenPointerMove((movementX, movementY) {
      if (isLocked) {
        _onMove?.call(movementX, movementY);
      }
    });
  }

  void requestLock() {
    browser.requestPointerLock();
  }

  void exitLock() {
    browser.exitPointerLock();
  }

  void dispose() {
    _lockChangeSubscription?.dispose();
    _moveSubscription?.dispose();
    _lockChangeSubscription = null;
    _moveSubscription = null;
  }
}
