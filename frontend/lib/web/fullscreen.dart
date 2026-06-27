import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS('document')
external JSObject get _document;

@JS('document.documentElement')
external JSObject get _documentElement;

final class FullscreenSubscription {
  const FullscreenSubscription(this._eventName, this._callback);

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

bool isFullscreen() {
  return _document.getProperty<JSAny?>('fullscreenElement'.toJS) != null;
}

void requestFullscreen() {
  try {
    _ignoreRejectedPromise(
      _documentElement.callMethod<JSAny?>('requestFullscreen'.toJS),
    );
  } catch (_) {
    // Browser support and gesture policies vary; immersive in-app mode still runs.
  }
}

void exitFullscreen() {
  if (!isFullscreen()) {
    return;
  }
  try {
    _document.callMethod<JSAny?>('exitFullscreen'.toJS);
  } catch (_) {
    // No-op if the browser refuses the request.
  }
}

void _ignoreRejectedPromise(JSAny? result) {
  if (result == null) {
    return;
  }
  try {
    (result as JSObject).callMethod<JSAny?>('catch'.toJS, ((JSAny? _) {}).toJS);
  } catch (_) {
    // The browser may return void instead of a Promise.
  }
}

FullscreenSubscription listenFullscreenChange(void Function(bool) onChange) {
  final callback = (() {
    onChange(isFullscreen());
  }).toJS;
  _document.callMethod<JSAny?>(
    'addEventListener'.toJS,
    'fullscreenchange'.toJS,
    callback,
  );
  return FullscreenSubscription('fullscreenchange', callback);
}
