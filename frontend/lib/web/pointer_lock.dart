import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS('document')
external JSObject get _document;

@JS('document.body')
external JSObject get _body;

typedef PointerMoveHandler = void Function(double movementX, double movementY);

final class PointerLockSubscription {
  const PointerLockSubscription(this._eventName, this._callback);

  final String _eventName;
  final JSFunction _callback;

  void dispose() {
    _document.callMethod<JSAny?>(
      'removeEventListener'.toJS,
      _eventName.toJS,
      _callback,
    );
  }
}

bool isPointerLocked() {
  return _document.getProperty<JSAny?>('pointerLockElement'.toJS) != null;
}

void requestPointerLock() {
  try {
    _ignoreRejectedPromise(_body.callMethod<JSAny?>('requestPointerLock'.toJS));
  } catch (_) {
    // Browser support and gesture policies vary; hover fallback still runs.
  }
}

void exitPointerLock() {
  try {
    _ignoreRejectedPromise(
      _document.callMethod<JSAny?>('exitPointerLock'.toJS),
    );
  } catch (_) {
    // No-op if the browser refuses the request.
  }
}

PointerLockSubscription listenPointerLockChange(
  void Function(bool locked) onChange,
) {
  final callback = (() {
    onChange(isPointerLocked());
  }).toJS;
  _document.callMethod<JSAny?>(
    'addEventListener'.toJS,
    'pointerlockchange'.toJS,
    callback,
  );
  return PointerLockSubscription('pointerlockchange', callback);
}

PointerLockSubscription listenPointerMove(PointerMoveHandler onMove) {
  final callback = ((JSObject event) {
    final movementX = event
        .getProperty<JSNumber>('movementX'.toJS)
        .toDartDouble;
    final movementY = event
        .getProperty<JSNumber>('movementY'.toJS)
        .toDartDouble;
    onMove(movementX, movementY);
  }).toJS;
  _document.callMethod<JSAny?>(
    'addEventListener'.toJS,
    'mousemove'.toJS,
    callback,
  );
  return PointerLockSubscription('mousemove', callback);
}

void _ignoreRejectedPromise(JSAny? result) {
  if (result == null) {
    return;
  }
  try {
    (result as JSObject).callMethod<JSAny?>('catch'.toJS, ((JSAny? _) {}).toJS);
  } catch (_) {
    // Some browsers return void instead of a Promise.
  }
}
