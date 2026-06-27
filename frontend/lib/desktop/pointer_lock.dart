import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

typedef PointerMoveHandler = void Function(double movementX, double movementY);

final class PointerLockSubscription {
  PointerLockSubscription(this._dispose);

  final void Function() _dispose;
  bool _disposed = false;

  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _dispose();
  }
}

const _channel = MethodChannel('reactionpro/pointer_lock');
final Set<void Function(bool locked)> _lockListeners = {};
final Set<PointerMoveHandler> _moveListeners = {};
bool _initialized = false;
bool _locked = false;

bool get _isSupported => Platform.isWindows;

bool isPointerLocked() {
  _ensureInitialized();
  return _locked;
}

void requestPointerLock() {
  if (!_isSupported) {
    return;
  }
  _ensureInitialized();
  unawaited(
    _channel
        .invokeMethod<bool>('lock')
        .then((locked) => _notifyLockChanged(locked ?? false))
        .catchError((Object _) => _notifyLockChanged(false)),
  );
}

void exitPointerLock() {
  if (!_isSupported) {
    return;
  }
  _ensureInitialized();
  unawaited(
    _channel
        .invokeMethod<void>('unlock')
        .then((_) => _notifyLockChanged(false))
        .catchError((Object _) => _notifyLockChanged(false)),
  );
}

PointerLockSubscription listenPointerLockChange(
  void Function(bool locked) onChange,
) {
  _ensureInitialized();
  _lockListeners.add(onChange);
  return PointerLockSubscription(() => _lockListeners.remove(onChange));
}

PointerLockSubscription listenPointerMove(PointerMoveHandler onMove) {
  _ensureInitialized();
  _moveListeners.add(onMove);
  return PointerLockSubscription(() => _moveListeners.remove(onMove));
}

void _ensureInitialized() {
  if (_initialized || !_isSupported) {
    return;
  }
  _initialized = true;
  _channel.setMethodCallHandler((call) async {
    switch (call.method) {
      case 'lockChanged':
        _notifyLockChanged(call.arguments == true);
      case 'pointerMove':
        final values = call.arguments;
        if (values is List && values.length >= 2) {
          final movementX = values[0];
          final movementY = values[1];
          if (movementX is num && movementY is num) {
            for (final listener in List.of(_moveListeners)) {
              listener(movementX.toDouble(), movementY.toDouble());
            }
          }
        }
    }
  });
}

void _notifyLockChanged(bool locked) {
  if (_locked == locked) {
    return;
  }
  _locked = locked;
  for (final listener in List.of(_lockListeners)) {
    listener(locked);
  }
}
